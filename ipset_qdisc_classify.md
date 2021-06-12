```
fq_codel: use priority field to override flow classification:
=============================================================

Here, we set the priority field to a classid with the major number
the same as the fq_codel major number (handle), and the minor number
to the subscriber ID. This way, we get a single Codel queue
per-subscriber.

As expected, we see fairness between Subscriber 1 and Subscriber 2,
and Subscriber 2's unresponsive UDP flow dominates their TCP flow,
because they're both in Subscriber 2's queue.

+ ip netns exec mid tc qdisc add dev mid.r root handle 1: htb default 10
+ ip netns exec mid tc class add dev mid.r parent 1: classid 1:10 htb rate 50Mbit
+ ip netns exec mid tc qdisc add dev mid.r handle 20: parent 1:10 fq_codel
+ ip netns exec mid ipset create subscribers hash:ip skbinfo
+ ip netns exec mid ipset add subscribers 10.7.1.2 skbprio 20:1
+ ip netns exec mid ipset add subscribers 10.7.1.3 skbprio 20:2
+ ip netns exec mid ipset add subscribers 10.7.1.4 skbprio 20:2
+ ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING -j SET --map-set subscribers dst --map-prio
+ set +x

Subscriber 1, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.2, port 5202
[  6] local 10.7.0.2 port 58322 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  3.30 MBytes  27.7 Mbits/sec   19   26.9 KBytes       
[  6]   1.00-2.00   sec  2.80 MBytes  23.5 Mbits/sec   19   21.2 KBytes       
[  6]   2.00-3.00   sec  2.80 MBytes  23.5 Mbits/sec   18   25.5 KBytes       
[  6]   3.00-4.00   sec  2.80 MBytes  23.5 Mbits/sec   20   18.4 KBytes       
[  6]   4.00-5.00   sec  2.98 MBytes  25.0 Mbits/sec   18   18.4 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  14.7 MBytes  24.6 Mbits/sec   94             sender
[  6]   0.00-5.01   sec  14.3 MBytes  23.9 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 55458 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec   970 KBytes  7.94 Mbits/sec    9   12.7 KBytes       
[  6]   1.00-2.00   sec   573 KBytes  4.69 Mbits/sec   16   8.48 KBytes       
[  6]   2.00-3.00   sec   764 KBytes  6.26 Mbits/sec   24   7.07 KBytes       
[  6]   3.00-4.00   sec   573 KBytes  4.69 Mbits/sec   33   4.24 KBytes       
[  6]   4.00-5.00   sec   573 KBytes  4.69 Mbits/sec   14   8.48 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  3.37 MBytes  5.66 Mbits/sec   96             sender
[  6]   0.00-5.00   sec  3.03 MBytes  5.07 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 34758 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.01   sec  11.5 MBytes  19.2 Mbits/sec  0.536 ms  338/8632 (3.9%)  receiver

iperf Done.

sfq: use priority field to override flow classification:
========================================================

Here, we set the priority field to a classid with the major number
the same as the sfq major number (handle), and the minor number
to the subscriber ID. This way, we get a single queue per-subscriber.

As expected, we see fairness between Subscriber 1 and Subscriber 2,
and Subscriber 2's unresponsive UDP flow dominates their TCP flow,
because they're both in Subscriber 2's queue.

+ ip netns exec mid tc qdisc add dev mid.r root handle 1: htb default 10
+ ip netns exec mid tc class add dev mid.r parent 1: classid 1:10 htb rate 50Mbit
+ ip netns exec mid tc qdisc add dev mid.r handle 20: parent 1:10 sfq
+ ip netns exec mid ipset create subscribers hash:ip skbinfo
+ ip netns exec mid ipset add subscribers 10.7.1.2 skbprio 20:1
+ ip netns exec mid ipset add subscribers 10.7.1.3 skbprio 20:2
+ ip netns exec mid ipset add subscribers 10.7.1.4 skbprio 20:2
+ ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING -j SET --map-set subscribers dst --map-prio
+ set +x

Subscriber 1, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.2, port 5202
[  6] local 10.7.0.2 port 58334 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  4.96 MBytes  41.6 Mbits/sec  414    129 KBytes       
[  6]   1.00-2.00   sec  3.23 MBytes  27.1 Mbits/sec    1    109 KBytes       
[  6]   2.00-3.00   sec  3.17 MBytes  26.6 Mbits/sec    0    127 KBytes       
[  6]   3.00-4.00   sec  2.11 MBytes  17.7 Mbits/sec    0    144 KBytes       
[  6]   4.00-5.00   sec  3.17 MBytes  26.6 Mbits/sec    0    158 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  16.6 MBytes  27.9 Mbits/sec  415             sender
[  6]   0.00-5.05   sec  14.4 MBytes  24.0 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 55466 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  2.94 MBytes  24.6 Mbits/sec  323   19.8 KBytes       
[  6]   1.00-2.00   sec   636 KBytes  5.21 Mbits/sec    2   21.2 KBytes       
[  6]   2.00-3.00   sec   636 KBytes  5.21 Mbits/sec    1   26.9 KBytes       
[  6]   3.00-4.00   sec   636 KBytes  5.21 Mbits/sec    6   21.2 KBytes       
[  6]   4.00-5.00   sec   636 KBytes  5.21 Mbits/sec    2   28.3 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  5.42 MBytes  9.10 Mbits/sec  334             sender
[  6]   0.00-5.03   sec  3.71 MBytes  6.19 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 54147 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.04   sec  10.8 MBytes  18.0 Mbits/sec  0.532 ms  805/8632 (9.3%)  receiver

iperf Done.

fq_pie: use priority field to override flow classification:
===========================================================

Here, we set the priority field to a classid with the major number
the same as the fq_pie major number (handle), and the minor number
to the subscriber ID. This way, we get a single queue per-subscriber.

As expected, we see fairness between Subscriber 1 and Subscriber 2,
and Subscriber 2's unresponsive UDP flow dominates their TCP flow,
because they're both in Subscriber 2's queue.

+ ip netns exec mid tc qdisc add dev mid.r root handle 1: htb default 10
+ ip netns exec mid tc class add dev mid.r parent 1: classid 1:10 htb rate 50Mbit
+ ip netns exec mid tc qdisc add dev mid.r handle 20: parent 1:10 fq_pie
+ ip netns exec mid ipset create subscribers hash:ip skbinfo
+ ip netns exec mid ipset add subscribers 10.7.1.2 skbprio 20:1
+ ip netns exec mid ipset add subscribers 10.7.1.3 skbprio 20:2
+ ip netns exec mid ipset add subscribers 10.7.1.4 skbprio 20:2
+ ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING -j SET --map-set subscribers dst --map-prio
+ set +x

Subscriber 1, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.2, port 5202
[  6] local 10.7.0.2 port 58346 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  4.96 MBytes  41.6 Mbits/sec   14    452 KBytes       
[  6]   1.00-2.00   sec  3.67 MBytes  30.8 Mbits/sec  506   8.48 KBytes       
[  6]   2.00-3.00   sec  3.54 MBytes  29.7 Mbits/sec  185   15.6 KBytes       
[  6]   3.00-4.00   sec  2.36 MBytes  19.8 Mbits/sec  134   28.3 KBytes       
[  6]   4.00-5.00   sec  3.54 MBytes  29.7 Mbits/sec   26   19.8 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  18.1 MBytes  30.3 Mbits/sec  865             sender
[  6]   0.00-5.01   sec  15.2 MBytes  25.5 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 55478 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  2.94 MBytes  24.6 Mbits/sec    0    361 KBytes       
[  6]   1.00-2.00   sec  1.49 MBytes  12.5 Mbits/sec  555   4.24 KBytes       
[  6]   2.00-3.00   sec  0.00 Bytes  0.00 bits/sec   69   2.83 KBytes       
[  6]   3.00-4.00   sec   764 KBytes  6.25 Mbits/sec   30   1.41 KBytes       
[  6]   4.00-5.00   sec  0.00 Bytes  0.00 bits/sec   39   11.3 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  5.17 MBytes  8.68 Mbits/sec  693             sender
[  6]   0.00-5.00   sec  3.66 MBytes  6.14 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 52954 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.21   sec  9.84 MBytes  15.9 Mbits/sec  0.347 ms  1507/8632 (17%)  receiver

iperf Done.

cake: map priority field to minor classid with tc flow:
=======================================================

Here, we use tc-flow to map the priority field to the minor classid.
As expected, as see fairness between Subscriber 1 and Subscriber 2,
but Subscriber 2's unresponsive UDP flow dominates their TCP flow,
because they map to the same Cake flow.

+ ip netns exec mid tc qdisc add dev mid.r handle 20: root cake bandwidth 50Mbit
+ ip netns exec mid tc filter add dev mid.r parent 20: handle 0x9 flow map key priority
+ ip netns exec mid ipset create subscribers hash:ip skbinfo
+ ip netns exec mid ipset add subscribers 10.7.1.2 skbprio 0:1
+ ip netns exec mid ipset add subscribers 10.7.1.3 skbprio 0:2
+ ip netns exec mid ipset add subscribers 10.7.1.4 skbprio 0:2
+ ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING -j SET --map-set subscribers dst --map-prio
+ set +x

Subscriber 1, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.2, port 5202
[  6] local 10.7.0.2 port 58352 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  3.02 MBytes  25.3 Mbits/sec   12   19.8 KBytes       
[  6]   1.00-2.00   sec  2.86 MBytes  24.0 Mbits/sec   13   15.6 KBytes       
[  6]   2.00-3.00   sec  2.86 MBytes  24.0 Mbits/sec   13   14.1 KBytes       
[  6]   3.00-4.00   sec  2.92 MBytes  24.5 Mbits/sec   12   18.4 KBytes       
[  6]   4.00-5.00   sec  2.80 MBytes  23.5 Mbits/sec   13   15.6 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  14.5 MBytes  24.3 Mbits/sec   63             sender
[  6]   0.00-5.01   sec  14.4 MBytes  24.0 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 55490 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec   737 KBytes  6.03 Mbits/sec    7   5.66 KBytes       
[  6]   1.00-2.00   sec   636 KBytes  5.21 Mbits/sec   20   7.07 KBytes       
[  6]   2.00-3.00   sec   636 KBytes  5.21 Mbits/sec   27   5.66 KBytes       
[  6]   3.00-4.00   sec   509 KBytes  4.17 Mbits/sec   20   4.24 KBytes       
[  6]   4.00-5.00   sec   636 KBytes  5.21 Mbits/sec   30   5.66 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  3.08 MBytes  5.17 Mbits/sec  104             sender
[  6]   0.00-5.00   sec  2.82 MBytes  4.73 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 52684 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.01   sec  11.6 MBytes  19.4 Mbits/sec  0.430 ms  260/8632 (3%)  receiver

iperf Done.

cake: map firewall mark to minor classid with tc flow:
======================================================

Here, we use tc-flow to map the mark field to the minor classid.
As expected, as see fairness between Subscriber 1 and Subscriber 2,
but Subscriber 2's unresponsive UDP flow dominates their TCP flow,
because they map to the same Cake flow.

+ ip netns exec mid tc qdisc add dev mid.r handle 20: root cake bandwidth 50Mbit
+ ip netns exec mid tc filter add dev mid.r parent 20: handle 0x9 flow map key mark
+ ip netns exec mid ipset create subscribers hash:ip skbinfo
+ ip netns exec mid ipset add subscribers 10.7.1.2 skbmark 0x1
+ ip netns exec mid ipset add subscribers 10.7.1.3 skbmark 0x2
+ ip netns exec mid ipset add subscribers 10.7.1.4 skbmark 0x2
+ ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING -j SET --map-set subscribers dst --map-mark
+ set +x

Subscriber 1, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.2, port 5202
[  6] local 10.7.0.2 port 58362 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  3.02 MBytes  25.4 Mbits/sec   12   19.8 KBytes       
[  6]   1.00-2.00   sec  2.86 MBytes  24.0 Mbits/sec   13   14.1 KBytes       
[  6]   2.00-3.00   sec  2.80 MBytes  23.5 Mbits/sec   12   18.4 KBytes       
[  6]   3.00-4.00   sec  2.92 MBytes  24.5 Mbits/sec   13   18.4 KBytes       
[  6]   4.00-5.00   sec  2.86 MBytes  24.0 Mbits/sec   13   18.4 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  14.5 MBytes  24.3 Mbits/sec   63             sender
[  6]   0.00-5.01   sec  14.3 MBytes  23.9 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 55500 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec   868 KBytes  7.11 Mbits/sec    4   15.6 KBytes       
[  6]   1.00-2.00   sec   509 KBytes  4.17 Mbits/sec    9   7.07 KBytes       
[  6]   2.00-3.00   sec   636 KBytes  5.21 Mbits/sec   21   8.48 KBytes       
[  6]   3.00-4.00   sec   636 KBytes  5.21 Mbits/sec   26   4.24 KBytes       
[  6]   4.00-5.00   sec   636 KBytes  5.21 Mbits/sec   31   8.48 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  3.21 MBytes  5.38 Mbits/sec   91             sender
[  6]   0.00-5.00   sec  2.97 MBytes  4.98 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 51903 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.00   sec  11.5 MBytes  19.3 Mbits/sec  0.477 ms  304/8632 (3.5%)  receiver

iperf Done.

cake: map firewall mark to minor classid with tc-flow, failed hosts attempt:
============================================================================

Here, we attempt to use tc-flow to map the firewall mark to hosts,
but the attempt fails because tc-flow doesn't map the major classid.
All three flows end up in the same queue, because the lower 16 bits
of the mark (all zero) are added to a base class ID of :1.

+ ip netns exec mid tc qdisc add dev mid.r handle 20: root cake bandwidth 50Mbit dsthost
+ ip netns exec mid tc filter add dev mid.r parent 20: handle 0x9 flow map key mark
+ ip netns exec mid ipset create subscribers hash:ip skbinfo
+ ip netns exec mid ipset add subscribers 10.7.1.2 skbmark 0x10000
+ ip netns exec mid ipset add subscribers 10.7.1.3 skbmark 0x20000
+ ip netns exec mid ipset add subscribers 10.7.1.4 skbmark 0x20000
+ ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING -j SET --map-set subscribers dst --map-mark
+ set +x

Subscriber 1, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.2, port 5202
[  6] local 10.7.0.2 port 58372 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  1.70 MBytes  14.2 Mbits/sec    9   11.3 KBytes       
[  6]   1.00-2.00   sec  1.80 MBytes  15.1 Mbits/sec   15   12.7 KBytes       
[  6]   2.00-3.00   sec  1.55 MBytes  13.0 Mbits/sec   18   7.07 KBytes       
[  6]   3.00-4.00   sec  1.93 MBytes  16.2 Mbits/sec   18   12.7 KBytes       
[  6]   4.00-5.00   sec  1.62 MBytes  13.6 Mbits/sec   19   9.90 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  8.59 MBytes  14.4 Mbits/sec   79             sender
[  6]   0.00-5.00   sec  8.47 MBytes  14.2 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 55510 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  2.06 MBytes  17.3 Mbits/sec    9   11.3 KBytes       
[  6]   1.00-2.00   sec  1.62 MBytes  13.6 Mbits/sec   15   8.48 KBytes       
[  6]   2.00-3.00   sec  1.86 MBytes  15.6 Mbits/sec   16   14.1 KBytes       
[  6]   3.00-4.00   sec  1.37 MBytes  11.5 Mbits/sec   19   12.7 KBytes       
[  6]   4.00-5.00   sec  1.86 MBytes  15.6 Mbits/sec   21   11.3 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  8.77 MBytes  14.7 Mbits/sec   80             sender
[  6]   0.00-5.00   sec  8.52 MBytes  14.3 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 35588 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8631 (0%)  sender
[  6]   0.00-5.01   sec  11.7 MBytes  19.7 Mbits/sec  0.263 ms  125/8631 (1.4%)  receiver

iperf Done.

cake: map priority field to classid with eBPF, hosts only:
==========================================================

Here, we use an eBPF classifier to map the priority field to the classid,
using the major ID only.

Because eBPF can map the major classid, we see both fairness between
Subscriber 1 and Subscriber 2, and also between Subscriber 2's
TCP and unresponsive UDP flows, because Cake hashes the flows as
usual when we haven't specified the minor classid.

+ ip netns exec mid tc qdisc add dev mid.r handle 20: root cake bandwidth 50Mbit
+ ip netns exec mid tc filter add dev mid.r parent 20: bpf obj priority_to_classid.o
Continuing without mounted eBPF fs. Too old kernel?
+ ip netns exec mid ipset create subscribers hash:ip skbinfo
+ ip netns exec mid ipset add subscribers 10.7.1.2 skbprio 1:0
+ ip netns exec mid ipset add subscribers 10.7.1.3 skbprio 2:0
+ ip netns exec mid ipset add subscribers 10.7.1.4 skbprio 2:0
+ ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING -j SET --map-set subscribers dst --map-prio
+ set +x

Subscriber 1, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.2, port 5202
[  6] local 10.7.0.2 port 58386 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  2.99 MBytes  25.1 Mbits/sec   12   17.0 KBytes       
[  6]   1.00-2.00   sec  2.86 MBytes  24.0 Mbits/sec   13   14.1 KBytes       
[  6]   2.00-3.00   sec  2.86 MBytes  24.0 Mbits/sec   13   14.1 KBytes       
[  6]   3.00-4.00   sec  2.80 MBytes  23.5 Mbits/sec   12   19.8 KBytes       
[  6]   4.00-5.00   sec  2.86 MBytes  24.0 Mbits/sec   13   18.4 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  14.4 MBytes  24.1 Mbits/sec   63             sender
[  6]   0.00-5.00   sec  14.3 MBytes  23.9 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 55516 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  1.53 MBytes  12.9 Mbits/sec   16   7.07 KBytes       
[  6]   1.00-2.00   sec  1.43 MBytes  12.0 Mbits/sec   16   5.66 KBytes       
[  6]   2.00-3.00   sec  1.43 MBytes  12.0 Mbits/sec   15   11.3 KBytes       
[  6]   3.00-4.00   sec  1.43 MBytes  12.0 Mbits/sec   17   5.66 KBytes       
[  6]   4.00-5.00   sec  1.43 MBytes  12.0 Mbits/sec   16   5.66 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  7.25 MBytes  12.2 Mbits/sec   80             sender
[  6]   0.00-5.00   sec  7.13 MBytes  12.0 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 59382 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.00   sec  7.25 MBytes  12.2 Mbits/sec  0.428 ms  1628/6878 (24%)  receiver

iperf Done.

cake: map priority field to classid with eBPF, hosts and flows:
===============================================================

Here, we use an eBPF classifier to map the priority field to the classid,
using both the major and minor parts of the class ID.

Because eBPF can map both the major and minor classid, we see
fairness between Subscriber 1 and Subscriber 2, and we see Subscriber 2's
unresponsive UDP flow dominate their TCP flow, since we have mapped
them to the same Cake flow.

+ ip netns exec mid tc qdisc add dev mid.r handle 20: root cake bandwidth 50Mbit
+ ip netns exec mid tc filter add dev mid.r parent 20: bpf obj priority_to_classid.o
Continuing without mounted eBPF fs. Too old kernel?
+ ip netns exec mid ipset create subscribers hash:ip skbinfo
+ ip netns exec mid ipset add subscribers 10.7.1.2 skbprio 1:3
+ ip netns exec mid ipset add subscribers 10.7.1.3 skbprio 2:4
+ ip netns exec mid ipset add subscribers 10.7.1.4 skbprio 2:4
+ ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING -j SET --map-set subscribers dst --map-prio
+ set +x

Subscriber 1, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.2, port 5202
[  6] local 10.7.0.2 port 58396 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  3.02 MBytes  25.4 Mbits/sec   12   18.4 KBytes       
[  6]   1.00-2.00   sec  2.86 MBytes  24.0 Mbits/sec   13   18.4 KBytes       
[  6]   2.00-3.00   sec  2.86 MBytes  24.0 Mbits/sec   13   18.4 KBytes       
[  6]   3.00-4.00   sec  2.80 MBytes  23.5 Mbits/sec   13   14.1 KBytes       
[  6]   4.00-5.00   sec  2.86 MBytes  24.0 Mbits/sec   13   18.4 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  14.4 MBytes  24.1 Mbits/sec   64             sender
[  6]   0.00-5.00   sec  14.3 MBytes  23.9 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 55528 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec   776 KBytes  6.36 Mbits/sec    7   9.90 KBytes       
[  6]   1.00-2.00   sec   573 KBytes  4.69 Mbits/sec   16   5.66 KBytes       
[  6]   2.00-3.00   sec   636 KBytes  5.21 Mbits/sec   22   7.07 KBytes       
[  6]   3.00-4.00   sec   636 KBytes  5.21 Mbits/sec   30   4.24 KBytes       
[  6]   4.00-5.00   sec   636 KBytes  5.21 Mbits/sec   32   4.24 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  3.18 MBytes  5.34 Mbits/sec  107             sender
[  6]   0.00-5.00   sec  2.98 MBytes  5.00 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 55268 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.01   sec  11.5 MBytes  19.2 Mbits/sec  0.480 ms  318/8632 (3.7%)  receiver

iperf Done.

cake: map firewall mark with flow to classid with eBPF, hosts only:
===================================================================

Here, we use an eBPF classifier to map the firewall mark to the classid,
using the major ID only.

Because eBPF can map the major classid, we see both fairness between
Subscriber 1 and Subscriber 2, and also between Subscriber 2's
TCP and unresponsive UDP flows, because Cake hashes the flows as
usual when we haven't specified the minor classid.

+ ip netns exec mid tc qdisc add dev mid.r handle 20: root cake bandwidth 50Mbit
+ ip netns exec mid tc filter add dev mid.r parent 20: bpf obj mark_to_classid.o
Continuing without mounted eBPF fs. Too old kernel?
+ ip netns exec mid ipset create subscribers hash:ip skbinfo
+ ip netns exec mid ipset add subscribers 10.7.1.2 skbmark 0x10000
+ ip netns exec mid ipset add subscribers 10.7.1.3 skbmark 0x20000
+ ip netns exec mid ipset add subscribers 10.7.1.4 skbmark 0x20000
+ ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING -j SET --map-set subscribers dst --map-mark
+ set +x

Subscriber 1, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.2, port 5202
[  6] local 10.7.0.2 port 58408 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  3.02 MBytes  25.4 Mbits/sec   12   18.4 KBytes       
[  6]   1.00-2.00   sec  2.80 MBytes  23.5 Mbits/sec   13   18.4 KBytes       
[  6]   2.00-3.00   sec  2.86 MBytes  24.0 Mbits/sec   13   18.4 KBytes       
[  6]   3.00-4.00   sec  2.86 MBytes  24.0 Mbits/sec   13   12.7 KBytes       
[  6]   4.00-5.00   sec  2.86 MBytes  24.0 Mbits/sec   13   14.1 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  14.4 MBytes  24.1 Mbits/sec   64             sender
[  6]   0.00-5.00   sec  14.3 MBytes  23.9 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 55544 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  1.56 MBytes  13.1 Mbits/sec   15   11.3 KBytes       
[  6]   1.00-2.00   sec  1.43 MBytes  12.0 Mbits/sec   16   8.48 KBytes       
[  6]   2.00-3.00   sec  1.43 MBytes  12.0 Mbits/sec   15   11.3 KBytes       
[  6]   3.00-4.00   sec  1.37 MBytes  11.5 Mbits/sec   16   8.48 KBytes       
[  6]   4.00-5.00   sec  1.43 MBytes  12.0 Mbits/sec   19   7.07 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  7.22 MBytes  12.1 Mbits/sec   81             sender
[  6]   0.00-5.00   sec  7.12 MBytes  11.9 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 43247 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.00   sec  7.25 MBytes  12.2 Mbits/sec  0.379 ms  1617/6869 (24%)  receiver

iperf Done.

cake: map firewall mark with flow to classid with eBPF, hosts and flows:
========================================================================

Here, we use an eBPF classifier to map the firewall mark to the classid,
using both the major and minor parts of the class ID.

Because eBPF can map both the major and minor classid, we see fairness
between Subscriber 1 and Subscriber 2, and we see Subscriber 2's
unresponsive UDP flow dominate their TCP flow, since we have mapped
them to the same Cake flow.

+ ip netns exec mid tc qdisc add dev mid.r handle 20: root cake bandwidth 50Mbit
+ ip netns exec mid tc filter add dev mid.r parent 20: bpf obj mark_to_classid.o
Continuing without mounted eBPF fs. Too old kernel?
+ ip netns exec mid ipset create subscribers hash:ip skbinfo
+ ip netns exec mid ipset add subscribers 10.7.1.2 skbmark 0x10003
+ ip netns exec mid ipset add subscribers 10.7.1.3 skbmark 0x20004
+ ip netns exec mid ipset add subscribers 10.7.1.4 skbmark 0x20004
+ ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING -j SET --map-set subscribers dst --map-mark
+ set +x

Subscriber 1, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.2, port 5202
[  6] local 10.7.0.2 port 58418 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  3.02 MBytes  25.4 Mbits/sec   12   19.8 KBytes       
[  6]   1.00-2.00   sec  2.80 MBytes  23.5 Mbits/sec   13   12.7 KBytes       
[  6]   2.00-3.00   sec  2.92 MBytes  24.5 Mbits/sec   12   18.4 KBytes       
[  6]   3.00-4.00   sec  2.80 MBytes  23.5 Mbits/sec   15   18.4 KBytes       
[  6]   4.00-5.00   sec  2.86 MBytes  24.0 Mbits/sec   13   15.6 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  14.4 MBytes  24.1 Mbits/sec   65             sender
[  6]   0.00-5.00   sec  14.3 MBytes  23.9 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 55550 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec   868 KBytes  7.11 Mbits/sec    4   15.6 KBytes       
[  6]   1.00-2.00   sec   509 KBytes  4.17 Mbits/sec   11   7.07 KBytes       
[  6]   2.00-3.00   sec   636 KBytes  5.21 Mbits/sec   20   5.66 KBytes       
[  6]   3.00-4.00   sec   636 KBytes  5.21 Mbits/sec   26   7.07 KBytes       
[  6]   4.00-5.00   sec   636 KBytes  5.21 Mbits/sec   31   4.24 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  3.21 MBytes  5.38 Mbits/sec   92             sender
[  6]   0.00-5.00   sec  2.99 MBytes  5.01 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 39031 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8631 (0%)  sender
[  6]   0.00-5.01   sec  11.5 MBytes  19.2 Mbits/sec  0.492 ms  317/8631 (3.7%)  receiver

iperf Done.
```
