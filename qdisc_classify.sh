#!/bin/bash

set -e

# setup sets up the netns environment
setup() {
	# set up server
	ip netns add srv
	ip link add dev srv.l type veth peer name mid.r
	ip link set dev srv.l netns srv
	ip netns exec srv ip addr add 10.7.1.2/24 dev srv.l
	ip netns exec srv ip addr add 10.7.1.3/24 dev srv.l
	ip netns exec srv ip addr add 10.7.1.4/24 dev srv.l
	ip netns exec srv ip link set srv.l up
	ip netns exec srv iperf3 -B 10.7.1.2 -p 5202 -s -D
	ip netns exec srv iperf3 -B 10.7.1.3 -p 5203 -s -D
	ip netns exec srv iperf3 -B 10.7.1.3 -p 5213 -s -D
	ip netns exec srv iperf3 -B 10.7.1.4 -p 5204 -s -D

	# set up middlebox
	ip netns add mid
	ip link set dev mid.r netns mid
	ip netns exec mid ip addr add 10.7.1.1/24 dev mid.r
	ip netns exec mid ip link set mid.r up
	ip link add dev mid.l type veth peer name cli.r
	ip link set dev mid.l netns mid
	ip netns exec mid ip addr add 10.7.0.1/24 dev mid.l
	ip netns exec mid ip link set mid.l up
	ip netns exec mid sysctl -qw net.ipv4.ip_forward=1

	# set up client
	ip netns add cli
	ip link set dev cli.r netns cli
	ip netns exec cli ip addr add 10.7.0.2/24 dev cli.r
	ip netns exec cli ip link set cli.r up

	# add routes
	ip netns exec srv ip route add 10.7.0.0/24 via 10.7.1.1 dev srv.l
	ip netns exec cli ip route add 10.7.1.0/24 via 10.7.0.1 dev cli.r
}

# teardown cleans up
teardown() {
	(
		ip netns del cli
		ip netns del mid
		ip netns del srv
		rm -f /tmp/qdisc_classify*
	) &> /dev/null
}

# run_subscriber_test runs the subscriber iperf3 tests and emits the results
run_subscriber_test() {
	ip netns exec cli iperf3 -C cubic --logfile /tmp/qdisc_classify1.log -t 5 -p 5202 -c 10.7.1.2 &
	ip netns exec cli iperf3 -C cubic --logfile /tmp/qdisc_classify2.log -t 5 -p 5203 -c 10.7.1.3 &
	ip netns exec cli iperf3 --logfile /tmp/qdisc_classify3.log -t 5 -p 5204 -u -b 20M -c 10.7.1.4 &

	wait

	echo
	echo "Subscriber 1, TCP client (cubic):"
	echo "---------------------------------"
	cat /tmp/qdisc_classify1.log

	echo
	echo "Subscriber 2, TCP client (cubic):"
	echo "---------------------------------"
	cat /tmp/qdisc_classify2.log

	echo
	echo "Subscriber 2, UDP client, 20Mbps unresponsive:"
	echo "----------------------------------------------"
	cat /tmp/qdisc_classify3.log
}

# run_host_test runs the host iperf3 tests and emits the results
run_host_test() {
	ip netns exec cli iperf3 -C cubic --logfile /tmp/qdisc_classify1.log -t 5 -p 5202 -c 10.7.1.2 &
	ip netns exec cli iperf3 -C cubic --logfile /tmp/qdisc_classify2.log -t 5 -p 5203 -c 10.7.1.3 &
	ip netns exec cli iperf3 --logfile /tmp/qdisc_classify3.log -t 5 -p 5213 -u -b 20M -c 10.7.1.3 &

	wait

	echo
	echo "Host 1, TCP client (cubic):"
	echo "---------------------------"
	cat /tmp/qdisc_classify1.log

	echo
	echo "Host 2, TCP client (cubic):"
	echo "---------------------------"
	cat /tmp/qdisc_classify2.log

	echo
	echo "Host 2, UDP client, 20Mbps unresponsive:"
	echo "----------------------------------------"
	cat /tmp/qdisc_classify3.log
}

# host_tc_flow uses the destination address for classification
host_tc_flow() {
	local qdisc=$1

	cat <<- EOF
	$1: use tc-flow with destination address for flow classification:
	=======================================================================

	Here, we use tc-flow with "hash keys dst" to hash packets by destination
	address. This sets the minor classid, giving a single queue for each
	destination address.

	As expected, we see fairness between destination Host 1 and Host 2, and
	Host 2's unresponsive UDP flow dominates their TCP flow, because they're
	both in Host 2's queue.

	EOF

	set -x
	ip netns exec mid tc qdisc add dev mid.r root handle 1: htb default 10
	ip netns exec mid tc class add dev mid.r parent 1: classid 1:10 \
		htb rate 50Mbit
	ip netns exec mid tc qdisc add dev mid.r handle 20: parent 1:10 $qdisc
	ip netns exec mid tc filter add dev mid.r \
		protocol all parent 20: handle 1 flow hash keys dst divisor 1024
	set +x

	run_host_test
}

# subscriber_priority uses the priority field for classification
subscriber_priority() {
	local qdisc=$1

	cat <<- EOF
	$1: use priority field to override flow classification:
	=============================================================

	Here, we set the priority field to a classid with the major number
	the same as the $1 major number (handle), and the minor number
	to the subscriber ID. This way, we get a single queue per-subscriber.

	As expected, we see fairness between Subscriber 1 and Subscriber 2,
	and Subscriber 2's unresponsive UDP flow dominates their TCP flow,
	because they're both in Subscriber 2's queue.

	EOF

	set -x
	ip netns exec mid tc qdisc add dev mid.r root handle 1: htb default 10
	ip netns exec mid tc class add dev mid.r parent 1: classid 1:10 \
		htb rate 50Mbit
	ip netns exec mid tc qdisc add dev mid.r handle 20: parent 1:10 $1
	ip netns exec mid ipset create subscribers hash:ip skbinfo # counters
	ip netns exec mid ipset add subscribers 10.7.1.2 skbprio 20:1
	ip netns exec mid ipset add subscribers 10.7.1.3 skbprio 20:2
	ip netns exec mid ipset add subscribers 10.7.1.4 skbprio 20:2
	ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING \
		-j SET --map-set subscribers dst --map-prio
	set +x

	run_subscriber_test
}

# subscriber_cake_priority_tc_flow maps the priority field to flows using tc flow
subscriber_cake_priority_tc_flow() {
	cat <<- EOF
	cake: map priority field to minor classid with tc flow:
	=======================================================
	
	Here, we use tc-flow to map the priority field to the minor classid.
	As expected, as see fairness between Subscriber 1 and Subscriber 2,
	but Subscriber 2's unresponsive UDP flow dominates their TCP flow,
	because they map to the same Cake flow.

	EOF

	set -x
	ip netns exec mid tc qdisc add dev mid.r handle 20: \
		root cake bandwidth 50Mbit
	ip netns exec mid tc filter add dev mid.r parent 20: handle 0x9 \
		flow map key priority
	ip netns exec mid ipset create subscribers hash:ip skbinfo # counters
	ip netns exec mid ipset add subscribers 10.7.1.2 skbprio 0:1
	ip netns exec mid ipset add subscribers 10.7.1.3 skbprio 0:2
	ip netns exec mid ipset add subscribers 10.7.1.4 skbprio 0:2
	ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING \
		-j SET --map-set subscribers dst --map-prio
	set +x

	run_subscriber_test
}

# subscriber_cake_mark_tc_flow maps the firewall mark to flows using tc flow
subscriber_cake_mark_tc_flow() {
	cat <<- EOF
	cake: map firewall mark to minor classid with tc flow:
	======================================================
	
	Here, we use tc-flow to map the mark field to the minor classid.
	As expected, as see fairness between Subscriber 1 and Subscriber 2,
	but Subscriber 2's unresponsive UDP flow dominates their TCP flow,
	because they map to the same Cake flow.

	EOF

	set -x
	ip netns exec mid tc qdisc add dev mid.r handle 20: \
		root cake bandwidth 50Mbit
	ip netns exec mid tc filter add dev mid.r parent 20: handle 0x9 \
		flow map key mark
	ip netns exec mid ipset create subscribers hash:ip skbinfo # counters
	ip netns exec mid ipset add subscribers 10.7.1.2 skbmark 0x1
	ip netns exec mid ipset add subscribers 10.7.1.3 skbmark 0x2
	ip netns exec mid ipset add subscribers 10.7.1.4 skbmark 0x2
	ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING \
		-j SET --map-set subscribers dst --map-mark
	set +x

	run_subscriber_test
}

# subscriber_cake_mark_tc_flow_hosts_fail maps the firewall mark to hosts using tc flow
subscriber_cake_mark_tc_flow_hosts_fail() {
	cat <<- EOF
	cake: map firewall mark to minor classid with tc-flow, failed hosts attempt:
	============================================================================
	
	Here, we attempt to use tc-flow to map the firewall mark to hosts,
	but the attempt fails because tc-flow doesn't map the major classid.
	All three flows end up in the same queue, because the lower 16 bits
	of the mark (all zero) are added to a base class ID of :1.

	EOF

	set -x
	ip netns exec mid tc qdisc add dev mid.r handle 20: \
		root cake bandwidth 50Mbit dsthost
	ip netns exec mid tc filter add dev mid.r parent 20: handle 0x9 \
		flow map key mark
	ip netns exec mid ipset create subscribers hash:ip skbinfo # counters
	ip netns exec mid ipset add subscribers 10.7.1.2 skbmark 0x10000
	ip netns exec mid ipset add subscribers 10.7.1.3 skbmark 0x20000
	ip netns exec mid ipset add subscribers 10.7.1.4 skbmark 0x20000
	ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING \
		-j SET --map-set subscribers dst --map-mark
	set +x

	run_subscriber_test
}

# subscriber_cake_priority_ebpf maps the priority field to hosts using eBPF
subscriber_cake_priority_ebpf() {
	cat <<- EOF
	cake: map priority field to classid with eBPF, hosts:
	=====================================================
	
	Here, we use an eBPF classifier to map the priority field to the classid,
	using the major ID only.
	
	Because eBPF can map the major classid, we see both fairness between
	Subscriber 1 and Subscriber 2, and also between Subscriber 2's
	TCP and unresponsive UDP flows, because Cake hashes the flows as
	usual when we haven't specified the minor classid.

	EOF

	set -x
	ip netns exec mid tc qdisc add dev mid.r handle 20: \
		root cake bandwidth 50Mbit
	ip netns exec mid tc filter add dev mid.r parent 20: \
		bpf obj priority_to_classid.o
	ip netns exec mid ipset create subscribers hash:ip skbinfo # counters
	ip netns exec mid ipset add subscribers 10.7.1.2 skbprio 1:0
	ip netns exec mid ipset add subscribers 10.7.1.3 skbprio 2:0
	ip netns exec mid ipset add subscribers 10.7.1.4 skbprio 2:0
	ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING \
		-j SET --map-set subscribers dst --map-prio
	set +x

	run_subscriber_test
}

# subscriber_cake_priority_ebpf_flow maps the priority field to hosts and flows using eBPF
subscriber_cake_priority_ebpf_flow() {
	cat <<- EOF
	cake: map priority field to classid with eBPF, hosts and flows:
	===============================================================
	
	Here, we use an eBPF classifier to map the priority field to the classid,
	using both the major and minor parts of the class ID.
	
	Because eBPF can map both the major and minor classid, we see
	fairness between Subscriber 1 and Subscriber 2, and we see Subscriber 2's
	unresponsive UDP flow dominate their TCP flow, since we have mapped
	them to the same Cake flow.

	EOF

	set -x
	ip netns exec mid tc qdisc add dev mid.r handle 20: \
		root cake bandwidth 50Mbit
	ip netns exec mid tc filter add dev mid.r parent 20: \
		bpf obj priority_to_classid.o
	ip netns exec mid ipset create subscribers hash:ip skbinfo # counters
	ip netns exec mid ipset add subscribers 10.7.1.2 skbprio 1:3
	ip netns exec mid ipset add subscribers 10.7.1.3 skbprio 2:4
	ip netns exec mid ipset add subscribers 10.7.1.4 skbprio 2:4
	ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING \
		-j SET --map-set subscribers dst --map-prio
	set +x

	run_subscriber_test
}

# subscriber_cake_mark_ebpf maps the firewall mark to hosts using eBPF
subscriber_cake_mark_ebpf() {
	cat <<- EOF
	cake: map firewall mark with flow to classid with eBPF, hosts:
	==============================================================
	
	Here, we use an eBPF classifier to map the firewall mark to the classid,
	using the major ID only.
	
	Because eBPF can map the major classid, we see both fairness between
	Subscriber 1 and Subscriber 2, and also between Subscriber 2's
	TCP and unresponsive UDP flows, because Cake hashes the flows as
	usual when we haven't specified the minor classid.

	EOF

	set -x
	ip netns exec mid tc qdisc add dev mid.r handle 20: \
		root cake bandwidth 50Mbit
	ip netns exec mid tc filter add dev mid.r parent 20: \
		bpf obj mark_to_classid.o
	ip netns exec mid ipset create subscribers hash:ip skbinfo # counters
	ip netns exec mid ipset add subscribers 10.7.1.2 skbmark 0x10000
	ip netns exec mid ipset add subscribers 10.7.1.3 skbmark 0x20000
	ip netns exec mid ipset add subscribers 10.7.1.4 skbmark 0x20000
	ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING \
		-j SET --map-set subscribers dst --map-mark
	set +x

	run_subscriber_test
}

# subscriber_cake_mark_ebpf_flow maps the firewall mark to hosts and flows using eBPF
subscriber_cake_mark_ebpf_flow() {
	cat <<- EOF
	cake: map firewall mark with flow to classid with eBPF, hosts and flows:
	========================================================================
	
	Here, we use an eBPF classifier to map the firewall mark to the classid,
	using both the major and minor parts of the class ID.
	
	Because eBPF can map both the major and minor classid, we see fairness
	between Subscriber 1 and Subscriber 2, and we see Subscriber 2's
	unresponsive UDP flow dominate their TCP flow, since we have mapped
	them to the same Cake flow.

	EOF

	set -x
	ip netns exec mid tc qdisc add dev mid.r handle 20: \
		root cake bandwidth 50Mbit
	ip netns exec mid tc filter add dev mid.r parent 20: \
		bpf obj mark_to_classid.o
	ip netns exec mid ipset create subscribers hash:ip skbinfo # counters
	ip netns exec mid ipset add subscribers 10.7.1.2 skbmark 0x10003
	ip netns exec mid ipset add subscribers 10.7.1.3 skbmark 0x20004
	ip netns exec mid ipset add subscribers 10.7.1.4 skbmark 0x20004
	ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING \
		-j SET --map-set subscribers dst --map-mark
	set +x

	run_subscriber_test
}

# main
trap teardown EXIT

test_funcs=(\
	"host_tc_flow fq_codel" \
	"host_tc_flow sfq" \
	"host_tc_flow cake" \
	#"host_tc_flow fq_pie" \
	"subscriber_priority fq_codel" \
	"subscriber_priority sfq" \
	"subscriber_priority fq_pie" \
	"subscriber_cake_priority_tc_flow" \
	"subscriber_cake_mark_tc_flow" \
	"subscriber_cake_mark_tc_flow_hosts_fail" \
	"subscriber_cake_priority_ebpf" \
	"subscriber_cake_priority_ebpf_flow" \
	"subscriber_cake_mark_ebpf" \
	"subscriber_cake_mark_ebpf_flow" \
)

for f in "${test_funcs[@]}"; do
	setup
	$f
	teardown
	echo
done
