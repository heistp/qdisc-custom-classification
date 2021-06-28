# qdisc-custom-classification

Customizing flow classification with the sfq, fq_codel, fq_pie and Cake qdiscs
using ipsets, tc-flow and eBPF

## Introduction

With the fair queueing (FQ) qdiscs in Linux, including sfq, fq_codel, fq_pie,
and [Cake](https://www.bufferbloat.net/projects/codel/wiki/Cake/), it's possible
to customize what constitutes a flow. Rather than flow fairness, for example,
these qdiscs can be configured to provide host fairness, subnet fairness, or
fully customized classification using [IP sets](https://ipset.netfilter.org/).

For qdiscs other than Cake, custom classification is done by substituting the
standard packet hash (typically a hash of the 5-tuple or 3-tuple) with a
supplied value, in one of two ways:
* When the major number (upper 16 bits) of the packet's `priority` field matches
  the qdisc's handle, the minor number (lower 16 bits) is used for the hash.
* When a filter attached to the qdisc sets a classid, the minor number of the
  classid is used for the hash.

For Cake, the customization methods are a little different, since it supports
two levels of isolation (host and flow):
* The major and minor numbers from an attached filter's classid are used for
  host and flow isolation, respectively.
* The priority field may be used to override the tin (priority level).

The priority and classid fields are commonly set using tc filters. The
[tc-flow](https://man7.org/linux/man-pages/man8/tc-flow.8.html) filter classifier
may be used to hash a custom set of fields in IP packets, or map other fields in
the packet, such as `priority` or `mark`. Two more examples of classification
with tc filters are in the
[Cake man page](https://man7.org/linux/man-pages/man8/tc-cake.8.html#OVERRIDING_CLASSIFICATION_WITH_TC_FILTERS).
The first uses [skbedit](https://man7.org/linux/man-pages/man8/tc-skbedit.8.html)
to set the priority field, and the second sets the major and minor classid
directly on a filter match.

When mapping a large number of IP or MAC addresses to queues,
[IP sets](https://ipset.netfilter.org/) may be used. This may be required at an
ISP, for example, where subscribers are defined by their IP/MAC address/es,
and subscriber fairness is desired. Using the ipset skbinfo extension
(described in the
[ipset(8) man page](https://ipset.netfilter.org/ipset.man.html)), the firewall
mark or skb priority may be set individually for each matching ipset entry.

## Using tc-flow for Classification with fq_codel, sfq and Cake

Using the tc-flow filter classifier to customize the hashing for fq_codel and
sfq is straightforward. We simply add a filter as a child of our qdisc that
hashes the key/s we want, for example:

```
tc qdisc add dev enp1s0 handle 20: fq_codel
tc filter add dev enp1s0 protocol all parent 20: handle 1 \
        flow hash keys dst divisor 1024
```

The `dst` keyword uses the destination address for hashing.  See the KEYS
section of the [tc-flow](https://man7.org/linux/man-pages/man8/tc-flow.8.html)
man page for a full list of possible hash keys.

This same technique *can* be used with Cake, but because tc-flow only sets
the minor classid, it does not take full advantage of Cake's two levels of
isolation (host and flow). See
[Using IP Sets for Classification with Cake](#using-ip-sets-for-classification-with-cake)
for a way to customize both levels of isolation.

fq_pie has been left out of this section deliberately. Although the same
technique could theoretically work for fq_pie, when adding the filter, in kernel
5.10 with iproute2-5.12.0 at least, it fails with the error `Error: Qdisc not
classful`.

## Using IP Sets for Classification with fq_codel, sfq and fq_pie

For fq_codel, sfq and fq_pie, using IP sets for custom flow classification is a
three step process.

First, we add our qdisc. Here we use htb for shaping, and fq_codel as the leaf.
Note that we have given the fq_codel qdisc an explicit handle of 20.

```
tc qdisc add dev enp1s0 root handle 1: htb default 10
tc class add dev enp1s0 parent 1: classid 1:10 htb rate 50Mbit
tc qdisc add dev enp1s0 handle 20: parent 1:10 fq_codel
```

Next, we create and populate an IP set of the appropriate type. Each entry
assigns the priority field using a major number of 20, our qdisc's handle, and a
minor number of the desired flow ID, or in this case our subscriber ID. Here,
subscriber 1 has an IP address of 10.7.1.2, and subscriber 2 has two IP
addresses, 10.7.1.3 and 10.7.1.4.

```
ipset create subscribers hash:ip skbinfo
ipset add subscribers 10.7.1.2 skbprio 20:1
ipset add subscribers 10.7.1.3 skbprio 20:2
ipset add subscribers 10.7.1.4 skbprio 20:2
```

Finally, we add a rule to the iptables mangle table that matches the destination
address of the packet using the `subscribers` IP set, which sets the skb's
priority field for any matched entries. The POSTROUTING chain is suitable for a
router or middlebox that forwards packets.

```
iptables -o enp1s0 -t mangle -A POSTROUTING \
	-j SET --map-set subscribers dst --map-prio
```

## Using IP Sets for Classification with Cake

With Cake, we use the term "classification" to refer to both the isolation (host
and flow) and the tin (or priority level). See the
[Cake man page](https://man7.org/linux/man-pages/man8/tc-cake.8.html#OVERRIDING_CLASSIFICATION_WITH_TC_FILTERS)
and the following sections for more information on how to customize each.

### Isolation

Cake provides two levels of isolation: host and flow. This may be used to first
provide fairness between hosts, then within a given host, fairness between
flows.

Cake's host and flow isolation is overridden using a tc filter's classid. The
question is, how do we use IP sets to set the classid, when the ipset skbinfo
extension only allows them to edit the packet's mark or priority fields? There
are at least two options, depending on whether we want to override only the flow
isolation, or both the host and flow isolation.

#### Customizing Flow Isolation with tc-flow

To customize only Cake's flow isolation with IP sets, one option is to use
[tc-flow](https://man7.org/linux/man-pages/man8/tc-flow.8.html). This allows
mapping a packet's priority or mark fields onto the classid. Similar to our
regular FQ qdiscs, this is a three step process.

First, we add our Cake qdisc. We also add a filter that uses tc-flow to map the
lower 16 bits of the packet's priority field to the minor classid. The value is
not copied directly, but starts with a minor classid of 1, so a priority with a
minor ID of 2 maps to a minor classid of 3. A handle must be specified to the
filter for it to work, although the handle number is arbitrary.

```
tc qdisc add dev enp1s0 handle 1: root Cake bandwidth 50Mbit
tc filter add dev enp1s0 parent 1: handle 0x99 flow map key priority
```

Next, we create and populate an IP set of the appropriate type. Each entry
assigns the priority field using a major number of 0 (this is ignored, as long
as it's not the same as the Cake's qdisc handle, see [Tin](#tin)), and a minor
number of our subscriber ID. Here, subscriber 1 has an IP address of 10.7.1.2,
and subscriber 2 has two IP addresses, 10.7.1.3 and 10.7.1.4.

```
ipset create subscribers hash:ip skbinfo
ipset add subscribers 10.7.1.2 skbprio 0:1
ipset add subscribers 10.7.1.3 skbprio 0:2
ipset add subscribers 10.7.1.4 skbprio 0:2
```

Finally, we add a rule to the iptables mangle table that matches the destination
address of the packet using the `subscribers` IP set, which sets the skb's
priority field for any matching entries. The POSTROUTING chain is suitable for a
router or middlebox that forwards packets.

```
iptables -o enp1s0 -t mangle -A POSTROUTING \
	-j SET --map-set subscribers dst --map-prio
```

Note that it is also possible to map the packet's mark instead of the priority
field. In this case, we use `flow map key mark` in the tc filter, `skbmark 0x#`
in the IP set, and `--map-mark` in the iptables command.

Note also that tc-flow only allows mapping to the minor classid, for flow
customization. To set both the major and minor class ID, we'll need eBPF,
described in the following section.

#### Customizing Host and/or Flow Isolation with eBPF

To customize both Cake's host and flow isolation, we can use a simple
[eBPF](https://man7.org/linux/man-pages/man8/tc-bpf.8.html) classifier to map
(copy) a packet's mark or priority to the major and minor classid of the filter.
The body of each of the classifiers (one for mark and one for priority) is as
simple as this, which just returns the desired 32-bit field as a classid
directly:

```
SEC("classifier")
int cls_main(struct __sk_buff *skb)
{
  return skb->mark;
  // OR return skb->priority;
}
```

To use it, we first add our cake qdisc, as well as a filter that uses the
desired eBPF classifier to map the appropriate field (in this case the mark) to
the minor classid.

```
tc qdisc add dev enp1s0 handle 1: root cake bandwidth 50Mbit
tc filter add dev enp1s0 parent 1: bpf obj mark_to_classid.o
```

Next, we create and populate an IP set of the appropriate type. Each entry
assigns the mark field using a major number of the flow ID, or in this case our
subscriber ID. Here, subscriber 1 has an IP address of 10.7.1.2, and subscriber
2 has two IP addresses, 10.7.1.3 and 10.7.1.4. We could also override the minor
classid (flow) using the lower 16 bits, but we have chosen not to, so that the
packet may be hashed as usual for flow classification.

```
ipset create subscribers hash:ip skbinfo
ipset add subscribers 10.7.1.2 skbmark 0x10000
ipset add subscribers 10.7.1.3 skbmark 0x20000
ipset add subscribers 10.7.1.4 skbmark 0x20000
```

Finally, we add a rule to the iptables mangle table that matches the destination
address of the packet using the `subscribers` IP set, which sets the skb's mark
field for any matched entries. The POSTROUTING chain is suitable for a router or
middlebox that forwards packets.

```
iptables -o enp1s0 -t mangle -A POSTROUTING \
	-j SET --map-set subscribers dst --map-mark
```

Note that we may also use the eBPF filter `priority_to_classid.o` instead, just
be sure that the major number of the priority field doesn't match Cake's qdisc
handle, or else Cake's tin may inadvertently be selected (see the following
section). Using the mark field avoids this potential conflict.

### Tin

Cake's tin may be selected using the packet's priority field. If the major
number of the priority field matches the qdisc's handle, then the minor number
of the priority field selects the tin using a 1-based index.

First, we add our cake qdisc, with an explicit handle of 20, and the `diffserv4`
keyword, which gives us four tins: Bulk (1), Best Effort (2), Video (3) and
Voice (4).

```
tc qdisc add dev enp1s0 handle 20: root cake bandwidth 50Mbit diffserv4
```

Next, we create and populate an IP set of the appropriate type. Each entry
assigns the priority field using a major number of 20, our qdisc's handle, and a
minor number of the desired Cake tin. Here, we send traffic destined to 10.7.1.2
and 10.7.1.3 to tin 2 (Best Effort) and traffic destined to 10.7.1.4 to tin 3
(Video).

```
ipset create subscribers hash:ip skbinfo
ipset add subscribers 10.7.1.2 skbprio 20:2
ipset add subscribers 10.7.1.3 skbprio 20:2
ipset add subscribers 10.7.1.4 skbprio 20:3
```

Finally, we add a rule to the iptables mangle table that matches the destination
address of the packet using the `subscribers` IP set, which sets the skb's
priority field for any matched entries. The POSTROUTING chain is suitable for a
router or middlebox that forwards packets.

```
iptables -o enp1s0 -t mangle -A POSTROUTING \
	-j SET --map-set subscribers dst --map-prio
```

It's possible for an IP set entry to override *both* the priority field and the
firewall mark. Thus, it's possible to customize both the isolation and the tin
at the same time. Using our example above, something like the below should work
for the ipset entry, in combination with the `mark_to_classid.o` eBPF filter,
and both `--map-prio` and `--map-mark` to iptables.  Here we assign a subscriber
ID of 1, and place traffic in the tin 2 (Best Effort).

```
ipset add subscribers 10.7.1.2 skbmark 0x10000 skbprio 20:2
```

Note however that this may not be desirable for an ISP to do. Cake's tin
selection takes priority over the host isolation, which is backwards from how an
ISP typically operates, which will likely want to first enforce subscriber
isolation, then priority levels.

## qdisc_classify.sh

`qdisc_classify.sh` is a standalone test script that demonstrates how to do
custom qdisc classification. It sets up a netns environment with three
namespaces, a client, a middlebox and a server. Three iperf3 servers are started
on the server. We then test three flows, two TCP flows and one unresponsive UDP
flow, from two different "subscribers", to show different host and flow
isolation scenarios using fq_codel, sfq, fq_pie and Cake.

*Prerequisites:* ipset, iperf3, BPF and BPF_SYSCALL support in kernel

To run it, simply execute as root, or see
[sample output](qdisc_classify.md):

`./qdisc_classify.sh`

**Note:** When running the script, ignore any warnings like the below, which
happen when running eBPF in network namespaces, and do not affect the results:

```
Continuing without mounted eBPF fs. Too old kernel?
```

It's usually not necessary to rebuild the eBPF classifiers, because the
executable format is portable. The pre-built objects in this repo have been
tested on amd64 with kernel 5.10, and arm64 with kernel 5.4. If the eBPF
examples don't work, try recompiling with `make`, which will also require clang
and libbpf.

## More Info

### Beyond IP Addresses

IP sets can also match by
[MAC address, IP/port, subnet, etc.](https://ipset.netfilter.org/features.html),
supporting many thousands of elements with little runtime overhead.

### CAKE_QUEUES

Cake is compiled with **1024 queues** by default (CAKE_QUEUES define). Thus,
the major and minor classids used must be <= 1024, or else the flow isolation
will not be overridden. CAKE_QUEUES may need to be increased, depending on the
requirements. Without changing it, the approach laid out here is suitable for up
to 1024 users, and practically, fewer total concurrent flows.

### Implications for the Evolution of ECN

The IETF is currently considering experimentation with
[L4S](https://github.com/heistp/l4s-tests/) style ECN signaling. L4S uses a
definition of the CE codepoint that is incompatible with the existing definition
in RFC3168, therefore, L4S flows dominate non-L4S flows in
[shared RFC3168 queues](https://github.com/heistp/l4s-tests/#unsafety-in-shared-rfc3168-queues).

While FQ can sometimes protect non-L4S flows from L4S flows, customization of
the flow classification as described here may circumvent this protection. For
example, this can happen when host fairness is configured using fq_codel, or
with Cake without flow hashing. Should that experiment go forward, it may be
possible to direct L4S and non-L4S flows to separate queues by adding ECT(1) to
the hash, but that exercise is left up to the reader.
