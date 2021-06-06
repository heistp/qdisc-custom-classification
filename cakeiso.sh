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
	ip netns exec mid tc qdisc add dev mid.r handle 1: \
		root cake bandwidth 50Mbit

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
	ip netns exec cli iperf3 --logfile /tmp/cakeiso1.log -t 5 -p 5202 -c 10.7.1.2 &
	ip netns exec cli iperf3 --logfile /tmp/cakeiso2.log -t 5 -p 5203 -c 10.7.1.3 &
	ip netns exec cli iperf3 --logfile /tmp/cakeiso3.log -t 5 -p 5204 -u -b 20M -c 10.7.1.4 &

	wait

	echo
	echo "Subscriber 1, TCP client:"
	echo "-------------------------"
	cat /tmp/cakeiso1.log

	echo
	echo "Subscriber 2, TCP client:"
	echo "-----------------------------"
	cat /tmp/cakeiso2.log

	echo
	echo "Subscriber 2, UDP client, 20Mbps unresponsive:"
	echo "----------------------------------------------"
	cat /tmp/cakeiso3.log
}

# setup_tc_flow_priority maps the priority field to flows using tc flow
setup_tc_flow_priority() {
	echo "Map priority field to classid with tc flow, flows only:"
	echo "======================================================="
	echo
	echo "Here, we use tc-flow to map the priority field to the minor classid."
	echo "As expected, as see fairness between Subscriber 1 and Subscriber 2,"
	echo "but Subscriber 2's unresponsive UDP flow dominates their TCP flow,"
	echo "because they map to the same Cake flow."
	echo

	set -x
	ip netns exec mid ipset create subscribers hash:ip skbinfo # counters
	ip netns exec mid ipset add subscribers 10.7.1.2 skbprio 0:1
	ip netns exec mid ipset add subscribers 10.7.1.3 skbprio 0:2
	ip netns exec mid ipset add subscribers 10.7.1.4 skbprio 0:2
	ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING \
		-j SET --map-set subscribers dst --map-prio
	ip netns exec mid tc filter add dev mid.r parent 1: handle 0x9 \
		flow map key priority
	set +x
}

# setup_tc_flow_mark maps the firewall mark to flows using tc flow
setup_tc_flow_mark() {
	echo "Map firewall mark to classid with tc flow, flows only:"
	echo "======================================================"
	echo
	echo "Here, we use tc-flow to map the priority field to the minor classid."
	echo "As expected, as see fairness between Subscriber 1 and Subscriber 2,"
	echo "but Subscriber 2's unresponsive UDP flow dominates their TCP flow,"
	echo "because they map to the same Cake flow."
	echo

	set -x
	ip netns exec mid ipset create subscribers hash:ip skbinfo # counters
	ip netns exec mid ipset add subscribers 10.7.1.2 skbmark 0x1
	ip netns exec mid ipset add subscribers 10.7.1.3 skbmark 0x2
	ip netns exec mid ipset add subscribers 10.7.1.4 skbmark 0x2
	ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING \
		-j SET --map-set subscribers dst --map-mark
	ip netns exec mid tc filter add dev mid.r parent 1: handle 0x9 \
		flow map key mark
	set +x
}

# setup_tc_flow_mark_hosts_fail maps the firewall mark to hosts using tc flow
setup_tc_flow_mark_hosts_fail() {
	echo "Map firewall mark to classid with tc-flow, failed hosts attempt:"
	echo "================================================================"
	echo
	echo "Here, we attempt to use tc-flow to map the firewall mark to hosts,"
	echo "but the attempt fails because tc-flow doesn't map the major classid."
	echo "There is no fairness between subscribers, and the unresponsive flow wins."
	echo

	set -x
	ip netns exec mid ipset create subscribers hash:ip skbinfo # counters
	ip netns exec mid ipset add subscribers 10.7.1.2 skbmark 0x10000
	ip netns exec mid ipset add subscribers 10.7.1.3 skbmark 0x20000
	ip netns exec mid ipset add subscribers 10.7.1.4 skbmark 0x20000
	ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING \
		-j SET --map-set subscribers dst --map-mark
	ip netns exec mid tc filter add dev mid.r parent 1: handle 0x9 \
		flow map key mark
	set +x
}

# setup_ebpf_priority maps the priority field to hosts using eBPF
setup_ebpf_priority() {
	echo "Map priority field to classid with eBPF, hosts only:"
	echo "===================================================="
	echo
	echo "Here, we use an eBPF classifier to map the priority field to the classid,"
	echo "using the major ID only."
	echo
	echo "Because eBPF can map the major classid, we see both fairness between"
	echo "Subscriber 1 and Subscriber 2, and also between Subscriber 2's"
	echo "TCP and unresponsive UDP flows, because Cake hashes the flows when"
	echo "we haven't specified the minor classid."
	echo

	ip netns exec mid ipset create subscribers hash:ip skbinfo # counters
	ip netns exec mid ipset add subscribers 10.7.1.2 skbprio 2:0
	ip netns exec mid ipset add subscribers 10.7.1.3 skbprio 3:0
	ip netns exec mid ipset add subscribers 10.7.1.4 skbprio 3:0
	ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING \
		-j SET --map-set subscribers dst --map-prio
	ip netns exec mid tc filter add dev mid.r parent 1: bpf obj priority_to_classid.o
}

# setup_ebpf_priority_flow maps the priority field to hosts and flows using eBPF
setup_ebpf_priority_flow() {
	echo "Map priority field to classid with eBPF, hosts and flows:"
	echo "========================================================="
	echo
	echo "Here, we use an eBPF classifier to map the priority field to the classid,"
	echo "using both the major and minor parts of the class ID."
	echo
	echo "Because eBPF can map both the major and minor classid, we see"
	echo "fairness between Subscriber 1 and Subscriber 2, and we see Subscriber 2's"
	echo "unresponsive UDP flow dominate their TCP flow, since we have mapped"
	echo "them to the same Cake flow."
	echo

	ip netns exec mid ipset create subscribers hash:ip skbinfo # counters
	ip netns exec mid ipset add subscribers 10.7.1.2 skbprio 2:1
	ip netns exec mid ipset add subscribers 10.7.1.3 skbprio 3:2
	ip netns exec mid ipset add subscribers 10.7.1.4 skbprio 3:2
	ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING \
		-j SET --map-set subscribers dst --map-prio
	ip netns exec mid tc filter add dev mid.r parent 1: bpf obj priority_to_classid.o
}

# setup_ebpf_mark maps the firewall mark to hosts using eBPF
setup_ebpf_mark() {
	echo "Map firewall mark with flow to classid with eBPF, hosts only:"
	echo "============================================================="
	echo
	echo "Here, we use an eBPF classifier to map the firewall mark to the classid,"
	echo "using the major ID only."
	echo
	echo "Because eBPF can map the major classid, we see both fairness between"
	echo "Subscriber 1 and Subscriber 2, and also between Subscriber 2's"
	echo "TCP and unresponsive UDP flows, because Cake hashes the flows when"
	echo "we haven't specified the minor classid."
	echo

	ip netns exec mid ipset create subscribers hash:ip skbinfo # counters
	ip netns exec mid ipset add subscribers 10.7.1.2 skbmark 0x10000
	ip netns exec mid ipset add subscribers 10.7.1.3 skbmark 0x20000
	ip netns exec mid ipset add subscribers 10.7.1.4 skbmark 0x20000
	ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING \
		-j SET --map-set subscribers dst --map-mark
	ip netns exec mid tc filter add dev mid.r parent 1: bpf obj mark_to_classid.o
}

# setup_ebpf_mark_flow maps the firewall mark to hosts and flows using eBPF
setup_ebpf_mark_flow() {
	echo "Map firewall mark with flow to classid with eBPF, hosts and flows:"
	echo "=================================================================="
	echo
	echo "Here, we use an eBPF classifier to map the firewall mark to the classid,"
	echo "using both the major and minor parts of the class ID."
	echo
	echo "Because eBPF can map both the major and minor classid, we see"
	echo "fairness between Subscriber 1 and Subscriber 2, and we see Subscriber 2's"
	echo "unresponsive UDP flow dominate their TCP flow, since we have mapped"
	echo "them to the same Cake flow."
	echo

	ip netns exec mid ipset create subscribers hash:ip skbinfo # counters
	ip netns exec mid ipset add subscribers 10.7.1.2 skbmark 0x10001
	ip netns exec mid ipset add subscribers 10.7.1.3 skbmark 0x20002
	ip netns exec mid ipset add subscribers 10.7.1.4 skbmark 0x20002
	ip netns exec mid iptables -o mid.r -t mangle -A POSTROUTING \
		-j SET --map-set subscribers dst --map-mark
	ip netns exec mid tc filter add dev mid.r parent 1: bpf obj mark_to_classid.o
}

# main
trap teardown EXIT

setup_funcs=(\
	setup_tc_flow_priority \
	setup_tc_flow_mark \
	setup_tc_flow_mark_hosts_fail \
	setup_ebpf_priority \
	setup_ebpf_priority_flow \
	setup_ebpf_mark \
	setup_ebpf_mark_flow \
)

for f in "${setup_funcs[@]}"; do
	setup
	$f
	run_test
	teardown
	echo
done
