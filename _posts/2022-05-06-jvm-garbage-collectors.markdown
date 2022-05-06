---
layout: post
title: "JVM Garbage Collectors - Serial, Parallel, CMS"
date: 2022-05-06 17:00:00 +0800
category: [Tech]
tags: [Software-Engineering, Java]
---

Depending on the resources available and the performance metric of an application, different Garbage Collectors (GC) should be considered for the underlying Java Virtual Machine. This post explains the main idea behind the garbage collection process in JVM and summarizes the pros and cons of Serial GC, Parallel GC and Concurrent-Mark-Sweep GC. 

[Garbage-First GC](https://plumbr.io/handbook/garbage-collection-algorithms-implementations#g1) (G1) is out-of-scope for this post as it works very differently from the other algorithms (and I still have not wrap my head around it). This post also assumes familiarity with heap memory.

### Garbage Collection Algorithms

These symbols will be used to illustrate the memory allocation in heap.

``` 
o       - unvisited
x       - visited
<empty> - free
```

<ins>Mark-Sweep</ins>: The objects in the heap that can be reached from root nodes (such as stack references) are marked as _visited_. While sweeping the memory, the regions occupied by the _unvisited_ objects are updated to be _free_. As there are likely to be less contiguous regions after a collection, external fragmentation is likely to occur.

```
Marked     | x |o| x |  o  |x|
Sweeped    | x | | x |     |x|
```

<ins>Mark-Sweep-Compact</ins>: After marking, the _visited_ objects are identified and compacted to the beginning of the memory region. This solves the external fragmentation issue, but more time is required as objects have to be moved and references have to be updated accordingly.

``` 
Marked     | x |o| x |  o  |x|
Sweeped    | x | | x |     |x|
Compacted  | x | x |x|       |
```

<ins>Mark-Copy</ins>: After marking, the _visited_ objects are relocated to another region. This accomplishes compaction of allocated memory at the same step. However, the disadvantage is that there is a need to maintain one more memory region.

``` 
Marked     | x |o| x |  o  |x|                 |
Copied     |                 | x | x |x|       |
```

During parts of a garbage collection, all application threads may be suspended. This is called <ins>stop-the-world</ins> pause. Long pauses are especially undesirable in interactive applications.

### Generational Garbage Collection in JVM

The <ins>Weak Generational Hypothesis</ins> states that most objects die young.

In JVM, heap memory is divided into two regions - Young Generation and Old Generation. Newly created objects are stored in the Young Generation and the older ones are promoted to the Old Generation. With this separation, GC can work more often in a smaller region where dead objects are more likely to be found.

``` 
<- Young Generation ->
+--------------------+--------------------+
|    Eden Space      |                    |
+----------+---------+   Old Generation   |
|    S0    |    S1   |                    |
+----------+---------+--------------------+
```

<ins>Young Generation</ins>: The region is divided into Eden Space where new objects are created, and S0/S1 Space where the _visited_ objects from each garbage collection can be copied to. Naturally, Mark-Copy algorithm is used.

<ins>Old Generation</ins>: As there is no delimited region for the _visited_ objects to be copied to. Only Mark-Sweep and Mark-Sweep-Compact algorithms can be used.

### Serial GC

JVM option: `-XX:+UseSerialGC`

This option uses Mark-Copy for the Young Generation and Mark-Sweep-Compact for the Old Generation. Both of the collectors are single-threaded. Without leveraging multiple cores present in modern processors, the stop-the-world pauses are longer. The advantage is that there is less resource overhead compared to other options.

### Parallel GC

JVM option: `-XX:+UseParallelGC -XX:+UseParallelOldGC`

Similary to Serial GC, this option uses Mark-Copy for the Young Generation and Mark-Sweep-Compact for the Old Generation. Unlike Serial GC, multiple threads are run for the respective algorithms. As less time is spent on garbage collection, there is higher throughput for the application.

### Concurrent-Mark-Sweep (CMS) GC

JVM option: `-XX:+UseParNewGC -XX:+UseConcMarkSweepGC`

For the Young Generation, this option is the same as Parallel GC. For the Old Generation, this option runs most of the job in Mark-Sweep <ins>concurrently</ins> with the application. This means that the application threads continue running during some parts of the garbage collection. Hence this option is less affected by stop-the-world pauses compared to the other two, making it preferred for interactive applications.

As at least one thread is used for garbage collection all the time, the application has lower throughput. Without compaction, external fragmentation may also occur. When this happens, there is a fallback with Serial GC but it is very time-consuming.

### Resources

1. [Java Garbage Collection by Plumbr](https://plumbr.io/handbook/garbage-collection-algorithms-implementations)
2. [Garbage Collection in Java by Ranjith](https://www.youtube.com/watch?v=UnaNQgzw4zY)
