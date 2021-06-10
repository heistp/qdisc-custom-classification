# qdisc-custom-classification

Using ipsets, tc-flow and eBPF to do custom qdisc flow classification with sfq,
fq_codel, fq_pie and cake

## Introduction

Here we show a way to customize
[Cake](https://www.bufferbloat.net/projects/codel/wiki/Cake/)'s host and flow
isolation in a scalable way, useful for small ISPs or anyone who wants to
override what constitutes a host or a flow for the purposes of isolation
and fairness. Cake already has the ability to override its flow classification
using tc filters (see the
[cake man page](https://man7.org/linux/man-pages/man8/tc-cake.8.html#OVERRIDING_CLASSIFICATION_WITH_TC_FILTERS)),
but they are processed linearly. ISPs, for example, may have many subscribers,
each with one or more IP/MAC addresses. We want isolation and fairness at two
levels:

1. between the ISP's subscribers (hosts), and
2. between the flows for each subscriber

without having to do a linear search through all the subscribers, which would
have to be done for each packet.

[IP sets](https://ipset.netfilter.org/) provide highly scalable sets of various
IP related types, like IP addresses, MAC addresses, subnets, etc. Each of these
set types supports the skbinfo extension, which allows setting the firewall mark
or skb priority individually for each ipset entry. However, Cake expects to have
tc filters as children of the Cake qdisc that set the major and minor class ID
to override the host and flow hash. We can't do this with ipsets, at least
directly.

Instead, we use the skbinfo extension of ipsets to set either the priority
field or a firewall mark, which like classids are also 32-bit unsigned values,
then we use either
[tc-flow](https://man7.org/linux/man-pages/man8/tc-flow.8.html) or
[eBPF](https://man7.org/linux/man-pages/man8/tc-bpf.8.html) in a child filter of
the Cake qdisc to map (copy) one of these to the classid. Using tc-flow, we can
only map to the minor classid, which means it can only override the flow
classification. Using an eBPF classifier, we can map to both the major and minor
classid, to flexibly override the classification for both the host and the flow.
If we only override the host, the flow is hashed automatically as usual.

## Installation

Prerequisites: ipset, iperf3 (to run `qdisc_classify.sh` test script), clang and
libbpf (for eBPF compiliation)

It's usually not necessary to rebuild the eBPF classifiers, because the
executable format is portable. The pre-built objects in this repo have been
tested on amd64 with kernel 5.10, and arm64 with kernel 5.4. If the eBPF
examples don't work, try recompiling with `make`. Your kernel also needs to
support BPF and BPF_SYSCALL, and iproute2 needs ELF library support compiled in.

## qdisc_classify.sh

`qdisc_classify.sh` is a standalone test script that demonstrates how to do this
custom isolation, and tests what works and what doesn't. It sets up a netns
environment with three namespaces, a client, a middlebox and a server. Three
iperf3 servers are started on the server. We test three flows from two different
"subscribers", two TCP flows and one unresponsive UDP flow, to show different
host and flow isolation scenarios. To run it, simply execute as root:

`./qdisc_classify.sh`

See [qdisc_classify.md](qdisc_classify.md) for sample output.

Seven different scenarios show the key concepts with tc-flow and eBPF:

- Three scenarios show how tc-flow can be used to override the flow
  classification (minor classid), but cannot be used to override the host
  classification (major classid).
- Four scenarios use the eBPF classifiers `mark_to_classid.o` and
  `priority_to_classid.o` to override the host and/or flow classification.

**Note:** Ignore any warnings like the below, which happen when running eBPF
in network namespaces, and do not affect the results:

```
Continuing without mounted eBPF fs. Too old kernel?
```

## More Info

### Beyond IP Addresses

IP sets can also match by
[MAC address, IP/port, subnet, etc.](https://ipset.netfilter.org/features.html),
supporting many thousands of elements with little runtime overhead.

### CAKE_QUEUES

Cake is only compiled with **1024 queues** by default (CAKE_QUEUES define).
Thus, the major and minor classids used must be <= 1024, or else the
classification will not be overridden. CAKE_QUEUES may need to be increased,
depending on the requirements. Without changing it, the approach laid out here
is suitable for up to 1024 users, and practically, far fewer total concurrent
flows.

### Overriding the Tin

**Heads Up:** Cake also supports overriding the tin (priority level) using the
skb priority field, which may conflict with our method of stuffing the classid
into the priority. If the major number of the priority field matches the qdisc
handle of the Cake instance, the minor number of the priority field will be used
to override the Cake tin, which may not be the intent. Either avoid conflicts
with the major number by using a Cake handle that doesn't conflict with any of
the major classids used, or use marks instead. The priority field to classid
mapping is provided in case the mark field is already in use for other purposes.

### Overriding both Isolation and Tin

It's possible for an ipset entry to override *both* the priority field and the
firewall mark. Thus, it's possible to customize both the isolation and the tin
at the same time. For example, if Cake's qdisc handle is 1, we're using
`diffserv4` and we want to isolate traffic for the IP 10.7.1.2, and put it into
the Video tin, something like this should work for the ipset entry, in
combination with the `mark_to_classid.o` eBPF filter:

```
ipset add subscribers 10.7.1.2 skbmark 0x10000 skbprio 1:3
```

In case the subscriber has a second IP, 10.7.1.3, whose traffic should not be
placed in the Video tin but be directed to whichever tin it would end up in by
default, this should work:

```
ipset add subscribers 10.7.1.3 skbmark 0x10000
```
