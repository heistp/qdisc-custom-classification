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
		rm -f /tmp/cakeiso*
	) &> /dev/null
}

# run_test runs the iperf3 tests and emits the results
run_test() {
	ip netns exec cli iperf3 -C cubic --logfile /tmp/cakeiso1.log -t 5 -p 5202 -c 10.7.1.2 &
	ip netns exec cli iperf3 -C cubic --logfile /tmp/cakeiso2.log -t 5 -p 5203 -c 10.7.1.3 &
	ip netns exec cli iperf3 --logfile /tmp/cakeiso3.log -t 5 -p 5204 -u -b 20M -c 10.7.1.4 &

	wait

	echo
	echo "Subscriber 1, TCP client (cubic):"
	echo "---------------------------------"
	cat /tmp/cakeiso1.log

	echo
	echo "Subscriber 2, TCP client (cubic):"
	echo "---------------------------------"
	cat /tmp/cakeiso2.log

	echo
	echo "Subscriber 2, UDP client, 20Mbps unresponsive:"
	echo "----------------------------------------------"
	cat /tmp/cakeiso3.log
}

# cake_tc_flow_priority maps the priority field to flows using tc flow
cake_tc_flow_priority() {
	cat <<- EOF
	Map priority field to classid with tc flow, flows only:
	=======================================================
	
	Here, we use tc-flow to map the priority field to the minor classid.
	As expected, as see fairness between Subscriber 1 and Subscriber 2,
	but Subscriber 2's unresponsive UDP flow dominates their TCP flow,
	because they map to the same Cake flow.

	EOF

	set -x
	ip netns exec mid ipset create subscribers hash:ip skbinfo # counters
	ip netns exec mid ipset add subscribers 10.7.1.2 skbprio 0:1
	ip netns exec mid ipset add subscribers 10.7.1.3 skbprio 0:2
	ip netns exec mid ipset add subscribers 10.7.1.4 skbprio 0:2
	ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING \
		-j SET --map-set subscribers dst --map-prio
	ip netns exec mid tc qdisc add dev mid.r handle 1: \
		root cake bandwidth 50Mbit
	ip netns exec mid tc filter add dev mid.r parent 1: handle 0x9 \
		flow map key priority
	set +x
}

# cake_tc_flow_mark maps the firewall mark to flows using tc flow
cake_tc_flow_mark() {
	cat <<- EOF
	Map firewall mark to classid with tc flow, flows only:
	======================================================
	
	Here, we use tc-flow to map the priority field to the minor classid.
	As expected, as see fairness between Subscriber 1 and Subscriber 2,
	but Subscriber 2's unresponsive UDP flow dominates their TCP flow,
	because they map to the same Cake flow.

	EOF

	set -x
	ip netns exec mid ipset create subscribers hash:ip skbinfo # counters
	ip netns exec mid ipset add subscribers 10.7.1.2 skbmark 0x1
	ip netns exec mid ipset add subscribers 10.7.1.3 skbmark 0x2
	ip netns exec mid ipset add subscribers 10.7.1.4 skbmark 0x2
	ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING \
		-j SET --map-set subscribers dst --map-mark
	ip netns exec mid tc qdisc add dev mid.r handle 1: \
		root cake bandwidth 50Mbit
	ip netns exec mid tc filter add dev mid.r parent 1: handle 0x9 \
		flow map key mark
	set +x
}

# cake_tc_flow_mark_hosts_fail maps the firewall mark to hosts using tc flow
cake_tc_flow_mark_hosts_fail() {
	cat <<- EOF
	Map firewall mark to classid with tc-flow, failed hosts attempt:
	================================================================
	
	Here, we attempt to use tc-flow to map the firewall mark to hosts,
	but the attempt fails because tc-flow doesn't map the major classid.
	There is no fairness between subscribers, and the unresponsive flow wins.

	EOF

	set -x
	ip netns exec mid ipset create subscribers hash:ip skbinfo # counters
	ip netns exec mid ipset add subscribers 10.7.1.2 skbmark 0x10000
	ip netns exec mid ipset add subscribers 10.7.1.3 skbmark 0x20000
	ip netns exec mid ipset add subscribers 10.7.1.4 skbmark 0x20000
	ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING \
		-j SET --map-set subscribers dst --map-mark
	ip netns exec mid tc qdisc add dev mid.r handle 1: \
		root cake bandwidth 50Mbit
	ip netns exec mid tc filter add dev mid.r parent 1: handle 0x9 \
		flow map key mark
	set +x
}

# cake_ebpf_priority maps the priority field to hosts using eBPF
cake_ebpf_priority() {
	cat <<- EOF
	Map priority field to classid with eBPF, hosts only:
	====================================================
	
	Here, we use an eBPF classifier to map the priority field to the classid,
	using the major ID only.
	
	Because eBPF can map the major classid, we see both fairness between
	Subscriber 1 and Subscriber 2, and also between Subscriber 2's
	TCP and unresponsive UDP flows, because Cake hashes the flows when
	we haven't specified the minor classid.

	EOF

	set -x
	ip netns exec mid ipset create subscribers hash:ip skbinfo # counters
	ip netns exec mid ipset add subscribers 10.7.1.2 skbprio 2:0
	ip netns exec mid ipset add subscribers 10.7.1.3 skbprio 3:0
	ip netns exec mid ipset add subscribers 10.7.1.4 skbprio 3:0
	ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING \
		-j SET --map-set subscribers dst --map-prio
	ip netns exec mid tc qdisc add dev mid.r handle 1: \
		root cake bandwidth 50Mbit
	ip netns exec mid tc filter add dev mid.r parent 1: \
		bpf obj priority_to_classid.o
	set +x
}

# cake_ebpf_priority_flow maps the priority field to hosts and flows using eBPF
cake_ebpf_priority_flow() {
	cat <<- EOF
	Map priority field to classid with eBPF, hosts and flows:
	=========================================================
	
	Here, we use an eBPF classifier to map the priority field to the classid,
	using both the major and minor parts of the class ID.
	
	Because eBPF can map both the major and minor classid, we see
	fairness between Subscriber 1 and Subscriber 2, and we see Subscriber 2's
	unresponsive UDP flow dominate their TCP flow, since we have mapped
	them to the same Cake flow.

	EOF

	set -x
	ip netns exec mid ipset create subscribers hash:ip skbinfo # counters
	ip netns exec mid ipset add subscribers 10.7.1.2 skbprio 2:1
	ip netns exec mid ipset add subscribers 10.7.1.3 skbprio 3:2
	ip netns exec mid ipset add subscribers 10.7.1.4 skbprio 3:2
	ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING \
		-j SET --map-set subscribers dst --map-prio
	ip netns exec mid tc qdisc add dev mid.r handle 1: \
		root cake bandwidth 50Mbit
	ip netns exec mid tc filter add dev mid.r parent 1: \
		bpf obj priority_to_classid.o
	set +x
}

# cake_ebpf_mark maps the firewall mark to hosts using eBPF
cake_ebpf_mark() {
	cat <<- EOF
	Map firewall mark with flow to classid with eBPF, hosts only:
	=============================================================
	
	Here, we use an eBPF classifier to map the firewall mark to the classid,
	using the major ID only.
	
	Because eBPF can map the major classid, we see both fairness between
	Subscriber 1 and Subscriber 2, and also between Subscriber 2's
	TCP and unresponsive UDP flows, because Cake hashes the flows when
	we haven't specified the minor classid.

	EOF

	set -x
	ip netns exec mid ipset create subscribers hash:ip skbinfo # counters
	ip netns exec mid ipset add subscribers 10.7.1.2 skbmark 0x10000
	ip netns exec mid ipset add subscribers 10.7.1.3 skbmark 0x20000
	ip netns exec mid ipset add subscribers 10.7.1.4 skbmark 0x20000
	ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING \
		-j SET --map-set subscribers dst --map-mark
	ip netns exec mid tc qdisc add dev mid.r handle 1: \
		root cake bandwidth 50Mbit
	ip netns exec mid tc filter add dev mid.r parent 1: \
		bpf obj mark_to_classid.o
	set +x
}

# cake_ebpf_mark_flow maps the firewall mark to hosts and flows using eBPF
cake_ebpf_mark_flow() {
	cat <<- EOF
	Map firewall mark with flow to classid with eBPF, hosts and flows:
	==================================================================
	
	Here, we use an eBPF classifier to map the firewall mark to the classid,
	using both the major and minor parts of the class ID.
	
	Because eBPF can map both the major and minor classid, we see
	fairness between Subscriber 1 and Subscriber 2, and we see Subscriber 2's
	unresponsive UDP flow dominate their TCP flow, since we have mapped
	them to the same Cake flow.

	EOF

	set -x
	ip netns exec mid ipset create subscribers hash:ip skbinfo # counters
	ip netns exec mid ipset add subscribers 10.7.1.2 skbmark 0x10001
	ip netns exec mid ipset add subscribers 10.7.1.3 skbmark 0x20002
	ip netns exec mid ipset add subscribers 10.7.1.4 skbmark 0x20002
	ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING \
		-j SET --map-set subscribers dst --map-mark
	ip netns exec mid tc qdisc add dev mid.r handle 1: \
		root cake bandwidth 50Mbit
	ip netns exec mid tc filter add dev mid.r parent 1: \
		bpf obj mark_to_classid.o
	set +x
}

# fq_codel_priority uses the priority field for fq_codel classification
fq_codel_priority() {
	cat <<- EOF
	fq_codel: use priority field to override flow classification:
	=======================================================

	Here, we set the priority field to a classid with the major number
	the same as the fq_codel major number (handle), and the minor number
	to the subscriber ID. This way, we get a single Codel queue
	per-subscriber.

	As expected, we see fairness between Subscriber 1 and Subscriber 2,
	and Subscriber 2's unresponsive UDP flow dominates their TCP flow,
	because they're both in Subscriber 2's queue.

	EOF

	set -x
	ip netns exec mid ipset create subscribers hash:ip skbinfo # counters
	ip netns exec mid ipset add subscribers 10.7.1.2 skbprio 2:1
	ip netns exec mid ipset add subscribers 10.7.1.3 skbprio 2:2
	ip netns exec mid ipset add subscribers 10.7.1.4 skbprio 2:2
	ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING \
		-j SET --map-set subscribers dst --map-prio
	ip netns exec mid tc qdisc add dev mid.r root handle 1: htb default fff3
	ip netns exec mid tc class add dev mid.r parent 1: classid 1:fff3 \
		htb rate 50Mbit
	ip netns exec mid tc qdisc add dev mid.r handle 2: parent 1:fff3 fq_codel
	set +x
}

# main
trap teardown EXIT

setup_funcs=(\
	cake_tc_flow_priority \
	cake_tc_flow_mark \
	cake_tc_flow_mark_hosts_fail \
	cake_ebpf_priority \
	cake_ebpf_priority_flow \
	cake_ebpf_mark \
	cake_ebpf_mark_flow \
	fq_codel_priority \
)

for f in "${setup_funcs[@]}"; do
	setup
	$f
	run_test
	teardown
	echo
done
