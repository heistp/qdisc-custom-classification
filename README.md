# ipset-qdisc-classification

Using ipsets to do custom flow classification with the sfq, fq_codel, fq_pie and
cake qdiscs in Linux

## Introduction

With the fair queueing (FQ) qdiscs in Linux, including sfq, fq_codel, and
fq_pie, it's possible to customize what constitutes a flow for the purposes of
FQ. This is done with the 32-bit `priority` field on the packet. When the major
number (upper 16 bits) of the priority matches the qdisc's handle, the minor
number (lower 16 bits) is used for classification, instead of a hash of the
packet's 5-tuple or 3-tuple. This code segment comes from fq_codel, and is
similar in sfq and fq_pie:

```
static unsigned int fq_codel_classify(struct sk_buff *skb, struct Qdisc *sch,
                                      int *qerr)
{
        ...

        if (TC_H_MAJ(skb->priority) == sch->handle &&
            TC_H_MIN(skb->priority) > 0 &&
            TC_H_MIN(skb->priority) <= q->flows_cnt)
                return TC_H_MIN(skb->priority);
        ...
}
```

For [cake](https://www.bufferbloat.net/projects/codel/wiki/Cake/), two levels of
isolation are possible, host and flow. Instead of the priority field, which
is used for tin selection, cake uses the major and minor numbers from an
attached filter's classid for host and flow isolation, respectively:

```
static u32 cake_classify(struct Qdisc *sch, struct cake_tin_data **t,
                         struct sk_buff *skb, int flow_mode, int *qerr)
{
        ...
        if (TC_H_MIN(res.classid) <= CAKE_QUEUES)
                flow = TC_H_MIN(res.classid);
        if (TC_H_MAJ(res.classid) <= (CAKE_QUEUES << 16))
                host = TC_H_MAJ(res.classid) >> 16;
        ...
}
```

The priority and classid fields are commonly set using tc filters. Two examples
of this are provided in the
[cake man page](https://man7.org/linux/man-pages/man8/tc-cake.8.html#OVERRIDING_CLASSIFICATION_WITH_TC_FILTERS).
The first uses [skbedit](https://man7.org/linux/man-pages/man8/tc-skbedit.8.html)
to set the priority field, and the second sets the major and minor classid.

TC filters may be enough for some applications, but what if we have a large set
of IP or MAC addresses to map to queues? This may be a common use case at an ISP
that wants fairness between its subscribers, for example. One or more IP or MAC
addresses may map to each queue, but it becomes too expensive to add filters for
each when they're processed linearly per-packet.

[IP sets](https://ipset.netfilter.org/) provide scalable, in-kernel sets of
various IP related types, like IP addresses, MAC addresses, subnets, etc. Each
of these set types supports the skbinfo extension (described in the [ipset(8)
man page](https://ipset.netfilter.org/ipset.man.html)), which allows setting the
firewall mark or skb priority individually for each matching ipset entry. Here
we show how to use this capability for custom classification in qdiscs.

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

With cake, we use the term "classification" to refer to both the isolation (host
and flow) and the tin (or priority level). See the
[cake man page](https://man7.org/linux/man-pages/man8/tc-cake.8.html#OVERRIDING_CLASSIFICATION_WITH_TC_FILTERS)
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

To customize only Cake's flow isolation, one option is to use
[tc-flow](https://man7.org/linux/man-pages/man8/tc-flow.8.html). This allows
mapping a packet's priority or mark fields onto the classid. Similar to our
regular FQ qdiscs, this is a three step process.

First, we add our cake qdisc. We also add a filter that uses tc-flow to map the
lower 16 bits of the packet's priority field to the minor classid. The value is
not copied directly, but starts with a minor classid of 1, so a priority with a
minor ID of 2 maps to a minor classid of 3. A handle must be specified to the
filter for it to work, although the handle number is arbitrary.

```
tc qdisc add dev enp1s0 handle 1: root cake bandwidth 50Mbit
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

## ipset_qdisc_classify.sh

To run it, simply execute as root, or see
[sample output](ipset_qdisc_classify.md):

`./ipset_qdisc_classify.sh`

*Prerequisites:* ipset, iperf3, BPF and BPF_SYSCALL support in kernel

`ipset_qdisc_classify.sh` is a standalone test script that demonstrates how to
do custom qdisc classification with IP sets. It sets up a netns environment with
three namespaces, a client, a middlebox and a server. Three iperf3 servers are
started on the server. We then test three flows, two TCP flows and one
unresponsive UDP flow, from two different "subscribers", to show different host
and flow isolation scenarios using fq_codel, sfq, fq_pie and cake.

It's usually not necessary to rebuild the eBPF classifiers, because the
executable format is portable. The pre-built objects in this repo have been
tested on amd64 with kernel 5.10, and arm64 with kernel 5.4. If the eBPF
examples don't work, try recompiling with `make`, which will also require clang
and libbpf.

**Note:** When running the script, ignore any warnings like the below, which
happen when running eBPF in network namespaces, and do not affect the results:

```
Continuing without mounted eBPF fs. Too old kernel?
```

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
to 1024 users, and practically, far fewer total concurrent flows.

### Implications for the Evolution of ECN

The IETF is currently on a path to consider the approval of
[L4S](https://github.com/heistp/l4s-tests/) style ECN signaling. L4S uses a
definition of the CE codepoint that is incompatible with the existing definition
in RFC3168, therefore, L4S flows dominate non-L4S flows in
[shared RFC3168 queues](https://github.com/heistp/l4s-tests/#unsafety-in-shared-rfc3168-queues), which is something to be avoided.

While FQ can sometimes protect non-L4S flows from L4S flows, using IP sets for
flow classification as described here (such as by IP or MAC address, with
fq_codel or Cake without flow hashing), is another potential path to flows
sharing RFC3168 queues, besides tunnels and hash collisions.
