```
fq_codel: use tc-flow with destination address for flow classification:
=======================================================================

Here, we use tc-flow with "hash keys dst" to hash packets by destination
address. This sets the minor classid, giving an fq_codel queue for each
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
[  6] local 10.7.0.2 port 38636 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  3.30 MBytes  27.7 Mbits/sec   20   24.0 KBytes       
[  6]   1.00-2.00   sec  2.80 MBytes  23.5 Mbits/sec   18   21.2 KBytes       
[  6]   2.00-3.00   sec  2.80 MBytes  23.5 Mbits/sec   20   19.8 KBytes       
[  6]   3.00-4.00   sec  2.80 MBytes  23.5 Mbits/sec   19   19.8 KBytes       
[  6]   4.00-5.00   sec  2.98 MBytes  25.0 Mbits/sec   17   21.2 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  14.7 MBytes  24.6 Mbits/sec   94             sender
[  6]   0.00-5.01   sec  14.3 MBytes  23.9 Mbits/sec                  receiver

iperf Done.

Host 2, TCP client (cubic):
---------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 37856 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  2.66 MBytes  22.3 Mbits/sec   17    161 KBytes       
[  6]   1.00-2.00   sec   764 KBytes  6.26 Mbits/sec   22    106 KBytes       
[  6]   2.00-3.00   sec  0.00 Bytes  0.00 bits/sec   19   36.8 KBytes       
[  6]   3.00-4.00   sec   700 KBytes  5.74 Mbits/sec   23   11.3 KBytes       
[  6]   4.00-5.00   sec   700 KBytes  5.74 Mbits/sec   20   5.66 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  4.77 MBytes  8.01 Mbits/sec  101             sender
[  6]   0.00-5.00   sec  3.06 MBytes  5.13 Mbits/sec                  receiver

iperf Done.

Host 2, UDP client, 20Mbps unresponsive:
----------------------------------------
Connecting to host 10.7.1.3, port 5213
[  6] local 10.7.0.2 port 59708 connected to 10.7.1.3 port 5213
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.01   sec  11.4 MBytes  19.1 Mbits/sec  0.528 ms  369/8632 (4.3%)  receiver

iperf Done.

sfq: use tc-flow with destination address for flow classification:
=======================================================================

Here, we use tc-flow with "hash keys dst" to hash packets by destination
address. This sets the minor classid, giving an sfq queue for each
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
[  6] local 10.7.0.2 port 38642 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  3.68 MBytes  30.8 Mbits/sec   11   99.0 KBytes       
[  6]   1.00-2.00   sec  2.98 MBytes  25.0 Mbits/sec    0    119 KBytes       
[  6]   2.00-3.00   sec  2.61 MBytes  21.9 Mbits/sec    0    136 KBytes       
[  6]   3.00-4.00   sec  2.98 MBytes  25.0 Mbits/sec    0    151 KBytes       
[  6]   4.00-5.00   sec  2.98 MBytes  25.0 Mbits/sec    0    165 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  15.2 MBytes  25.6 Mbits/sec   11             sender
[  6]   0.00-5.05   sec  14.4 MBytes  24.0 Mbits/sec                  receiver

iperf Done.

Host 2, TCP client (cubic):
---------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 37866 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  2.35 MBytes  19.7 Mbits/sec  420   65.0 KBytes       
[  6]   1.00-2.00   sec  1.24 MBytes  10.4 Mbits/sec   18   24.0 KBytes       
[  6]   2.00-3.00   sec   636 KBytes  5.21 Mbits/sec    3   25.5 KBytes       
[  6]   3.00-4.00   sec   700 KBytes  5.73 Mbits/sec    3   17.0 KBytes       
[  6]   4.00-5.00   sec  0.00 Bytes  0.00 bits/sec    4   24.0 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  4.90 MBytes  8.21 Mbits/sec  448             sender
[  6]   0.00-5.03   sec  3.70 MBytes  6.17 Mbits/sec                  receiver

iperf Done.

Host 2, UDP client, 20Mbps unresponsive:
----------------------------------------
Connecting to host 10.7.1.3, port 5213
[  6] local 10.7.0.2 port 40984 connected to 10.7.1.3 port 5213
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8631 (0%)  sender
[  6]   0.00-5.03   sec  10.8 MBytes  18.0 Mbits/sec  0.557 ms  805/8631 (9.3%)  receiver

iperf Done.

cake: use tc-flow with destination address for flow classification:
=======================================================================

Here, we use tc-flow with "hash keys dst" to hash packets by destination
address. This sets the minor classid, giving an cake queue for each
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
[  6] local 10.7.0.2 port 38656 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  3.02 MBytes  25.4 Mbits/sec   12   19.8 KBytes       
[  6]   1.00-2.00   sec  2.80 MBytes  23.5 Mbits/sec   13   15.6 KBytes       
[  6]   2.00-3.00   sec  2.86 MBytes  24.0 Mbits/sec   13   14.1 KBytes       
[  6]   3.00-4.00   sec  2.86 MBytes  24.0 Mbits/sec   13   14.1 KBytes       
[  6]   4.00-5.00   sec  2.86 MBytes  24.0 Mbits/sec   13   12.7 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  14.4 MBytes  24.1 Mbits/sec   64             sender
[  6]   0.00-5.00   sec  14.3 MBytes  23.9 Mbits/sec                  receiver

iperf Done.

Host 2, TCP client (cubic):
---------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 37876 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec   779 KBytes  6.38 Mbits/sec    7   5.66 KBytes       
[  6]   1.00-2.00   sec   636 KBytes  5.21 Mbits/sec   15   5.66 KBytes       
[  6]   2.00-3.00   sec   636 KBytes  5.21 Mbits/sec   22   5.66 KBytes       
[  6]   3.00-4.00   sec   636 KBytes  5.21 Mbits/sec   26   4.24 KBytes       
[  6]   4.00-5.00   sec   636 KBytes  5.21 Mbits/sec   28   5.66 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  3.25 MBytes  5.45 Mbits/sec   98             sender
[  6]   0.00-5.00   sec  2.99 MBytes  5.01 Mbits/sec                  receiver

iperf Done.

Host 2, UDP client, 20Mbps unresponsive:
----------------------------------------
Connecting to host 10.7.1.3, port 5213
[  6] local 10.7.0.2 port 60651 connected to 10.7.1.3 port 5213
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.01   sec  11.5 MBytes  19.2 Mbits/sec  0.492 ms  319/8632 (3.7%)  receiver

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
[  6] local 10.7.0.2 port 38668 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  3.15 MBytes  26.4 Mbits/sec   20   19.8 KBytes       
[  6]   1.00-2.00   sec  2.73 MBytes  22.9 Mbits/sec   19   19.8 KBytes       
[  6]   2.00-3.00   sec  2.86 MBytes  24.0 Mbits/sec   16   24.0 KBytes       
[  6]   3.00-4.00   sec  2.86 MBytes  24.0 Mbits/sec   18   19.8 KBytes       
[  6]   4.00-5.00   sec  2.86 MBytes  24.0 Mbits/sec   18   19.8 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  14.5 MBytes  24.3 Mbits/sec   91             sender
[  6]   0.00-5.01   sec  14.3 MBytes  23.9 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 37884 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  1.26 MBytes  10.5 Mbits/sec    2   65.0 KBytes       
[  6]   1.00-2.00   sec   382 KBytes  3.13 Mbits/sec   13   8.48 KBytes       
[  6]   2.00-3.00   sec   573 KBytes  4.69 Mbits/sec   22   2.83 KBytes       
[  6]   3.00-4.00   sec   573 KBytes  4.69 Mbits/sec    8   11.3 KBytes       
[  6]   4.00-5.00   sec   573 KBytes  4.69 Mbits/sec   21   9.90 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  3.31 MBytes  5.55 Mbits/sec   66             sender
[  6]   0.00-5.00   sec  2.95 MBytes  4.95 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 48046 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.01   sec  11.5 MBytes  19.3 Mbits/sec  0.640 ms  287/8632 (3.3%)  receiver

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
[  6] local 10.7.0.2 port 38672 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  3.72 MBytes  31.2 Mbits/sec    4    132 KBytes       
[  6]   1.00-2.00   sec  2.98 MBytes  25.0 Mbits/sec    0    161 KBytes       
[  6]   2.00-3.00   sec  2.61 MBytes  21.9 Mbits/sec    1    139 KBytes       
[  6]   3.00-4.00   sec  3.11 MBytes  26.1 Mbits/sec    1    106 KBytes       
[  6]   4.00-5.00   sec  2.61 MBytes  21.9 Mbits/sec    0    126 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  15.0 MBytes  25.2 Mbits/sec    6             sender
[  6]   0.00-5.04   sec  14.4 MBytes  23.9 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 37896 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  1.04 MBytes  8.76 Mbits/sec   23   14.1 KBytes       
[  6]   1.00-2.00   sec   573 KBytes  4.69 Mbits/sec    2   24.0 KBytes       
[  6]   2.00-3.00   sec   764 KBytes  6.26 Mbits/sec    4   22.6 KBytes       
[  6]   3.00-4.00   sec   573 KBytes  4.69 Mbits/sec    2   31.1 KBytes       
[  6]   4.00-5.00   sec   573 KBytes  4.69 Mbits/sec    4   22.6 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  3.47 MBytes  5.82 Mbits/sec   35             sender
[  6]   0.00-5.03   sec  3.20 MBytes  5.34 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 34223 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8631 (0%)  sender
[  6]   0.00-5.04   sec  11.3 MBytes  18.9 Mbits/sec  0.380 ms  426/8631 (4.9%)  receiver

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
[  6] local 10.7.0.2 port 38682 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  4.49 MBytes  37.6 Mbits/sec   24    417 KBytes       
[  6]   1.00-2.00   sec  3.60 MBytes  30.2 Mbits/sec  549   4.24 KBytes       
[  6]   2.00-3.00   sec  3.54 MBytes  29.7 Mbits/sec  187   8.48 KBytes       
[  6]   3.00-4.00   sec  2.36 MBytes  19.8 Mbits/sec  143   19.8 KBytes       
[  6]   4.00-5.00   sec  3.54 MBytes  29.7 Mbits/sec   26   25.5 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  17.5 MBytes  29.4 Mbits/sec  929             sender
[  6]   0.00-5.01   sec  14.5 MBytes  24.3 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 37906 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  1.23 MBytes  10.3 Mbits/sec    2   86.3 KBytes       
[  6]   1.00-2.00   sec   509 KBytes  4.17 Mbits/sec   66   2.83 KBytes       
[  6]   2.00-3.00   sec   509 KBytes  4.17 Mbits/sec   36   5.66 KBytes       
[  6]   3.00-4.00   sec   764 KBytes  6.26 Mbits/sec   28   8.48 KBytes       
[  6]   4.00-5.00   sec   764 KBytes  6.26 Mbits/sec   26   7.07 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  3.72 MBytes  6.23 Mbits/sec  158             sender
[  6]   0.00-5.00   sec  3.13 MBytes  5.25 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 35090 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.01   sec  11.1 MBytes  18.6 Mbits/sec  0.561 ms  584/8632 (6.8%)  receiver

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
[  6] local 10.7.0.2 port 38698 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  3.02 MBytes  25.4 Mbits/sec   12   19.8 KBytes       
[  6]   1.00-2.00   sec  2.80 MBytes  23.5 Mbits/sec   14   14.1 KBytes       
[  6]   2.00-3.00   sec  2.86 MBytes  24.0 Mbits/sec   13   15.6 KBytes       
[  6]   3.00-4.00   sec  2.92 MBytes  24.5 Mbits/sec   13   18.4 KBytes       
[  6]   4.00-5.00   sec  2.80 MBytes  23.5 Mbits/sec   13   14.1 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  14.4 MBytes  24.1 Mbits/sec   65             sender
[  6]   0.00-5.01   sec  14.3 MBytes  23.9 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 37914 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec   730 KBytes  5.98 Mbits/sec    4   14.1 KBytes       
[  6]   1.00-2.00   sec   573 KBytes  4.69 Mbits/sec   15   5.66 KBytes       
[  6]   2.00-3.00   sec   700 KBytes  5.73 Mbits/sec   23   5.66 KBytes       
[  6]   3.00-4.00   sec   573 KBytes  4.69 Mbits/sec   26   2.83 KBytes       
[  6]   4.00-5.00   sec   573 KBytes  4.69 Mbits/sec   28   7.07 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  3.07 MBytes  5.16 Mbits/sec   96             sender
[  6]   0.00-5.00   sec  2.94 MBytes  4.93 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 55001 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.01   sec  11.5 MBytes  19.3 Mbits/sec  0.534 ms  285/8632 (3.3%)  receiver

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
[  6] local 10.7.0.2 port 38704 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  3.02 MBytes  25.4 Mbits/sec   12   19.8 KBytes       
[  6]   1.00-2.00   sec  2.86 MBytes  24.0 Mbits/sec   13   18.4 KBytes       
[  6]   2.00-3.00   sec  2.80 MBytes  23.5 Mbits/sec   13   14.1 KBytes       
[  6]   3.00-4.00   sec  2.86 MBytes  24.0 Mbits/sec   13   14.1 KBytes       
[  6]   4.00-5.00   sec  2.92 MBytes  24.5 Mbits/sec   13   15.6 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  14.5 MBytes  24.3 Mbits/sec   64             sender
[  6]   0.00-5.01   sec  14.3 MBytes  23.9 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 37926 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec   734 KBytes  6.01 Mbits/sec    8   7.07 KBytes       
[  6]   1.00-2.00   sec   636 KBytes  5.21 Mbits/sec   12   4.24 KBytes       
[  6]   2.00-3.00   sec   636 KBytes  5.21 Mbits/sec   24   2.83 KBytes       
[  6]   3.00-4.00   sec   636 KBytes  5.21 Mbits/sec   29   2.83 KBytes       
[  6]   4.00-5.00   sec   509 KBytes  4.17 Mbits/sec   30   4.24 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  3.08 MBytes  5.16 Mbits/sec  103             sender
[  6]   0.00-5.00   sec  2.92 MBytes  4.90 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 47584 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.01   sec  11.5 MBytes  19.3 Mbits/sec  0.481 ms  273/8632 (3.2%)  receiver

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
[  6] local 10.7.0.2 port 38716 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  2.04 MBytes  17.1 Mbits/sec   11   12.7 KBytes       
[  6]   1.00-2.00   sec  1.37 MBytes  11.5 Mbits/sec   15   14.1 KBytes       
[  6]   2.00-3.00   sec  1.49 MBytes  12.5 Mbits/sec   19   9.90 KBytes       
[  6]   3.00-4.00   sec  1.74 MBytes  14.6 Mbits/sec   17   9.90 KBytes       
[  6]   4.00-5.00   sec  1.62 MBytes  13.6 Mbits/sec   19   11.3 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  8.26 MBytes  13.9 Mbits/sec   81             sender
[  6]   0.00-5.00   sec  8.05 MBytes  13.5 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 37936 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  1.58 MBytes  13.3 Mbits/sec   12   15.6 KBytes       
[  6]   1.00-2.00   sec  2.07 MBytes  17.4 Mbits/sec   13   11.3 KBytes       
[  6]   2.00-3.00   sec  1.93 MBytes  16.2 Mbits/sec   16   14.1 KBytes       
[  6]   3.00-4.00   sec  1.62 MBytes  13.6 Mbits/sec   18   9.90 KBytes       
[  6]   4.00-5.00   sec  1.80 MBytes  15.1 Mbits/sec   20   8.48 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  9.00 MBytes  15.1 Mbits/sec   79             sender
[  6]   0.00-5.00   sec  8.91 MBytes  14.9 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 53378 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.01   sec  11.8 MBytes  19.7 Mbits/sec  0.328 ms  104/8632 (1.2%)  receiver

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
[  6] local 10.7.0.2 port 38724 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  2.99 MBytes  25.1 Mbits/sec   12   19.8 KBytes       
[  6]   1.00-2.00   sec  2.86 MBytes  24.0 Mbits/sec   13   14.1 KBytes       
[  6]   2.00-3.00   sec  2.86 MBytes  24.0 Mbits/sec   12   19.8 KBytes       
[  6]   3.00-4.00   sec  2.86 MBytes  24.0 Mbits/sec   13   18.4 KBytes       
[  6]   4.00-5.00   sec  2.80 MBytes  23.5 Mbits/sec   13   18.4 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  14.4 MBytes  24.1 Mbits/sec   63             sender
[  6]   0.00-5.00   sec  14.3 MBytes  23.9 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 37944 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  1.56 MBytes  13.1 Mbits/sec   16   11.3 KBytes       
[  6]   1.00-2.00   sec  1.43 MBytes  12.0 Mbits/sec   15   8.48 KBytes       
[  6]   2.00-3.00   sec  1.43 MBytes  12.0 Mbits/sec   16   11.3 KBytes       
[  6]   3.00-4.00   sec  1.37 MBytes  11.5 Mbits/sec   18   5.66 KBytes       
[  6]   4.00-5.00   sec  1.43 MBytes  12.0 Mbits/sec   16   7.07 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  7.22 MBytes  12.1 Mbits/sec   81             sender
[  6]   0.00-5.00   sec  7.13 MBytes  12.0 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 57127 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.00   sec  7.25 MBytes  12.2 Mbits/sec  0.482 ms  1669/6918 (24%)  receiver

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
[  6] local 10.7.0.2 port 38738 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  3.02 MBytes  25.4 Mbits/sec   12   18.4 KBytes       
[  6]   1.00-2.00   sec  2.80 MBytes  23.5 Mbits/sec   13   15.6 KBytes       
[  6]   2.00-3.00   sec  2.86 MBytes  24.0 Mbits/sec   13   14.1 KBytes       
[  6]   3.00-4.00   sec  2.86 MBytes  24.0 Mbits/sec   13   14.1 KBytes       
[  6]   4.00-5.00   sec  2.86 MBytes  24.0 Mbits/sec   13   14.1 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  14.4 MBytes  24.1 Mbits/sec   64             sender
[  6]   0.00-5.00   sec  14.3 MBytes  23.9 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 37954 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec   718 KBytes  5.88 Mbits/sec    7   11.3 KBytes       
[  6]   1.00-2.00   sec   636 KBytes  5.21 Mbits/sec   15   11.3 KBytes       
[  6]   2.00-3.00   sec   636 KBytes  5.21 Mbits/sec   20   5.66 KBytes       
[  6]   3.00-4.00   sec   573 KBytes  4.69 Mbits/sec   26   4.24 KBytes       
[  6]   4.00-5.00   sec   573 KBytes  4.69 Mbits/sec   29   5.66 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  3.06 MBytes  5.14 Mbits/sec   97             sender
[  6]   0.00-5.00   sec  2.92 MBytes  4.90 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 35528 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.01   sec  11.5 MBytes  19.3 Mbits/sec  0.489 ms  273/8632 (3.2%)  receiver

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
[  6] local 10.7.0.2 port 38744 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  3.02 MBytes  25.4 Mbits/sec   13   18.4 KBytes       
[  6]   1.00-2.00   sec  2.80 MBytes  23.5 Mbits/sec   13   17.0 KBytes       
[  6]   2.00-3.00   sec  2.86 MBytes  24.0 Mbits/sec   13   15.6 KBytes       
[  6]   3.00-4.00   sec  2.92 MBytes  24.5 Mbits/sec   13   18.4 KBytes       
[  6]   4.00-5.00   sec  2.80 MBytes  23.5 Mbits/sec   13   15.6 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  14.4 MBytes  24.1 Mbits/sec   65             sender
[  6]   0.00-5.00   sec  14.3 MBytes  23.9 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 37966 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  1.56 MBytes  13.1 Mbits/sec   16   7.07 KBytes       
[  6]   1.00-2.00   sec  1.43 MBytes  12.0 Mbits/sec   14   8.48 KBytes       
[  6]   2.00-3.00   sec  1.43 MBytes  12.0 Mbits/sec   16   8.48 KBytes       
[  6]   3.00-4.00   sec  1.37 MBytes  11.5 Mbits/sec   18   7.07 KBytes       
[  6]   4.00-5.00   sec  1.43 MBytes  12.0 Mbits/sec   18   8.48 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  7.22 MBytes  12.1 Mbits/sec   82             sender
[  6]   0.00-5.00   sec  7.13 MBytes  12.0 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 36522 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.00   sec  7.25 MBytes  12.2 Mbits/sec  0.555 ms  1593/6845 (23%)  receiver

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
[  6] local 10.7.0.2 port 38756 connected to 10.7.1.2 port 5202
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec  2.96 MBytes  24.8 Mbits/sec   12   19.8 KBytes       
[  6]   1.00-2.00   sec  2.86 MBytes  24.0 Mbits/sec   13   14.1 KBytes       
[  6]   2.00-3.00   sec  2.86 MBytes  24.0 Mbits/sec   13   15.6 KBytes       
[  6]   3.00-4.00   sec  2.86 MBytes  24.0 Mbits/sec   13   14.1 KBytes       
[  6]   4.00-5.00   sec  2.86 MBytes  24.0 Mbits/sec   13   14.1 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  14.4 MBytes  24.1 Mbits/sec   64             sender
[  6]   0.00-5.00   sec  14.3 MBytes  23.9 Mbits/sec                  receiver

iperf Done.

Subscriber 2, TCP client (cubic):
---------------------------------
Connecting to host 10.7.1.3, port 5203
[  6] local 10.7.0.2 port 37972 connected to 10.7.1.3 port 5203
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-1.00   sec   721 KBytes  5.91 Mbits/sec    6   5.66 KBytes       
[  6]   1.00-2.00   sec   573 KBytes  4.69 Mbits/sec   15   4.24 KBytes       
[  6]   2.00-3.00   sec   700 KBytes  5.73 Mbits/sec   20   4.24 KBytes       
[  6]   3.00-4.00   sec   573 KBytes  4.69 Mbits/sec   26   2.83 KBytes       
[  6]   4.00-5.00   sec   636 KBytes  5.21 Mbits/sec   25   5.66 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-5.00   sec  3.13 MBytes  5.25 Mbits/sec   92             sender
[  6]   0.00-5.00   sec  3.00 MBytes  5.03 Mbits/sec                  receiver

iperf Done.

Subscriber 2, UDP client, 20Mbps unresponsive:
----------------------------------------------
Connecting to host 10.7.1.4, port 5204
[  6] local 10.7.0.2 port 46928 connected to 10.7.1.4 port 5204
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  6]   0.00-1.00   sec  2.38 MBytes  20.0 Mbits/sec  1725  
[  6]   1.00-2.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   2.00-3.00   sec  2.38 MBytes  20.0 Mbits/sec  1726  
[  6]   3.00-4.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
[  6]   4.00-5.00   sec  2.38 MBytes  20.0 Mbits/sec  1727  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  6]   0.00-5.00   sec  11.9 MBytes  20.0 Mbits/sec  0.000 ms  0/8632 (0%)  sender
[  6]   0.00-5.01   sec  11.5 MBytes  19.2 Mbits/sec  0.457 ms  324/8632 (3.8%)  receiver

iperf Done.
```
