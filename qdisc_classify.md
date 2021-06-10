```
sfq: use priority field to override flow classification:
========================================================

Here, we set the priority field to a classid with the major number
the same as the sfq major number (handle), and the minor number
to the subscriber ID. This way, we get a single queue per-subscriber.

As expected, we see fairness between Subscriber 1 and Subscriber 2,
and Subscriber 2's unresponsive UDP flow dominates their TCP flow,
because they're both in Subscriber 2's queue.

+ ip netns exec mid ipset create subscribers hash:ip skbinfo
+ ip netns exec mid ipset add subscribers 10.7.1.2 skbprio 2:1
+ ip netns exec mid ipset add subscribers 10.7.1.3 skbprio 2:2
+ ip netns exec mid ipset add subscribers 10.7.1.4 skbprio 2:2
+ ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING -j SET --map-set subscribers dst --map-prio
+ ip netns exec mid tc qdisc add dev mid.r root handle 1: htb default fff3
+ ip netns exec mid tc class add dev mid.r parent 1: classid 1:fff3 htb rate 50Mbit
+ ip netns exec mid tc qdisc add dev mid.r handle 2: parent 1:fff3 sfq
+ set +x

Subscriber 1, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.2, port 5202
[  6] local 10.7.0.2 port 49216 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  4.92 MBytes  41.2 Mbits/sec  206   93.3 KBytes       
[  6]   1.00-2.00   sec  2.24 MBytes  18.8 Mbits/sec    0    113 KBytes       
[  6]   2.00-3.00   sec  2.98 MBytes  25.0 Mbits/sec    0    132 KBytes       
[  6]   3.00-4.00   sec  2.98 MBytes  25.0 Mbits/sec    0    148 KBytes       
[  6]   4.00-5.00   sec  2.98 MBytes  25.0 Mbits/sec    0    163 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  16.1 MBytes  27.0 Mbits/sec  206             sender
[  6]   0.00-5.04   sec  14.4 MBytes  24.0 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 46352 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  2.87 MBytes  24.1 Mbits/sec  218   25.5 KBytes       
[  6]   1.00-2.00   sec   636 KBytes  5.21 Mbits/sec    1   28.3 KBytes       
[  6]   2.00-3.00   sec   636 KBytes  5.21 Mbits/sec    2   33.9 KBytes       
[  6]   3.00-4.00   sec   636 KBytes  5.21 Mbits/sec    2   28.3 KBytes       
[  6]   4.00-5.00   sec  0.00 Bytes  0.00 bits/sec    5   22.6 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  4.74 MBytes  7.95 Mbits/sec  228             sender
[  6]   0.00-5.02   sec  3.49 MBytes  5.82 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 43803 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.03   sec  11.0 MBytes  18.4 Mbits/sec  0.541 ms  648/8632 (7.5%)  receiver

iperf Done.

fq_codel: use priority field to override flow classification:
=======================================================

Here, we set the priority field to a classid with the major number
the same as the fq_codel major number (handle), and the minor number
to the subscriber ID. This way, we get a single Codel queue
per-subscriber.

As expected, we see fairness between Subscriber 1 and Subscriber 2,
and Subscriber 2's unresponsive UDP flow dominates their TCP flow,
because they're both in Subscriber 2's queue.

+ ip netns exec mid ipset create subscribers hash:ip skbinfo
+ ip netns exec mid ipset add subscribers 10.7.1.2 skbprio 2:1
+ ip netns exec mid ipset add subscribers 10.7.1.3 skbprio 2:2
+ ip netns exec mid ipset add subscribers 10.7.1.4 skbprio 2:2
+ ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING -j SET --map-set subscribers dst --map-prio
+ ip netns exec mid tc qdisc add dev mid.r root handle 1: htb default fff3
+ ip netns exec mid tc class add dev mid.r parent 1: classid 1:fff3 htb rate 50Mbit
+ ip netns exec mid tc qdisc add dev mid.r handle 2: parent 1:fff3 fq_codel
+ set +x

Subscriber 1, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.2, port 5202
[  6] local 10.7.0.2 port 49222 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  3.30 MBytes  27.7 Mbits/sec   21   17.0 KBytes       
[  6]   1.00-2.00   sec  2.80 MBytes  23.5 Mbits/sec   19   17.0 KBytes       
[  6]   2.00-3.00   sec  2.80 MBytes  23.5 Mbits/sec   20   17.0 KBytes       
[  6]   3.00-4.00   sec  2.80 MBytes  23.5 Mbits/sec   20   17.0 KBytes       
[  6]   4.00-5.00   sec  2.98 MBytes  25.0 Mbits/sec   19   17.0 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  14.7 MBytes  24.6 Mbits/sec   99             sender
[  6]   0.00-5.01   sec  14.3 MBytes  23.9 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 46362 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  2.47 MBytes  20.7 Mbits/sec   14    243 KBytes       
[  6]   1.00-2.00   sec   954 KBytes  7.82 Mbits/sec   11    170 KBytes       
[  6]   2.00-3.00   sec   827 KBytes  6.78 Mbits/sec   32   96.2 KBytes       
[  6]   3.00-4.00   sec  0.00 Bytes  0.00 bits/sec   16   26.9 KBytes       
[  6]   4.00-5.00   sec   700 KBytes  5.73 Mbits/sec   26   4.24 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  4.90 MBytes  8.21 Mbits/sec   99             sender
[  6]   0.00-5.00   sec  3.26 MBytes  5.47 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 56524 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.01   sec  11.2 MBytes  18.8 Mbits/sec  0.493 ms  527/8632 (6.1%)  receiver

iperf Done.

fq_pie: use priority field to override flow classification:
===========================================================

Here, we set the priority field to a classid with the major number
the same as the fq_pie major number (handle), and the minor number
to the subscriber ID. This way, we get a single queue per-subscriber.

As expected, we see fairness between Subscriber 1 and Subscriber 2,
and Subscriber 2's unresponsive UDP flow dominates their TCP flow,
because they're both in Subscriber 2's queue.

+ ip netns exec mid ipset create subscribers hash:ip skbinfo
+ ip netns exec mid ipset add subscribers 10.7.1.2 skbprio 2:1
+ ip netns exec mid ipset add subscribers 10.7.1.3 skbprio 2:2
+ ip netns exec mid ipset add subscribers 10.7.1.4 skbprio 2:2
+ ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING -j SET --map-set subscribers dst --map-prio
+ ip netns exec mid tc qdisc add dev mid.r root handle 1: htb default fff3
+ ip netns exec mid tc class add dev mid.r parent 1: classid 1:fff3 htb rate 50Mbit
+ ip netns exec mid tc qdisc add dev mid.r handle 2: parent 1:fff3 fq_pie
+ set +x

Subscriber 1, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.2, port 5202
[  6] local 10.7.0.2 port 49240 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  5.67 MBytes  47.6 Mbits/sec    6    494 KBytes       
[  6]   1.00-2.00   sec  2.49 MBytes  20.9 Mbits/sec  498   5.66 KBytes       
[  6]   2.00-3.00   sec  3.54 MBytes  29.7 Mbits/sec  196   5.66 KBytes       
[  6]   3.00-4.00   sec  2.36 MBytes  19.8 Mbits/sec  106   25.5 KBytes       
[  6]   4.00-5.00   sec  3.54 MBytes  29.7 Mbits/sec   29   25.5 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  17.6 MBytes  29.5 Mbits/sec  835             sender
[  6]   0.00-5.01   sec  14.3 MBytes  23.9 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 46380 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  1.23 MBytes  10.3 Mbits/sec    7   62.2 KBytes       
[  6]   1.00-2.00   sec   636 KBytes  5.21 Mbits/sec   59   4.24 KBytes       
[  6]   2.00-3.00   sec   573 KBytes  4.69 Mbits/sec   33   4.24 KBytes       
[  6]   3.00-4.00   sec   764 KBytes  6.26 Mbits/sec   30   5.66 KBytes       
[  6]   4.00-5.00   sec   573 KBytes  4.69 Mbits/sec   30   11.3 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  3.72 MBytes  6.23 Mbits/sec  159             sender
[  6]   0.00-5.01   sec  3.34 MBytes  5.59 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 52892 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.02   sec  11.1 MBytes  18.6 Mbits/sec  0.426 ms  569/8632 (6.6%)  receiver

iperf Done.

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
+ ip netns exec mid tc qdisc add dev mid.r handle 1: root cake bandwidth 50Mbit
+ ip netns exec mid tc filter add dev mid.r parent 1: handle 0x9 flow map key priority
+ set +x

Subscriber 1, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.2, port 5202
[  6] local 10.7.0.2 port 49254 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  2.95 MBytes  24.8 Mbits/sec   12   19.8 KBytes       
[  6]   1.00-2.00   sec  2.89 MBytes  24.2 Mbits/sec   13   12.7 KBytes       
[  6]   2.00-3.00   sec  2.87 MBytes  24.0 Mbits/sec   12   18.4 KBytes       
[  6]   3.00-4.00   sec  2.80 MBytes  23.5 Mbits/sec   13   14.1 KBytes       
[  6]   4.00-5.00   sec  2.86 MBytes  24.0 Mbits/sec   13   15.6 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  14.4 MBytes  24.1 Mbits/sec   63             sender
[  6]   0.00-5.01   sec  14.3 MBytes  23.9 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 46392 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec   716 KBytes  5.86 Mbits/sec    8   5.66 KBytes       
[  6]   1.00-2.00   sec   636 KBytes  5.21 Mbits/sec   15   4.24 KBytes       
[  6]   2.00-3.00   sec   636 KBytes  5.21 Mbits/sec   22   4.24 KBytes       
[  6]   3.00-4.00   sec   573 KBytes  4.69 Mbits/sec   29   4.24 KBytes       
[  6]   4.00-5.00   sec   573 KBytes  4.69 Mbits/sec   33   2.83 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  3.06 MBytes  5.13 Mbits/sec  107             sender
[  6]   0.00-5.00   sec  2.91 MBytes  4.88 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 51983 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8631 (0%)  sender
[  6]   0.00-5.01   sec  11.5 MBytes  19.3 Mbits/sec  0.439 ms  273/8631 (3.2%)  receiver

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
+ ip netns exec mid tc qdisc add dev mid.r handle 1: root cake bandwidth 50Mbit
+ ip netns exec mid tc filter add dev mid.r parent 1: handle 0x9 flow map key mark
+ set +x

Subscriber 1, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.2, port 5202
[  6] local 10.7.0.2 port 49268 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  3.02 MBytes  25.4 Mbits/sec   12   21.2 KBytes       
[  6]   1.00-2.00   sec  2.80 MBytes  23.5 Mbits/sec   13   15.6 KBytes       
[  6]   2.00-3.00   sec  2.86 MBytes  24.0 Mbits/sec   13   14.1 KBytes       
[  6]   3.00-4.00   sec  2.86 MBytes  24.0 Mbits/sec   12   18.4 KBytes       
[  6]   4.00-5.00   sec  2.86 MBytes  24.0 Mbits/sec   13   19.8 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  14.4 MBytes  24.1 Mbits/sec   63             sender
[  6]   0.00-5.00   sec  14.3 MBytes  23.9 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 46398 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec   902 KBytes  7.39 Mbits/sec    3   24.0 KBytes       
[  6]   1.00-2.00   sec   509 KBytes  4.17 Mbits/sec   15   4.24 KBytes       
[  6]   2.00-3.00   sec   636 KBytes  5.21 Mbits/sec   22   7.07 KBytes       
[  6]   3.00-4.00   sec   636 KBytes  5.21 Mbits/sec   32   2.83 KBytes       
[  6]   4.00-5.00   sec   509 KBytes  4.17 Mbits/sec   29   4.24 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  3.12 MBytes  5.23 Mbits/sec  101             sender
[  6]   0.00-5.00   sec  2.90 MBytes  4.87 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 45535 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8631 (0%)  sender
[  6]   0.00-5.01   sec  11.6 MBytes  19.4 Mbits/sec  0.476 ms  255/8631 (3%)  receiver

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
+ ip netns exec mid tc qdisc add dev mid.r handle 1: root cake bandwidth 50Mbit
+ ip netns exec mid tc filter add dev mid.r parent 1: handle 0x9 flow map key mark
+ set +x

Subscriber 1, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.2, port 5202
[  6] local 10.7.0.2 port 49274 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  1.82 MBytes  15.3 Mbits/sec   10   12.7 KBytes       
[  6]   1.00-2.00   sec  1.74 MBytes  14.6 Mbits/sec   14   11.3 KBytes       
[  6]   2.00-3.00   sec  1.74 MBytes  14.6 Mbits/sec   16   11.3 KBytes       
[  6]   3.00-4.00   sec  1.74 MBytes  14.6 Mbits/sec   17   12.7 KBytes       
[  6]   4.00-5.00   sec  2.24 MBytes  18.8 Mbits/sec   22   12.7 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  9.28 MBytes  15.6 Mbits/sec   79             sender
[  6]   0.00-5.00   sec  9.08 MBytes  15.2 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 46412 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  1.94 MBytes  16.3 Mbits/sec    9   14.1 KBytes       
[  6]   1.00-2.00   sec  1.74 MBytes  14.6 Mbits/sec   16   8.48 KBytes       
[  6]   2.00-3.00   sec  1.62 MBytes  13.6 Mbits/sec   18   8.48 KBytes       
[  6]   3.00-4.00   sec  1.62 MBytes  13.6 Mbits/sec   19   11.3 KBytes       
[  6]   4.00-5.00   sec  1.24 MBytes  10.4 Mbits/sec   20   7.07 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  8.16 MBytes  13.7 Mbits/sec   82             sender
[  6]   0.00-5.00   sec  7.92 MBytes  13.3 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 45338 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.01   sec  11.7 MBytes  19.7 Mbits/sec  0.262 ms  126/8632 (1.5%)  receiver

iperf Done.

Map priority field to classid with eBPF, hosts only:
====================================================

Here, we use an eBPF classifier to map the priority field to the classid,
using the major ID only.

Because eBPF can map the major classid, we see both fairness between
Subscriber 1 and Subscriber 2, and also between Subscriber 2's
TCP and unresponsive UDP flows, because Cake hashes the flows when
we haven't specified the minor classid.

+ ip netns exec mid ipset create subscribers hash:ip skbinfo
+ ip netns exec mid ipset add subscribers 10.7.1.2 skbprio 2:0
+ ip netns exec mid ipset add subscribers 10.7.1.3 skbprio 3:0
+ ip netns exec mid ipset add subscribers 10.7.1.4 skbprio 3:0
+ ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING -j SET --map-set subscribers dst --map-prio
+ ip netns exec mid tc qdisc add dev mid.r handle 1: root cake bandwidth 50Mbit
+ ip netns exec mid tc filter add dev mid.r parent 1: bpf obj priority_to_classid.o
Continuing without mounted eBPF fs. Too old kernel?
+ set +x

Subscriber 1, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.2, port 5202
[  6] local 10.7.0.2 port 49282 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  2.99 MBytes  25.1 Mbits/sec   12   19.8 KBytes       
[  6]   1.00-2.00   sec  2.86 MBytes  24.0 Mbits/sec   13   14.1 KBytes       
[  6]   2.00-3.00   sec  2.86 MBytes  24.0 Mbits/sec   13   14.1 KBytes       
[  6]   3.00-4.00   sec  2.80 MBytes  23.5 Mbits/sec   12   18.4 KBytes       
[  6]   4.00-5.00   sec  2.86 MBytes  24.0 Mbits/sec   13   15.6 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  14.4 MBytes  24.1 Mbits/sec   63             sender
[  6]   0.00-5.00   sec  14.2 MBytes  23.9 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 46422 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  1.53 MBytes  12.9 Mbits/sec   16   8.48 KBytes       
[  6]   1.00-2.00   sec  1.43 MBytes  12.0 Mbits/sec   15   9.90 KBytes       
[  6]   2.00-3.00   sec  1.43 MBytes  12.0 Mbits/sec   15   11.3 KBytes       
[  6]   3.00-4.00   sec  1.43 MBytes  12.0 Mbits/sec   16   11.3 KBytes       
[  6]   4.00-5.00   sec  1.43 MBytes  12.0 Mbits/sec   18   8.48 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  7.25 MBytes  12.2 Mbits/sec   80             sender
[  6]   0.00-5.00   sec  7.13 MBytes  12.0 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 43276 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.00   sec  7.26 MBytes  12.2 Mbits/sec  0.501 ms  1621/6875 (24%)  receiver

iperf Done.

Map priority field to classid with eBPF, hosts and flows:
=========================================================

Here, we use an eBPF classifier to map the priority field to the classid,
using both the major and minor parts of the class ID.

Because eBPF can map both the major and minor classid, we see
fairness between Subscriber 1 and Subscriber 2, and we see Subscriber 2's
unresponsive UDP flow dominate their TCP flow, since we have mapped
them to the same Cake flow.

+ ip netns exec mid ipset create subscribers hash:ip skbinfo
+ ip netns exec mid ipset add subscribers 10.7.1.2 skbprio 2:1
+ ip netns exec mid ipset add subscribers 10.7.1.3 skbprio 3:2
+ ip netns exec mid ipset add subscribers 10.7.1.4 skbprio 3:2
+ ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING -j SET --map-set subscribers dst --map-prio
+ ip netns exec mid tc qdisc add dev mid.r handle 1: root cake bandwidth 50Mbit
+ ip netns exec mid tc filter add dev mid.r parent 1: bpf obj priority_to_classid.o
Continuing without mounted eBPF fs. Too old kernel?
+ set +x

Subscriber 1, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.2, port 5202
[  6] local 10.7.0.2 port 49292 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  3.02 MBytes  25.4 Mbits/sec   13   15.6 KBytes       
[  6]   1.00-2.00   sec  2.80 MBytes  23.5 Mbits/sec   12   15.6 KBytes       
[  6]   2.00-3.00   sec  2.86 MBytes  24.0 Mbits/sec   13   14.1 KBytes       
[  6]   3.00-4.00   sec  2.86 MBytes  24.0 Mbits/sec   13   14.1 KBytes       
[  6]   4.00-5.00   sec  2.86 MBytes  24.0 Mbits/sec   12   19.8 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  14.4 MBytes  24.1 Mbits/sec   63             sender
[  6]   0.00-5.01   sec  14.3 MBytes  23.9 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 46432 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec   868 KBytes  7.11 Mbits/sec    5   15.6 KBytes       
[  6]   1.00-2.00   sec   509 KBytes  4.17 Mbits/sec   13   5.66 KBytes       
[  6]   2.00-3.00   sec   636 KBytes  5.21 Mbits/sec   23   4.24 KBytes       
[  6]   3.00-4.00   sec   636 KBytes  5.21 Mbits/sec   24   2.83 KBytes       
[  6]   4.00-5.00   sec   509 KBytes  4.17 Mbits/sec   30   4.24 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  3.08 MBytes  5.18 Mbits/sec   95             sender
[  6]   0.00-5.00   sec  2.91 MBytes  4.88 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 50221 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.01   sec  11.5 MBytes  19.4 Mbits/sec  0.472 ms  269/8632 (3.1%)  receiver

iperf Done.

Map firewall mark with flow to classid with eBPF, hosts only:
=============================================================

Here, we use an eBPF classifier to map the firewall mark to the classid,
using the major ID only.

Because eBPF can map the major classid, we see both fairness between
Subscriber 1 and Subscriber 2, and also between Subscriber 2's
TCP and unresponsive UDP flows, because Cake hashes the flows when
we haven't specified the minor classid.

+ ip netns exec mid ipset create subscribers hash:ip skbinfo
+ ip netns exec mid ipset add subscribers 10.7.1.2 skbmark 0x10000
+ ip netns exec mid ipset add subscribers 10.7.1.3 skbmark 0x20000
+ ip netns exec mid ipset add subscribers 10.7.1.4 skbmark 0x20000
+ ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING -j SET --map-set subscribers dst --map-mark
+ ip netns exec mid tc qdisc add dev mid.r handle 1: root cake bandwidth 50Mbit
+ ip netns exec mid tc filter add dev mid.r parent 1: bpf obj mark_to_classid.o
Continuing without mounted eBPF fs. Too old kernel?
+ set +x

Subscriber 1, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.2, port 5202
[  6] local 10.7.0.2 port 49304 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  2.99 MBytes  25.1 Mbits/sec   13   15.6 KBytes       
[  6]   1.00-2.00   sec  2.86 MBytes  24.0 Mbits/sec   12   18.4 KBytes       
[  6]   2.00-3.00   sec  2.86 MBytes  24.0 Mbits/sec   13   18.4 KBytes       
[  6]   3.00-4.00   sec  2.92 MBytes  24.5 Mbits/sec   13   18.4 KBytes       
[  6]   4.00-5.00   sec  2.80 MBytes  23.5 Mbits/sec   13   14.1 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  14.4 MBytes  24.2 Mbits/sec   64             sender
[  6]   0.00-5.00   sec  14.3 MBytes  23.9 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 46440 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  1.56 MBytes  13.1 Mbits/sec   15   12.7 KBytes       
[  6]   1.00-2.00   sec  1.43 MBytes  12.0 Mbits/sec   16   8.48 KBytes       
[  6]   2.00-3.00   sec  1.43 MBytes  12.0 Mbits/sec   17   11.3 KBytes       
[  6]   3.00-4.00   sec  1.37 MBytes  11.5 Mbits/sec   18   8.48 KBytes       
[  6]   4.00-5.00   sec  1.43 MBytes  12.0 Mbits/sec   16   11.3 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  7.22 MBytes  12.1 Mbits/sec   82             sender
[  6]   0.00-5.00   sec  7.13 MBytes  12.0 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 47960 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.00   sec  7.25 MBytes  12.2 Mbits/sec  0.272 ms  1606/6859 (23%)  receiver

iperf Done.

Map firewall mark with flow to classid with eBPF, hosts and flows:
==================================================================

Here, we use an eBPF classifier to map the firewall mark to the classid,
using both the major and minor parts of the class ID.

Because eBPF can map both the major and minor classid, we see
fairness between Subscriber 1 and Subscriber 2, and we see Subscriber 2's
unresponsive UDP flow dominate their TCP flow, since we have mapped
them to the same Cake flow.

+ ip netns exec mid ipset create subscribers hash:ip skbinfo
+ ip netns exec mid ipset add subscribers 10.7.1.2 skbmark 0x10001
+ ip netns exec mid ipset add subscribers 10.7.1.3 skbmark 0x20002
+ ip netns exec mid ipset add subscribers 10.7.1.4 skbmark 0x20002
+ ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING -j SET --map-set subscribers dst --map-mark
+ ip netns exec mid tc qdisc add dev mid.r handle 1: root cake bandwidth 50Mbit
+ ip netns exec mid tc filter add dev mid.r parent 1: bpf obj mark_to_classid.o
Continuing without mounted eBPF fs. Too old kernel?
+ set +x

Subscriber 1, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.2, port 5202
[  6] local 10.7.0.2 port 49316 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  3.02 MBytes  25.4 Mbits/sec   12   19.8 KBytes       
[  6]   1.00-2.00   sec  2.80 MBytes  23.5 Mbits/sec   13   18.4 KBytes       
[  6]   2.00-3.00   sec  2.86 MBytes  24.0 Mbits/sec   13   18.4 KBytes       
[  6]   3.00-4.00   sec  2.92 MBytes  24.5 Mbits/sec   13   14.1 KBytes       
[  6]   4.00-5.00   sec  2.80 MBytes  23.5 Mbits/sec   12   18.4 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  14.4 MBytes  24.1 Mbits/sec   63             sender
[  6]   0.00-5.01   sec  14.3 MBytes  23.9 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 46448 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec   788 KBytes  6.45 Mbits/sec    4   14.1 KBytes       
[  6]   1.00-2.00   sec   573 KBytes  4.69 Mbits/sec   11   8.48 KBytes       
[  6]   2.00-3.00   sec   573 KBytes  4.69 Mbits/sec   26   5.66 KBytes       
[  6]   3.00-4.00   sec   636 KBytes  5.21 Mbits/sec   26   4.24 KBytes       
[  6]   4.00-5.00   sec   636 KBytes  5.21 Mbits/sec   25   4.24 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  3.13 MBytes  5.25 Mbits/sec   92             sender
[  6]   0.00-5.00   sec  2.97 MBytes  4.99 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 34123 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.01   sec  11.5 MBytes  19.2 Mbits/sec  0.471 ms  315/8632 (3.6%)  receiver

iperf Done.
```
