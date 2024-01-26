---
layout: post
title: "Learning Points: Large Pages in the Linux Kernel"
date: 2024-01-25 20:00:00 +0800
category: [Tech]
tags: [Operating-System, Learning-Points, Database]
---

This [video](https://youtu.be/hoSpvGxXgNg?si=7KhmP_flQ4LLoYm0) talks about Large Pages in the Linux Kernel. The presenter is Matthew Wilcox from Oracle. Related to the topic, this [article](https://lwn.net/Articles/686690/) by Neil Brown talks about challenges of Transparent Huge Pages in the page cache.

### Background

Memory is managed in pages. An Oracle server with 6TiB of memory has 1.5 billion 4KiB pages. As a NUMA system, it has several nodes with a high performance connection. If a processor accesses memory not in its own node, the data is accessed slower than local memory. Per NUMA-node basis, there are 192 million pages which are tracked with an LRU list.

- A long LRU list is inefficient since there is heavy contention for the lock.
- TLB cache lines also have high misses. Larger page sizes means less entries in TLBs thus less evictions.
- Large page table sizes per process, leading to OOM errors.
- Having many pages means that there is more overhead from the address translation.

### Huge Pages (HugeTLB)

Huge pages are blocks of memory that come in 2MB and 1GB sizes. Huge pages are reserved by the administrators during boot time. They require significant code changes by application developers to be used effectively. For example, mmap can be used with `MAP_HUGETBL` flag to allocate the huge pages that have been reserved.

### Compound Page

A lower level construct for the kernel developers. Linux can allocate pages in 2<sup>n</sup> where n is the order of the page. First page is the head page and all the other pages are tail pages. The operation on tail pages usually redirect to the head page. This construct is used to build other systems such as Transparent Huge Pages.

### Transparent Huge Pages (THP)

THP allocates huge pages while being transparent to the applications. The old THP implementation only works for 2 MiB pages and mapping of anonymous memory. Modern kernels support the new THP which works with variable powers of two (4 KiB, 8 KiB, ...) in page sizes and added support for tmpfs (shared memory). Unlike the standard Huge Pages, THP allocates page sizes dynamically during runtime.

Only some architectures support THP. Sometimes hardware supports larger page sizes, but there is no code in the Linux core. Furthermore, the filesystem authors (besides tmpfs) are unfamiliar with it.

### Folio API

There is also an ambiguity on the original THP API. For example, should the filesystem page-fault handle return the head page of THP or a specific subpage?

Folio API removes the ambiguity. Any Folio function will operate on the full page. The functions only take in base pages or the head of compound pages, and no tail pages.

### Controling Large Pages Sizes

- Hints from userspace have been unreliable in the past.
- In terms of responsibilities, the filesystem authors should not have to develop their own heuristics.
- The page cache readahead already decides how many pages to read ahead, so now it should also decide how large pages should be set to.
- Page fault will allocate PMD-sized (2 MiB) pages if `MADV_HUGEPAGE` is set by user.

### Challenges of THP Support in Filesystems

Anonymous memory is only accessed by memory mapping (mmap) and the size of this mapping is usually fixed on allocation. Sharing between processes only happens as the result of a fork and, for the process-private mappings that support THP, the huge pages will only remain shared as long as they are unchanged. So every mapping of an anonymous transparent huge page will be the same size.

However, in filesystems, memory used for file-backed data can be mapped concurrently by multiple processes. Preventing one process from getting a huge mapping because the other process only mapped small pages is not acceptable. So THP for filesystems must support concurrent mappings for both huge and non-huge pages.

Furthermore, the space in files is not allocated by mapping but by the result of write calls. THP for files must allocate huge pages before the file is known to be big enough to utilize them.

### Huge Pages in Databases

Standard huge pages (HugeTLB) can be beneficial as page table sizes are reduced, leading to less memory usage by the kernel.

However for THP, the dynamic page sizes means that memory allocation by the kernel may be inefficient for the use case of databases. Database systems rely on their own memory management systems, designed to optimize performance based on the application context. THP can conflict with these built-in memory management strategies.
