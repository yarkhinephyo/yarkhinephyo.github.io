---
layout: post
title: "Learning Points: Getting Started with eBPF"
date: 2024-01-25 11:00:00 +0800
category: [Tech]
tags: [C, Networking, Operating-System, Learning-Points]
---

This [video](https://youtu.be/TJgxjVTZtfw?si=7wepOfWoMZYa35sP) is an introductory video on eBPF presented by Liz Rice from Isovalent. In the video description, there are also really interesting hands-on exercises.

### Overview

Adding features to the kernel is slow because of the complexity and the nature of open source community. eBPF allows running custom code in the kernel.

Any kernel function call, perf event, network packet can be attached as an event to trigger eBPF programs in the kernel.

### eBPF Hello World

This Python script compiles an eBPF program and attaches it to a kprobe that is hit whenever the `execve` syscall is run. Then the script prints traces produced by the eBPF program.

```python
#!/usr/bin/python3  
from bcc import BPF

program = r"""
int hello(void *ctx) {
    bpf_trace_printk("Hello World!");
    return 0;
}
"""

b = BPF(text=program)
syscall = b.get_syscall_fnname("execve")
b.attach_kprobe(event=syscall, fn_name="hello")

b.trace_print()
```

Depending on the type of event the eBPF program is attached to, `ctx` pointer contains different information.

### eBPF Map

eBPF map is a generic data structure that stores key-value data to share between eBPF kernel programs and user-space applications.

The macro `BPF_HASH` creates a hash table that can be updated in the kernel. The BCC framework provides an access to the map in the user-space via `b["counter_table"]`.

```c
BPF_HASH(counter_table);

int hello(void *ctx) {
   u64 uid;
   u64 counter = 0;
   u64 *p;

   uid = bpf_get_current_uid_gid() & 0xFFFFFFFF;
   p = counter_table.lookup(&uid);
   if (p != 0) {
      counter = *p;
   }
   counter++;
   counter_table.update(&uid, &counter);
   return 0;
}
```

### eBPF Runtime

eBPF program is compiled into bytecode for the eBPF software virtual machine. If we use clang for compilation, the target should be `-march=bpf`. The BPF syscall verifies the program and loads it into the kernel. After loading into the kernel, the program needs to be attached to the event. More syscalls are used to get the information of eBPF maps into user-space.

![eBPF Syscalls](/assets/img/2024-01-25-1.jpg)

### Usage of bpftool

Instead of using BCC framework, `bpftool` also provides the control for eBPF programs. Functionalities include:

- List all the eBPF programs loaded into the kernel.
- Attach events to eBPF programs.
- Inspect the bytecodes of eBPF programs.
- Read the eBPF maps.
- Update the contents in eBPF naps.

### XDP with eBPF

eXpress Data Path allows running eBPF programs on the network interface card/ driver. However, only some NICs/ drivers support XDP.

In the program below, the `SEC` macro defines the attachment point. As an XDP program, it will be attached to a network interface and triggered whenever an inbound packet is received on that interface. This program counts the number of packets and passes the packets (instead of dropping) to the network stack afterwards.

```c
#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>

int counter = 0;

SEC("xdp")
int hello(struct xdp_md *ctx) {
    bpf_printk("Hello World %d", counter);
    counter++; 
    return XDP_PASS;
}

char LICENSE[] SEC("license") = "Dual BSD/GPL";
```

After compiling with clang, this command loads the eBPF program into the kernel and pin it to the filesystem.

```
bpftool prog load hello.bpf.o /sys/fs/bpf/hello
```

This command attaches the eBPF program to the loopback network interface.

```
bpftool net attach xdp name hello dev lo
```

Note that aside from XDP, the interception of network packets with eBPF can be done at higher levels of the network stack.
