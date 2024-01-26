---
layout: post
title: "Learning Points: Linux Performance Tools"
date: 2024-01-26 16:00:00 +0800
category: [Tech]
tags: [Operating-System, Learning-Points]
---

This [video](https://youtu.be/FJW8nGV4jxY?si=XBbqHBf_aPIhKfaW) talks about some monitoring performance tools in Linux. The presenter is Brendan Gregg from Netflix.

### Basic Observability Tools

`top` measures the system and per-process interval summary. Since the screen refreshes in intervals, `top` can miss short lived processes that starts and dies quickly. `top` can also consume noticeable CPU to read /proc.

Load averages measure the resource demand for CPUs + disks in Linux. Time constants of 1, 5 and 15 minutes are used. If there is an increasing order, it means the resources are becoming busier.

For CPU, the usage percentages are shown for user-processes, system-processes, nice-configured-processes, idle-time, wait-time-IO, hardware-interrupt-time, software-interrupt-time, wait-time-cpu. The idle-time, wait-time-IO and wait-time-CPU can help to identify overworked systems.

For the physical memory, buff/cache means the sum of buffers to be written and in-cache memory for files being read. Therefore, this memory can be used for other purposes after flushing and evicting respectively.

```
top - 01:39:09 up 21:32,  6 users,  load average: 0.25, 0.24, 0.21
Tasks: 572 total,   1 running, 571 sleeping,   0 stopped,   0 zombie
%Cpu(s):  0.2 us,  0.2 sy,  0.0 ni, 99.5 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
MiB Mem :  24061.0 total,  11254.0 free,   1744.2 used,  11062.8 buff/cache
MiB Swap:   8192.0 total,   8192.0 free,      0.0 used.  21854.5 avail Mem 

    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND                     
      1 root      20   0  168444  13992   8352 S   2.3   0.1  25:10.61 systemd                     
   1048 message+  20   0   13904   9408   4240 S   0.7   0.0   5:22.55 dbus-daemon                 
 366923 kyar      20   0   13932   4596   3468 R   0.7   0.0   0:00.14 top                         
     15 root      20   0       0      0      0 I   0.3   0.0   0:38.36 rcu_sched                   
    557 root      19  -1  218160 121180 117880 S   0.3   0.5   3:54.25 systemd-journal             
    954 root      20   0       0      0      0 S   0.3   0.0   0:51.03 kcs-evdefer/1  
```

`ps -ef f` can shows processes with trees for relationships.

```
UID          PID    PPID  C STIME TTY      STAT   TIME CMD
root           2       0  0 Jan25 ?        S      0:00 [kthreadd]
root           3       2  0 Jan25 ?        I<     0:00  \_ [rcu_gp]
root           4       2  0 Jan25 ?        I<     0:00  \_ [rcu_par_gp]
root           5       2  0 Jan25 ?        I<     0:00  \_ [slub_flushwq]
  ...
```

`vmstat --unit MiB` shows virtual memory statistics. Unlike `top`, we can see the separate memory for buffered writes and memory for cached reads. Under IO, there are the numbers of blocks received and sent (per second) from devices. Under system, there are the numbers of interrupts and context switches per second.

```
procs -----------memory---------- ---swap-- -----io---- -system-- ------cpu-----
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
 0  0      0  11278    485  10637    0    0     1    17   14   13  0  1 99  0  0
```

`iostat` shows the throughputs for each device. Overworked disks can be identified.

```
Device             tps    kB_read/s    kB_wrtn/s    kB_dscd/s    kB_read    kB_wrtn    kB_dscd
loop0             0.00         0.02         0.00         0.00       1782          0          0
loop1             0.01         0.02         0.00         0.00       1868          0          0
  ...
sda              36.94        20.61       263.88         0.00    1669285   21370268          0
sr0               0.00         0.00         0.00         0.00          1          0          0
```

`mpstat` shows multi-processor statistics to look for hot CPUs.

```
02:16:23 AM  CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
02:16:23 AM  all    0.21    0.18    0.54    0.21    0.00    0.00    0.00    0.00    0.00   98.86
02:16:23 AM    0    0.18    0.26    0.50    0.23    0.00    0.01    0.00    0.00    0.00   98.82
02:16:23 AM    1    0.27    0.22    0.68    0.09    0.00    0.01    0.00    0.00    0.00   98.74
02:16:23 AM    2    0.20    0.20    0.51    0.27    0.00    0.00    0.00    0.00    0.00   98.81
  ...
```

### System Call Tracer (strace)

Translate system call arguments for better observability. However, it has a massive overhead and can slow the target by > 100 times. Use the `-p` flag to attach to a process.

### Network Protocol Statistics (netstat)

`netstat` shows various network protocol statistics.

Side note: Unlike internet sockets, unix domain sockets are already reliable and in-order. Unix stream sockets allow reading arbitrary number of bytes. Unix datagrams maintain message boundaries. 

```
Active Internet connections (w/o servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State      
tcp        0      0 nurseshark.ics.cs.c:ssh c-73-154-235-112.:54352 ESTABLISHED
tcp        0      0 nurseshark.ics.cs.c:ssh c-73-154-235-112.:54101 ESTABLISHED
tcp        0    169 nurseshark.ics.cs:60726 LDAP-06.ANDREW.CM:ldaps ESTABLISHED
  ...
udp        0      0 localhost:41669         localhost:41669         ESTABLISHED
Active UNIX domain sockets (w/o servers)
Proto RefCnt Flags       Type       State         I-Node   Path
unix  2      [ ]         DGRAM                    57742    /var/spool/postfix/dev/log
unix  2      [ ]         DGRAM                    35609    @fcm_clif
unix  2      [ ]         DGRAM                    19606476 /run/user/2690276/systemd/notify
unix  16     [ ]         DGRAM      CONNECTED     21547    /run/systemd/journal/socket
unix  3      [ ]         STREAM     CONNECTED     19592750 /run/user/2707326/bus
unix  3      [ ]         STREAM     CONNECTED     18231599 /run/systemd/journal/stdout
  ...
```

`netstat -rn` shows the routing table. Gateway 0.0.0.0 means that there is no intermediate hop.

```
Kernel IP routing table
Destination     Gateway         Genmask         Flags   MSS Window  irtt Iface
0.0.0.0         128.2.220.1     0.0.0.0         UG        0 0          0 eno1
128.2.1.10      128.2.220.1     255.255.255.255 UGH       0 0          0 eno1
128.2.1.11      128.2.220.1     255.255.255.255 UGH       0 0          0 eno1
128.2.1.20      128.2.220.1     255.255.255.255 UGH       0 0          0 eno1
128.2.1.21      128.2.220.1     255.255.255.255 UGH       0 0          0 eno1
  ...
128.2.220.0     0.0.0.0         255.255.254.0   U         0 0          0 eno1
128.2.220.1     0.0.0.0         255.255.255.255 UH        0 0          0 eno1
192.168.122.0   0.0.0.0         255.255.255.0   U         0 0          0 virbr0
```

`ip route get` gets a single route to a destination and prints its contents exactly as the kernel sees it. In the example, the packet travels from the current machine `128.2.220.25` to the gateway. This aligns with the routing table shown above.

```
8.8.8.8 via 128.2.220.1 dev eno1 src 128.2.220.25 uid 2690276 
```

Note that the loopback address is not inside the routing table. It is because there is a higher priority local table that is consulted at `ip route show table local`. So packets addressed to `127.0.0.1` or `128.2.220.25` will go to the local machine.

```
local 127.0.0.0/8 dev lo proto kernel scope host src 127.0.0.1 
local 127.0.0.1 dev lo proto kernel scope host src 127.0.0.1 
broadcast 127.255.255.255 dev lo proto kernel scope link src 127.0.0.1 
local 128.2.220.25 dev eno1 proto kernel scope host src 128.2.220.25 
broadcast 128.2.221.255 dev eno1 proto kernel scope link src 128.2.220.25 
  ...
```
