```
fq_codel: use tc-flow with destination address for flow classification:
=======================================================================

Here, we use tc-flow with "hash keys dst" to hash packets by destination
address. This sets the minor classid, giving a single queue for each
destination address.

As expected, we see fairness between destination Host 1 and Host 2, and
Host 2's unresponsive UDP flow dominates their TCP flow, because they're
both in Host 2's queue.

+ ip netns exec mid tc qdisc add dev mid.r root handle 1: htb default 10
+ ip netns exec mid tc class add dev mid.r parent 1: classid 1:10 htb rate 50Mbit
+ ip netns exec mid tc qdisc add dev mid.r handle 20: parent 1:10 fq_codel
+ ip netns exec mid tc filter add dev mid.r protocol all parent 20: handle 1 flow hash keys dst divisor 1024
+ set +x

Host 1, TCP client (cubic):
---------------------------
Connecting to host 10.7.1.2, port 5202
[  6] local 10.7.0.2 port 42948 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  3.92 MBytes  32.9 Mbits/sec   20   21.2 KBytes       
[  6]   1.00-2.00   sec  2.61 MBytes  21.9 Mbits/sec   18   24.0 KBytes       
[  6]   2.00-3.00   sec  3.11 MBytes  26.1 Mbits/sec   22   15.6 KBytes       
[  6]   3.00-4.00   sec  2.73 MBytes  22.9 Mbits/sec   19   19.8 KBytes       
[  6]   4.00-5.00   sec  2.98 MBytes  25.0 Mbits/sec   21   18.4 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  15.4 MBytes  25.8 Mbits/sec  100             sender
[  6]   0.00-5.01   sec  14.5 MBytes  24.2 Mbits/sec                  receiver

iperf Done.

Host 2, TCP client (cubic):
---------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 42170 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  1.11 MBytes  9.28 Mbits/sec    8   11.3 KBytes       
[  6]   1.00-2.00   sec   382 KBytes  3.13 Mbits/sec   11   14.1 KBytes       
[  6]   2.00-3.00   sec   764 KBytes  6.26 Mbits/sec   27   7.07 KBytes       
[  6]   3.00-4.00   sec   382 KBytes  3.13 Mbits/sec   21   12.7 KBytes       
[  6]   4.00-5.00   sec   573 KBytes  4.69 Mbits/sec    9   21.2 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  3.16 MBytes  5.30 Mbits/sec   76             sender
[  6]   0.00-5.02   sec  2.83 MBytes  4.73 Mbits/sec                  receiver

iperf Done.

Host 2, UDP client, 20Mbps unresponsive:
----------------------------------------
Connecting to host 10.7.1.3, port 5213
[  6] local 10.7.0.2 port 54215 connected to 10.7.1.3 port 5213
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.03   sec  11.5 MBytes  19.2 Mbits/sec  0.455 ms  273/8632 (3.2%)  receiver

iperf Done.

sfq: use tc-flow with destination address for flow classification:
=======================================================================

Here, we use tc-flow with "hash keys dst" to hash packets by destination
address. This sets the minor classid, giving a single queue for each
destination address.

As expected, we see fairness between destination Host 1 and Host 2, and
Host 2's unresponsive UDP flow dominates their TCP flow, because they're
both in Host 2's queue.

+ ip netns exec mid tc qdisc add dev mid.r root handle 1: htb default 10
+ ip netns exec mid tc class add dev mid.r parent 1: classid 1:10 htb rate 50Mbit
+ ip netns exec mid tc qdisc add dev mid.r handle 20: parent 1:10 sfq
+ ip netns exec mid tc filter add dev mid.r protocol all parent 20: handle 1 flow hash keys dst divisor 1024
+ set +x

Host 1, TCP client (cubic):
---------------------------
Connecting to host 10.7.1.2, port 5202
[  6] local 10.7.0.2 port 42958 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  3.81 MBytes  31.9 Mbits/sec    7    100 KBytes       
[  6]   1.00-2.00   sec  2.61 MBytes  21.9 Mbits/sec    3    109 KBytes       
[  6]   2.00-3.00   sec  2.98 MBytes  25.0 Mbits/sec    0    129 KBytes       
[  6]   3.00-4.00   sec  2.98 MBytes  25.0 Mbits/sec    0    144 KBytes       
[  6]   4.00-5.00   sec  2.61 MBytes  21.9 Mbits/sec    0    158 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  15.0 MBytes  25.2 Mbits/sec   10             sender
[  6]   0.00-5.04   sec  14.4 MBytes  24.0 Mbits/sec                  receiver

iperf Done.

Host 2, TCP client (cubic):
---------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 42180 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  2.60 MBytes  21.8 Mbits/sec  428   56.6 KBytes       
[  6]   1.00-2.00   sec  1.24 MBytes  10.4 Mbits/sec    3   32.5 KBytes       
[  6]   2.00-3.00   sec   636 KBytes  5.21 Mbits/sec    6   35.4 KBytes       
[  6]   3.00-4.00   sec   636 KBytes  5.21 Mbits/sec    5   19.8 KBytes       
[  6]   4.00-5.00   sec   700 KBytes  5.74 Mbits/sec    4   14.1 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  5.77 MBytes  9.67 Mbits/sec  446             sender
[  6]   0.00-5.02   sec  3.95 MBytes  6.60 Mbits/sec                  receiver

iperf Done.

Host 2, UDP client, 20Mbps unresponsive:
----------------------------------------
Connecting to host 10.7.1.3, port 5213
[  6] local 10.7.0.2 port 34252 connected to 10.7.1.3 port 5213
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.03   sec  10.5 MBytes  17.6 Mbits/sec  0.479 ms  1006/8632 (12%)  receiver

iperf Done.

cake: use tc-flow with destination address for flow classification:
=======================================================================

Here, we use tc-flow with "hash keys dst" to hash packets by destination
address. This sets the minor classid, giving a single queue for each
destination address.

As expected, we see fairness between destination Host 1 and Host 2, and
Host 2's unresponsive UDP flow dominates their TCP flow, because they're
both in Host 2's queue.

+ ip netns exec mid tc qdisc add dev mid.r root handle 1: htb default 10
+ ip netns exec mid tc class add dev mid.r parent 1: classid 1:10 htb rate 50Mbit
+ ip netns exec mid tc qdisc add dev mid.r handle 20: parent 1:10 cake
+ ip netns exec mid tc filter add dev mid.r protocol all parent 20: handle 1 flow hash keys dst divisor 1024
+ set +x

Host 1, TCP client (cubic):
---------------------------
Connecting to host 10.7.1.2, port 5202
[  6] local 10.7.0.2 port 42970 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  3.08 MBytes  25.9 Mbits/sec   12   18.4 KBytes       
[  6]   1.00-2.00   sec  2.73 MBytes  22.9 Mbits/sec   13   14.1 KBytes       
[  6]   2.00-3.00   sec  2.86 MBytes  24.0 Mbits/sec   12   18.4 KBytes       
[  6]   3.00-4.00   sec  2.86 MBytes  24.0 Mbits/sec   13   18.4 KBytes       
[  6]   4.00-5.00   sec  2.86 MBytes  24.0 Mbits/sec   14   12.7 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  14.4 MBytes  24.1 Mbits/sec   64             sender
[  6]   0.00-5.00   sec  14.3 MBytes  23.9 Mbits/sec                  receiver

iperf Done.

Host 2, TCP client (cubic):
---------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 42190 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec   718 KBytes  5.88 Mbits/sec    7   8.48 KBytes       
[  6]   1.00-2.00   sec   636 KBytes  5.21 Mbits/sec   12   7.07 KBytes       
[  6]   2.00-3.00   sec   636 KBytes  5.21 Mbits/sec   20   5.66 KBytes       
[  6]   3.00-4.00   sec   636 KBytes  5.21 Mbits/sec   21   8.48 KBytes       
[  6]   4.00-5.00   sec   764 KBytes  6.26 Mbits/sec   27   8.48 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  3.31 MBytes  5.56 Mbits/sec   87             sender
[  6]   0.00-5.00   sec  3.13 MBytes  5.24 Mbits/sec                  receiver

iperf Done.

Host 2, UDP client, 20Mbps unresponsive:
----------------------------------------
Connecting to host 10.7.1.3, port 5213
[  6] local 10.7.0.2 port 45203 connected to 10.7.1.3 port 5213
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.01   sec  11.3 MBytes  19.0 Mbits/sec  0.471 ms  418/8632 (4.8%)  receiver

iperf Done.

fq_codel: use priority field to override flow classification:
=============================================================

Here, we set the priority field to a classid with the major number
the same as the fq_codel major number (handle), and the minor number
to the subscriber ID. This way, we get a single queue per-subscriber.

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
[  6] local 10.7.0.2 port 42982 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  4.71 MBytes  39.5 Mbits/sec   41   17.0 KBytes       
[  6]   1.00-2.00   sec  2.73 MBytes  22.9 Mbits/sec   18   25.5 KBytes       
[  6]   2.00-3.00   sec  2.73 MBytes  22.9 Mbits/sec   18   25.5 KBytes       
[  6]   3.00-4.00   sec  2.73 MBytes  22.9 Mbits/sec   19   21.2 KBytes       
[  6]   4.00-5.00   sec  2.73 MBytes  22.9 Mbits/sec   20   19.8 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  15.6 MBytes  26.3 Mbits/sec  116             sender
[  6]   0.00-5.01   sec  14.3 MBytes  23.9 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 42196 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  1.93 MBytes  16.2 Mbits/sec    6    124 KBytes       
[  6]   1.00-2.00   sec   445 KBytes  3.65 Mbits/sec    6   73.5 KBytes       
[  6]   2.00-3.00   sec   445 KBytes  3.65 Mbits/sec   14   2.83 KBytes       
[  6]   3.00-4.00   sec   445 KBytes  3.65 Mbits/sec   19   8.48 KBytes       
[  6]   4.00-5.00   sec   891 KBytes  7.30 Mbits/sec   23   5.66 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  4.10 MBytes  6.88 Mbits/sec   68             sender
[  6]   0.00-5.00   sec  3.05 MBytes  5.11 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 57697 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.01   sec  11.4 MBytes  19.1 Mbits/sec  0.559 ms  365/8632 (4.2%)  receiver

iperf Done.

sfq: use priority field to override flow classification:
=============================================================

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
[  6] local 10.7.0.2 port 42988 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  3.87 MBytes  32.4 Mbits/sec    8    120 KBytes       
[  6]   1.00-2.00   sec  2.61 MBytes  21.9 Mbits/sec    0    110 KBytes       
[  6]   2.00-3.00   sec  2.98 MBytes  25.0 Mbits/sec    0    129 KBytes       
[  6]   3.00-4.00   sec  2.98 MBytes  25.0 Mbits/sec    0    146 KBytes       
[  6]   4.00-5.00   sec  2.61 MBytes  21.9 Mbits/sec    0    160 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  15.1 MBytes  25.3 Mbits/sec    8             sender
[  6]   0.00-5.05   sec  14.4 MBytes  24.0 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 42212 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  3.09 MBytes  26.0 Mbits/sec  437   65.0 KBytes       
[  6]   1.00-2.00   sec   636 KBytes  5.21 Mbits/sec   29   26.9 KBytes       
[  6]   2.00-3.00   sec   636 KBytes  5.21 Mbits/sec    1   31.1 KBytes       
[  6]   3.00-4.00   sec   636 KBytes  5.21 Mbits/sec    3   26.9 KBytes       
[  6]   4.00-5.00   sec   636 KBytes  5.21 Mbits/sec    7   25.5 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  5.58 MBytes  9.36 Mbits/sec  477             sender
[  6]   0.00-5.03   sec  3.84 MBytes  6.40 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 57854 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.04   sec  10.7 MBytes  17.8 Mbits/sec  0.488 ms  902/8632 (10%)  receiver

iperf Done.

fq_pie: use priority field to override flow classification:
=============================================================

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
[  6] local 10.7.0.2 port 43004 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  3.58 MBytes  30.1 Mbits/sec    2    163 KBytes       
[  6]   1.00-2.00   sec  2.98 MBytes  25.0 Mbits/sec   13   33.9 KBytes       
[  6]   2.00-3.00   sec  2.98 MBytes  25.0 Mbits/sec    6   46.7 KBytes       
[  6]   3.00-4.00   sec  2.98 MBytes  25.0 Mbits/sec    8   31.1 KBytes       
[  6]   4.00-5.00   sec  2.98 MBytes  25.0 Mbits/sec    2   63.6 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  15.5 MBytes  26.0 Mbits/sec   31             sender
[  6]   0.00-5.01   sec  14.6 MBytes  24.4 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 42218 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  1.26 MBytes  10.5 Mbits/sec    2   83.4 KBytes       
[  6]   1.00-2.00   sec   764 KBytes  6.26 Mbits/sec   66   2.83 KBytes       
[  6]   2.00-3.00   sec   255 KBytes  2.08 Mbits/sec   27   7.07 KBytes       
[  6]   3.00-4.00   sec   509 KBytes  4.17 Mbits/sec   28   9.90 KBytes       
[  6]   4.00-5.00   sec   764 KBytes  6.26 Mbits/sec   29   4.24 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  3.50 MBytes  5.86 Mbits/sec  152             sender
[  6]   0.00-5.00   sec  3.00 MBytes  5.03 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 45710 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.01   sec  11.1 MBytes  18.7 Mbits/sec  0.479 ms  563/8632 (6.5%)  receiver

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
[  6] local 10.7.0.2 port 43014 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  3.02 MBytes  25.4 Mbits/sec   12   19.8 KBytes       
[  6]   1.00-2.00   sec  2.86 MBytes  24.0 Mbits/sec   13   14.1 KBytes       
[  6]   2.00-3.00   sec  2.86 MBytes  24.0 Mbits/sec   13   14.1 KBytes       
[  6]   3.00-4.00   sec  2.80 MBytes  23.5 Mbits/sec   13   14.1 KBytes       
[  6]   4.00-5.00   sec  2.86 MBytes  24.0 Mbits/sec   13   14.1 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  14.4 MBytes  24.1 Mbits/sec   64             sender
[  6]   0.00-5.00   sec  14.3 MBytes  24.0 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 42230 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec   724 KBytes  5.93 Mbits/sec   11   2.83 KBytes       
[  6]   1.00-2.00   sec   573 KBytes  4.69 Mbits/sec   16   2.83 KBytes       
[  6]   2.00-3.00   sec   700 KBytes  5.74 Mbits/sec   20   5.66 KBytes       
[  6]   3.00-4.00   sec   573 KBytes  4.69 Mbits/sec   25   5.66 KBytes       
[  6]   4.00-5.00   sec   636 KBytes  5.21 Mbits/sec   28   2.83 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  3.13 MBytes  5.25 Mbits/sec  100             sender
[  6]   0.00-5.00   sec  2.97 MBytes  4.99 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 45396 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.01   sec  11.5 MBytes  19.2 Mbits/sec  0.472 ms  330/8632 (3.8%)  receiver

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
[  6] local 10.7.0.2 port 43020 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  2.96 MBytes  24.8 Mbits/sec   12   18.4 KBytes       
[  6]   1.00-2.00   sec  2.92 MBytes  24.5 Mbits/sec   13   18.4 KBytes       
[  6]   2.00-3.00   sec  2.80 MBytes  23.5 Mbits/sec   13   14.1 KBytes       
[  6]   3.00-4.00   sec  2.86 MBytes  24.0 Mbits/sec   13   12.7 KBytes       
[  6]   4.00-5.00   sec  2.92 MBytes  24.5 Mbits/sec   12   18.4 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  14.5 MBytes  24.3 Mbits/sec   63             sender
[  6]   0.00-5.01   sec  14.3 MBytes  23.9 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 42240 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec   805 KBytes  6.59 Mbits/sec    4   14.1 KBytes       
[  6]   1.00-2.00   sec   509 KBytes  4.17 Mbits/sec   14   7.07 KBytes       
[  6]   2.00-3.00   sec   636 KBytes  5.21 Mbits/sec   22   7.07 KBytes       
[  6]   3.00-4.00   sec   636 KBytes  5.21 Mbits/sec   24   2.83 KBytes       
[  6]   4.00-5.00   sec   636 KBytes  5.21 Mbits/sec   30   4.24 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  3.15 MBytes  5.28 Mbits/sec   94             sender
[  6]   0.00-5.00   sec  2.91 MBytes  4.89 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 49767 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.00   sec  11.6 MBytes  19.4 Mbits/sec  0.478 ms  265/8632 (3.1%)  receiver

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
[  6] local 10.7.0.2 port 43026 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  1.33 MBytes  11.2 Mbits/sec   11   4.24 KBytes       
[  6]   1.00-2.00   sec  1.69 MBytes  14.2 Mbits/sec   15   11.3 KBytes       
[  6]   2.00-3.00   sec  1.62 MBytes  13.6 Mbits/sec   17   8.48 KBytes       
[  6]   3.00-4.00   sec  1.80 MBytes  15.1 Mbits/sec   19   11.3 KBytes       
[  6]   4.00-5.00   sec  1.81 MBytes  15.2 Mbits/sec   19   11.3 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  8.25 MBytes  13.8 Mbits/sec   81             sender
[  6]   0.00-5.00   sec  8.16 MBytes  13.7 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 42250 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  2.43 MBytes  20.4 Mbits/sec    7   18.4 KBytes       
[  6]   1.00-2.00   sec  1.74 MBytes  14.6 Mbits/sec   19   9.90 KBytes       
[  6]   2.00-3.00   sec  1.74 MBytes  14.6 Mbits/sec   16   9.90 KBytes       
[  6]   3.00-4.00   sec  1.49 MBytes  12.5 Mbits/sec   16   15.6 KBytes       
[  6]   4.00-5.00   sec  1.62 MBytes  13.6 Mbits/sec   17   18.4 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  9.02 MBytes  15.1 Mbits/sec   75             sender
[  6]   0.00-5.01   sec  8.81 MBytes  14.8 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 57284 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8631 (0%)  sender
[  6]   0.00-5.00   sec  11.8 MBytes  19.7 Mbits/sec  0.259 ms  103/8631 (1.2%)  receiver

iperf Done.

cake: map priority field to classid with eBPF, hosts:
=====================================================

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
[  6] local 10.7.0.2 port 43042 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  3.05 MBytes  25.6 Mbits/sec   13   15.6 KBytes       
[  6]   1.00-2.00   sec  2.80 MBytes  23.5 Mbits/sec   13   15.6 KBytes       
[  6]   2.00-3.00   sec  2.86 MBytes  24.0 Mbits/sec   12   19.8 KBytes       
[  6]   3.00-4.00   sec  2.80 MBytes  23.5 Mbits/sec   14   14.1 KBytes       
[  6]   4.00-5.00   sec  2.86 MBytes  24.0 Mbits/sec   12   18.4 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  14.4 MBytes  24.1 Mbits/sec   64             sender
[  6]   0.00-5.00   sec  14.3 MBytes  23.9 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 42258 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  1.53 MBytes  12.9 Mbits/sec   16   8.48 KBytes       
[  6]   1.00-2.00   sec  1.43 MBytes  12.0 Mbits/sec   14   7.07 KBytes       
[  6]   2.00-3.00   sec  1.43 MBytes  12.0 Mbits/sec   17   8.48 KBytes       
[  6]   3.00-4.00   sec  1.43 MBytes  12.0 Mbits/sec   17   8.48 KBytes       
[  6]   4.00-5.00   sec  1.43 MBytes  12.0 Mbits/sec   17   8.48 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  7.25 MBytes  12.2 Mbits/sec   81             sender
[  6]   0.00-5.00   sec  7.13 MBytes  12.0 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 42937 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.00   sec  7.25 MBytes  12.2 Mbits/sec  0.537 ms  1659/6912 (24%)  receiver

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
[  6] local 10.7.0.2 port 43052 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  2.96 MBytes  24.8 Mbits/sec   13   14.1 KBytes       
[  6]   1.00-2.00   sec  2.86 MBytes  24.0 Mbits/sec   12   19.8 KBytes       
[  6]   2.00-3.00   sec  2.86 MBytes  24.0 Mbits/sec   13   18.4 KBytes       
[  6]   3.00-4.00   sec  2.92 MBytes  24.5 Mbits/sec   13   14.1 KBytes       
[  6]   4.00-5.00   sec  2.80 MBytes  23.5 Mbits/sec   13   14.1 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  14.4 MBytes  24.1 Mbits/sec   64             sender
[  6]   0.00-5.01   sec  14.3 MBytes  23.9 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 42268 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec   721 KBytes  5.91 Mbits/sec    8   5.66 KBytes       
[  6]   1.00-2.00   sec   636 KBytes  5.21 Mbits/sec   15   2.83 KBytes       
[  6]   2.00-3.00   sec   636 KBytes  5.21 Mbits/sec   19   5.66 KBytes       
[  6]   3.00-4.00   sec   573 KBytes  4.69 Mbits/sec   29   4.24 KBytes       
[  6]   4.00-5.00   sec   636 KBytes  5.21 Mbits/sec   24   7.07 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  3.13 MBytes  5.25 Mbits/sec   95             sender
[  6]   0.00-5.00   sec  2.99 MBytes  5.02 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 50913 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.01   sec  11.5 MBytes  19.2 Mbits/sec  0.491 ms  324/8632 (3.8%)  receiver

iperf Done.

cake: map firewall mark with flow to classid with eBPF, hosts:
==============================================================

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
[  6] local 10.7.0.2 port 43062 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  2.22 MBytes  18.6 Mbits/sec   13   18.4 KBytes       
[  6]   1.00-2.00   sec  2.86 MBytes  24.0 Mbits/sec   13   14.1 KBytes       
[  6]   2.00-3.00   sec  2.80 MBytes  23.5 Mbits/sec   13   14.1 KBytes       
[  6]   3.00-4.00   sec  2.86 MBytes  24.0 Mbits/sec   12   19.8 KBytes       
[  6]   4.00-5.00   sec  2.86 MBytes  24.0 Mbits/sec   13   18.4 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  13.6 MBytes  22.8 Mbits/sec   64             sender
[  6]   0.00-5.00   sec  13.5 MBytes  22.6 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 42274 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  1.72 MBytes  14.4 Mbits/sec   15   8.48 KBytes       
[  6]   1.00-2.00   sec  1.43 MBytes  12.0 Mbits/sec   14   8.48 KBytes       
[  6]   2.00-3.00   sec  1.43 MBytes  12.0 Mbits/sec   17   8.48 KBytes       
[  6]   3.00-4.00   sec  1.43 MBytes  12.0 Mbits/sec   17   7.07 KBytes       
[  6]   4.00-5.00   sec  1.43 MBytes  12.0 Mbits/sec   17   8.48 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  7.43 MBytes  12.5 Mbits/sec   80             sender
[  6]   0.00-5.00   sec  7.30 MBytes  12.2 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 59706 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.00   sec  7.87 MBytes  13.2 Mbits/sec  0.360 ms  1142/6840 (17%)  receiver

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
[  6] local 10.7.0.2 port 43066 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  3.02 MBytes  25.4 Mbits/sec   12   18.4 KBytes       
[  6]   1.00-2.00   sec  2.80 MBytes  23.5 Mbits/sec   13   12.7 KBytes       
[  6]   2.00-3.00   sec  2.92 MBytes  24.5 Mbits/sec   12   18.4 KBytes       
[  6]   3.00-4.00   sec  2.80 MBytes  23.5 Mbits/sec   13   18.4 KBytes       
[  6]   4.00-5.00   sec  2.92 MBytes  24.5 Mbits/sec   13   18.4 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  14.5 MBytes  24.3 Mbits/sec   63             sender
[  6]   0.00-5.01   sec  14.3 MBytes  23.9 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 42290 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec   788 KBytes  6.45 Mbits/sec    4   15.6 KBytes       
[  6]   1.00-2.00   sec   636 KBytes  5.21 Mbits/sec   12   5.66 KBytes       
[  6]   2.00-3.00   sec   636 KBytes  5.21 Mbits/sec   24   7.07 KBytes       
[  6]   3.00-4.00   sec   636 KBytes  5.21 Mbits/sec   27   5.66 KBytes       
[  6]   4.00-5.00   sec   509 KBytes  4.17 Mbits/sec   33   4.24 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  3.13 MBytes  5.25 Mbits/sec  100             sender
[  6]   0.00-5.00   sec  2.92 MBytes  4.90 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 54443 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.01   sec  11.5 MBytes  19.3 Mbits/sec  0.490 ms  277/8632 (3.2%)  receiver

iperf Done.
```
