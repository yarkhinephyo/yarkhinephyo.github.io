---
layout: post
title: "Learning Points: Containers Under the Hood"
date: 2024-02-02 15:00:00 +0800
category: [Tech]
tags: [Operating-System, Learning-Points]
---

In this [video](https://youtu.be/BM3aH-wultc?si=RTcj8mXG19HxQw2R), Gerlof Langeveld from AT Computing talks about how Linux containers work under the hood. The focus is mostly on the Linux namespaces and not Cgroups.

### Conventional Unix Approach

All processes run in one ecosystem, which includes:

- Hostname.
- PID numbers.
- Mounted filesystems.
- Network stack.
- IPC objects (semaphores, pipes).
- Users.

Even before containers, every process could have its own root directory (chroot) which it is limited to for usage.

If a process assumes the root identity means all the privileged actions are allowed. Non-root identity meant no privileged actions at all.

There were no tools to control resource consumption for each process.

### Containerized Approach

Processes are isolated from other processes in the host. Containers are implemented by administering the root directory, namespaces and control groups of a child process differently from the parent.

- Private filesystem - chroot.
- Isolated hostname - namespace 'uts'.
- Isolated IPC (shmem, semaphores, message queues) - namespace 'ipc'. Processes in the same namespace can share the objects.
- Isolated PID numbering - namespace 'pid'. The process will have different PID in ancestor namespace and its own namespace. Process with PID 1 in any namespace reaps the orphaned children in the namespace. The `/proc` has to be mounted accordingly in the new PID namespace too.
- Isolated users - namespace 'user'.
- Isolated mount - namespace 'mnt'. Processes connected to the same namespace share mountpoints. When a new namespace is created, the mount structure is inherited. However, when there are updates to the mount points, there is no impact on the original namespaces.
- Private network stack - namespace 'net'. A new network namespace initially has only the loopback interface but more can be added. Physical devices can only be in one namespace. Network namespaces can be connected via veth pairs.
- Limited privilege under root identity - capabilities.
- Limited utilization of CPU - cgroup 'cpu'.
- Limited utilization of memory - cgroup 'memory'.
- Limited utilization of disk - cgroup 'blkio'.

### Namespaces

Every process refers to namespaces. When there is a fork, the child processes inherit the binding of namespaces by default. Processes can unshare namespaces.

The namespace details are in the pseudo-filesystem `/proc`. The `$$` refers to the current process. The number in the bracket refers to the inode representing the namespace.

```
$ ls -l /proc/$$/ns
lrwxrwxrwx 1 kyar users 0 Feb  2 02:15 ipc -> 'ipc:[4026531839]'
lrwxrwxrwx 1 kyar users 0 Feb  2 02:15 mnt -> 'mnt:[4026531841]'
lrwxrwxrwx 1 kyar users 0 Feb  2 02:15 net -> 'net:[4026531840]'
lrwxrwxrwx 1 kyar users 0 Feb  2 02:15 pid -> 'pid:[4026531836]'
...
```

The `unshare` command executes a specified program in new namespaces. It uses the system call `unshare`. The `nsenter` command connects with existing namespaces of other processes. It uses the system call `setns`.


### Docker Namespaces

Docker allows sharing of namespaces. For example, `docker run --pid=host` shares the PID namespace with the host and `docker run --pid=container:CID` shares the PID namespace with anothe container.

### Modified Root Directory

Even before containers were prevalent, every process has own root directory. Usually, all the processes inherit the root directory of the entire filesystem from systemd. Use `chroot` to use a prepared directory as root. Use `pivot_root` to change root directory for all processes in the mount namespace.

```
sudo chroot topdir bash --login
```

### Capabilities

Traditional Unix privilege scheme only checks whether UID = 0. Linux privilege scheme has a collection of distinct privileges that can be set for each process. For example: CAP_CHOWN, CAP_KILL, CAP_SYS_BOOT etc. Thread running with effective UID = 0 initially has all the capabilities set.

```
docker run --cap-add foo --cap-drop bar ...
```

### Build a Container Step by Step (Without Cgroups)

In the `step1.sh`, a new hostname namespace is created.


```
#!/bin/bash
unshare -u bash step2.sh
```

In `step2.sh`, the hostname for the child process is changed. Then, `unshare` is run again to create a new PID namespace. The current process' environment is not modified. The forked child process will be in the new namespace with PID 1.

```
hostname mycontainer
unshare -p --fork --mount-proc bash step3.sh
```

In `step3.sh`, a new network namespace is created.

```
unshare -n bash step4.sh
```

In `step4.sh`, the local loopback link is set to up. Then, the script uses `nsenter` to set up veth pairing interface `mybr0` in the parent process's network stack namespace. Then the script sets up `mybr1` device for its own namespace. Now packets transmitted on one device in the pair are immediately received on the other device.

At the end, a new mount namespace is created.

```
ip link set dev lo up

nsenter -n -t 1 ip link add name mybr0 type veth peer name mybr1 netns $$
nsenter -n -t 1 ip addr add 192.168.47.11/24 dev mybr0
nsenter -n -t 1 ip link set dev mybr0 up

ip addr add 192.168.47.12/24 dev my br1
ip link set dev mybr1 up

unshare -m bash step5.sh
```

In `step5.sh`, a new directory for the container's root is created. A tmpfs filesystem (in-memory filesystem) of 50MB is mounted to the new root's directory. This mount point will be not visible within the parent's process. The contents from a skeleton root folder is copied into the mount point. `pivot_root` is used to change the root directory.

```
ROOTDIR=${pwd}/newroot

[ -d ${ROOTDIR} ] || mkdir "$ROOTDIR"
mount -n -t tmpfs -i size=50M none "${ROOTDIR}"
rsync -a skeletonfs/ "${ROOTDIR}"

cd "${ROOTDIR}"

pivot_root . oldroot

mount -t proc proc /proc

export PS1="[\u$\h \W]# "
bash
```