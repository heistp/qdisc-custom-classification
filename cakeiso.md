```
Map priority field to classid with tc flow, flows only:
=======================================================

Here, we use tc-flow to map the priority field to the minor classid.
As expected, as see fairness between Subscriber 1 and Subscriber 2,
but Subscriber 2's unresponsive UDP flow dominates their TCP flow,
because they map to the same Cake flow.

+ ip netns exec mid ipset create subscribers hash:ip skbinfo
+ ip netns exec mid ipset add subscribers 10.7.1.2 skbprio 0:1
+ ip netns exec mid ipset add subscribers 10.7.1.3 skbprio 0:2
+ ip netns exec mid ipset add subscribers 10.7.1.4 skbprio 0:2
+ ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING -j SET --map-set subscribers dst --map-prio
+ ip netns exec mid tc filter add dev mid.r parent 1: handle 0x9 flow map key priority
+ set +x

Subscriber 1, TCP client:
-------------------------
Connecting to host 10.7.1.2, port 5202
[  6] local 10.7.0.2 port 41124 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  3.08 MBytes  25.9 Mbits/sec   12   15.6 KBytes       
[  6]   1.00-2.00   sec  2.73 MBytes  22.9 Mbits/sec   13   14.1 KBytes       
[  6]   2.00-3.00   sec  2.98 MBytes  25.0 Mbits/sec   12   14.1 KBytes       
[  6]   3.00-4.00   sec  2.86 MBytes  24.0 Mbits/sec   13   14.1 KBytes       
[  6]   4.00-5.00   sec  2.86 MBytes  24.0 Mbits/sec   13   14.1 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  14.5 MBytes  24.4 Mbits/sec   63             sender
[  6]   0.00-5.00   sec  14.4 MBytes  24.1 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client:
-----------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 56174 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec   735 KBytes  6.02 Mbits/sec    5   9.90 KBytes       
[  6]   1.00-2.00   sec   573 KBytes  4.69 Mbits/sec   17   8.48 KBytes       
[  6]   2.00-3.00   sec   509 KBytes  4.17 Mbits/sec   17   4.24 KBytes       
[  6]   3.00-4.00   sec   636 KBytes  5.21 Mbits/sec   25   5.66 KBytes       
[  6]   4.00-5.00   sec   636 KBytes  5.21 Mbits/sec   24   9.90 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  3.02 MBytes  5.06 Mbits/sec   88             sender
[  6]   0.00-5.00   sec  2.91 MBytes  4.88 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 38458 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.01   sec  11.5 MBytes  19.2 Mbits/sec  0.535 ms  331/8632 (3.8%)  receiver

iperf Done.

Map firewall mark to classid with tc flow, flows only:
======================================================

Here, we use tc-flow to map the priority field to the minor classid.
As expected, as see fairness between Subscriber 1 and Subscriber 2,
but Subscriber 2's unresponsive UDP flow dominates their TCP flow,
because they map to the same Cake flow.

+ ip netns exec mid ipset create subscribers hash:ip skbinfo
+ ip netns exec mid ipset add subscribers 10.7.1.2 skbmark 0x1
+ ip netns exec mid ipset add subscribers 10.7.1.3 skbmark 0x2
+ ip netns exec mid ipset add subscribers 10.7.1.4 skbmark 0x2
+ ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING -j SET --map-set subscribers dst --map-mark
+ ip netns exec mid tc filter add dev mid.r parent 1: handle 0x9 flow map key mark
+ set +x

Subscriber 1, TCP client:
-------------------------
Connecting to host 10.7.1.2, port 5202
[  6] local 10.7.0.2 port 41136 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  3.02 MBytes  25.4 Mbits/sec   12   19.8 KBytes       
[  6]   1.00-2.00   sec  2.80 MBytes  23.5 Mbits/sec   13   18.4 KBytes       
[  6]   2.00-3.00   sec  2.86 MBytes  24.0 Mbits/sec   13   14.1 KBytes       
[  6]   3.00-4.00   sec  2.86 MBytes  24.0 Mbits/sec   12   18.4 KBytes       
[  6]   4.00-5.00   sec  2.86 MBytes  24.0 Mbits/sec   14   12.7 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  14.4 MBytes  24.1 Mbits/sec   64             sender
[  6]   0.00-5.00   sec  14.3 MBytes  23.9 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client:
-----------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 56184 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec   721 KBytes  5.91 Mbits/sec    6   8.48 KBytes       
[  6]   1.00-2.00   sec   636 KBytes  5.21 Mbits/sec   18   4.24 KBytes       
[  6]   2.00-3.00   sec   636 KBytes  5.21 Mbits/sec   16   7.07 KBytes       
[  6]   3.00-4.00   sec   573 KBytes  4.69 Mbits/sec   31   7.07 KBytes       
[  6]   4.00-5.00   sec   700 KBytes  5.73 Mbits/sec   29   5.66 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  3.19 MBytes  5.35 Mbits/sec  100             sender
[  6]   0.00-5.00   sec  2.96 MBytes  4.96 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 42725 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.21   sec  11.5 MBytes  18.5 Mbits/sec  0.447 ms  298/8632 (3.5%)  receiver

iperf Done.

Map firewall mark to classid with tc-flow, failed hosts attempt:
================================================================

Here, we attempt to use tc-flow to map the firewall mark to hosts,
but the attempt fails because tc-flow doesn't map the major classid.
There is no fairness between subscribers, and the unresponsive flow wins.

+ ip netns exec mid ipset create subscribers hash:ip skbinfo
+ ip netns exec mid ipset add subscribers 10.7.1.2 skbmark 0x10000
+ ip netns exec mid ipset add subscribers 10.7.1.3 skbmark 0x20000
+ ip netns exec mid ipset add subscribers 10.7.1.4 skbmark 0x20000
+ ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING -j SET --map-set subscribers dst --map-mark
+ ip netns exec mid tc filter add dev mid.r parent 1: handle 0x9 flow map key mark
+ set +x

Subscriber 1, TCP client:
-------------------------
Connecting to host 10.7.1.2, port 5202
[  6] local 10.7.0.2 port 41144 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  1.63 MBytes  13.6 Mbits/sec   10   8.48 KBytes       
[  6]   1.00-2.00   sec  1.93 MBytes  16.2 Mbits/sec   13   11.3 KBytes       
[  6]   2.00-3.00   sec  1.74 MBytes  14.6 Mbits/sec   17   12.7 KBytes       
[  6]   3.00-4.00   sec  1.68 MBytes  14.1 Mbits/sec   19   11.3 KBytes       
[  6]   4.00-5.00   sec  1.74 MBytes  14.6 Mbits/sec   20   11.3 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  8.71 MBytes  14.6 Mbits/sec   79             sender
[  6]   0.00-5.00   sec  8.60 MBytes  14.4 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client:
-----------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 56194 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  2.34 MBytes  19.6 Mbits/sec   10   19.8 KBytes       
[  6]   1.00-2.00   sec  1.30 MBytes  10.9 Mbits/sec   20   7.07 KBytes       
[  6]   2.00-3.00   sec  1.68 MBytes  14.1 Mbits/sec   16   5.66 KBytes       
[  6]   3.00-4.00   sec  1.68 MBytes  14.1 Mbits/sec   18   8.48 KBytes       
[  6]   4.00-5.00   sec  1.68 MBytes  14.1 Mbits/sec   18   5.66 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  8.68 MBytes  14.6 Mbits/sec   82             sender
[  6]   0.00-5.00   sec  8.34 MBytes  14.0 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 38411 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.00   sec  11.8 MBytes  19.8 Mbits/sec  0.285 ms  97/8632 (1.1%)  receiver

iperf Done.

Map priority field to classid with eBPF, hosts only:
====================================================

Here, we use an eBPF classifier to map the priority field to the classid,
using the major ID only.

Because eBPF can map the major classid, we see both fairness between
Subscriber 1 and Subscriber 2, and also between Subscriber 2's
TCP and unresponsive UDP flows, because Cake hashes the flows when
we haven't specified the minor classid.

Continuing without mounted eBPF fs. Too old kernel?

Subscriber 1, TCP client:
-------------------------
Connecting to host 10.7.1.2, port 5202
[  6] local 10.7.0.2 port 41158 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  2.96 MBytes  24.8 Mbits/sec   12   15.6 KBytes       
[  6]   1.00-2.00   sec  2.86 MBytes  24.0 Mbits/sec   12   18.4 KBytes       
[  6]   2.00-3.00   sec  2.86 MBytes  24.0 Mbits/sec   13   14.1 KBytes       
[  6]   3.00-4.00   sec  2.86 MBytes  24.0 Mbits/sec   13   14.1 KBytes       
[  6]   4.00-5.00   sec  2.86 MBytes  24.0 Mbits/sec   12   19.8 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  14.4 MBytes  24.1 Mbits/sec   62             sender
[  6]   0.00-5.00   sec  14.3 MBytes  23.9 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client:
-----------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 56206 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  1.56 MBytes  13.1 Mbits/sec   17   7.07 KBytes       
[  6]   1.00-2.00   sec  1.43 MBytes  12.0 Mbits/sec   15   8.48 KBytes       
[  6]   2.00-3.00   sec  1.43 MBytes  12.0 Mbits/sec   17   7.07 KBytes       
[  6]   3.00-4.00   sec  1.37 MBytes  11.5 Mbits/sec   16   11.3 KBytes       
[  6]   4.00-5.00   sec  1.43 MBytes  12.0 Mbits/sec   19   5.66 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  7.22 MBytes  12.1 Mbits/sec   84             sender
[  6]   0.00-5.00   sec  7.13 MBytes  12.0 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 34876 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.00   sec  7.25 MBytes  12.2 Mbits/sec  0.521 ms  1597/6847 (23%)  receiver

iperf Done.

Map priority field to classid with eBPF, hosts and flows:
=========================================================

Here, we use an eBPF classifier to map the priority field to the classid,
using both the major and minor parts of the class ID.

Because eBPF can map both the major and minor classid, we see
fairness between Subscriber 1 and Subscriber 2, and we see Subscriber 2's
unresponsive UDP flow dominate their TCP flow, since we have mapped
them to the same Cake flow.

Continuing without mounted eBPF fs. Too old kernel?

Subscriber 1, TCP client:
-------------------------
Connecting to host 10.7.1.2, port 5202
[  6] local 10.7.0.2 port 41172 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  3.08 MBytes  25.9 Mbits/sec   13   12.7 KBytes       
[  6]   1.00-2.00   sec  2.73 MBytes  22.9 Mbits/sec   12   14.1 KBytes       
[  6]   2.00-3.00   sec  2.86 MBytes  24.0 Mbits/sec   13   12.7 KBytes       
[  6]   3.00-4.00   sec  2.86 MBytes  24.0 Mbits/sec   13   18.4 KBytes       
[  6]   4.00-5.00   sec  2.86 MBytes  24.0 Mbits/sec   13   14.1 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  14.4 MBytes  24.1 Mbits/sec   64             sender
[  6]   0.00-5.00   sec  14.3 MBytes  23.9 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client:
-----------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 56214 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec   735 KBytes  6.02 Mbits/sec    8   7.07 KBytes       
[  6]   1.00-2.00   sec   573 KBytes  4.69 Mbits/sec   17   5.66 KBytes       
[  6]   2.00-3.00   sec   636 KBytes  5.21 Mbits/sec   20   7.07 KBytes       
[  6]   3.00-4.00   sec   573 KBytes  4.69 Mbits/sec   30   4.24 KBytes       
[  6]   4.00-5.00   sec   636 KBytes  5.21 Mbits/sec   31   5.66 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  3.08 MBytes  5.17 Mbits/sec  106             sender
[  6]   0.00-5.00   sec  2.95 MBytes  4.94 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 39350 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.01   sec  11.5 MBytes  19.3 Mbits/sec  0.407 ms  292/8632 (3.4%)  receiver

iperf Done.

Map firewall mark with flow to classid with eBPF, hosts only:
=============================================================

Here, we use an eBPF classifier to map the firewall mark to the classid,
using the major ID only.

Because eBPF can map the major classid, we see both fairness between
Subscriber 1 and Subscriber 2, and also between Subscriber 2's
TCP and unresponsive UDP flows, because Cake hashes the flows when
we haven't specified the minor classid.

Continuing without mounted eBPF fs. Too old kernel?

Subscriber 1, TCP client:
-------------------------
Connecting to host 10.7.1.2, port 5202
[  6] local 10.7.0.2 port 41204 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  2.86 MBytes  24.0 Mbits/sec   13   14.1 KBytes       
[  6]   1.00-2.00   sec  2.86 MBytes  24.0 Mbits/sec   12   18.4 KBytes       
[  6]   2.00-3.00   sec  2.86 MBytes  24.0 Mbits/sec   13   14.1 KBytes       
[  6]   3.00-4.00   sec  2.86 MBytes  24.0 Mbits/sec   13   12.7 KBytes       
[  6]   4.00-5.00   sec  2.86 MBytes  24.0 Mbits/sec   13   14.1 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  14.3 MBytes  24.0 Mbits/sec   64             sender
[  6]   0.00-5.00   sec  14.2 MBytes  23.7 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client:
-----------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 56242 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  1.59 MBytes  13.3 Mbits/sec   17   7.07 KBytes       
[  6]   1.00-2.00   sec  1.43 MBytes  12.0 Mbits/sec   15   7.07 KBytes       
[  6]   2.00-3.00   sec  1.43 MBytes  12.0 Mbits/sec   16   9.90 KBytes       
[  6]   3.00-4.00   sec  1.43 MBytes  12.0 Mbits/sec   17   8.48 KBytes       
[  6]   4.00-5.00   sec  1.43 MBytes  12.0 Mbits/sec   17   11.3 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  7.31 MBytes  12.3 Mbits/sec   82             sender
[  6]   0.00-5.00   sec  7.15 MBytes  12.0 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 57589 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.00   sec  7.33 MBytes  12.3 Mbits/sec  0.474 ms  1587/6894 (23%)  receiver

iperf Done.

Map firewall mark with flow to classid with eBPF, hosts and flows:
==================================================================

Here, we use an eBPF classifier to map the firewall mark to the classid,
using both the major and minor parts of the class ID.

Because eBPF can map both the major and minor classid, we see
fairness between Subscriber 1 and Subscriber 2, and we see Subscriber 2's
unresponsive UDP flow dominate their TCP flow, since we have mapped
them to the same Cake flow.

Continuing without mounted eBPF fs. Too old kernel?

Subscriber 1, TCP client:
-------------------------
Connecting to host 10.7.1.2, port 5202
[  6] local 10.7.0.2 port 41214 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  3.02 MBytes  25.4 Mbits/sec   13   17.0 KBytes       
[  6]   1.00-2.00   sec  2.80 MBytes  23.5 Mbits/sec   13   14.1 KBytes       
[  6]   2.00-3.00   sec  2.86 MBytes  24.0 Mbits/sec   12   18.4 KBytes       
[  6]   3.00-4.00   sec  2.86 MBytes  24.0 Mbits/sec   13   17.0 KBytes       
[  6]   4.00-5.00   sec  2.86 MBytes  24.0 Mbits/sec   13   15.6 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  14.4 MBytes  24.1 Mbits/sec   64             sender
[  6]   0.00-5.01   sec  14.3 MBytes  23.9 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client:
-----------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 56256 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec   730 KBytes  5.98 Mbits/sec    6   14.1 KBytes       
[  6]   1.00-2.00   sec   573 KBytes  4.69 Mbits/sec   14   5.66 KBytes       
[  6]   2.00-3.00   sec   700 KBytes  5.73 Mbits/sec   25   4.24 KBytes       
[  6]   3.00-4.00   sec   573 KBytes  4.69 Mbits/sec   30   5.66 KBytes       
[  6]   4.00-5.00   sec   636 KBytes  5.21 Mbits/sec   26   8.48 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  3.14 MBytes  5.26 Mbits/sec  101             sender
[  6]   0.00-5.00   sec  3.01 MBytes  5.05 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 41143 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.01   sec  11.5 MBytes  19.2 Mbits/sec  0.559 ms  334/8632 (3.9%)  receiver

iperf Done.
```
