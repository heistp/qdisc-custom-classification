#include <linux/bpf.h>

#define SEC(NAME) __attribute__((section(NAME), used))

SEC("classifier")
int cls_main(struct __sk_buff *skb)
{
	return skb->priority;
}

char __license[] SEC("license") = "GPL";
