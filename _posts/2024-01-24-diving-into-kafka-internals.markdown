---
layout: post
title: "Learning Points: Diving into Kafka Internals"
date: 2024-01-24 18:50:00 +0800
category: [Tech]
tags: [System-Design, Learning-Points]
---

This [video](https://youtu.be/d89W_GzWnRw?si=CbQtaafPfeyiGBZT) is a deep dive on Apache Kafka's internals with David Jacot from Confluent. Related to the topic, this [article](https://www.confluent.io/blog/why-replace-zookeeper-with-kafka-raft-the-log-of-all-logs/) by Confluent talks about why Zookeeper was replaced with KRaft in Kafka.

### High Level Overview of Kafka

Kafka contains a few components.

- Kafka cluster: Pub-sub messaging system. Users publish and consume via APIs. Events are persisted and replicated in brokers.
- Low level APIs: Producer and consumer APIs to interact with Kafka clusters.
- Connect API: Connectors are built out of the shelf to integrate third party systems with Kafka.

### Old Metadata on Zookeeper

There are two architectures. There is an ongoing effort to migrate from Zookeeper to KRaft.

In the old architecture, Zookeeper elects one controller node as the metadata store and the rest of the broker pool stores data for persistence. The producer and consumer APIs interact with the broker pool.

```
+-----------------------------------+
| Zookeeper | Zookeeper | Zookeeper |
+-----------------------------------+
                  |
                  v
              Controller
            /     |      \
        Broker  Broker  Broker
```

There are limitations with this.

- Broker shutdown: If a broker shuts down, the topic partitions that it acts as a leader will have to be reassigned to a new leader. The controller has to update the metadata in Zookeeper and also propagates to all the brokers. This operation is proportional to the number of brokers.
- Controller failover: If the old controller crashes, the other brokers will try to register with Zookeeper. The new controller has to fetch metadata from Zookeeper which is proportional to the number of topic partitions in the cluster. During this bootstrap, the controller cannot handle any administrative requests.

### New Metadata on KRaft


```
     Voter ---- Leader ---- Voter  (Also brokers)

            [Metadata Log]
            /     |      \
        Broker  Broker  Broker
```

Instead of storing metadata in Zookeeper, the metadata is stored as transaction logs in Kafka. The log is managed by a leader and voters in a quorum. The other brokers passively read the log to catch up. Since the replication is done on changelogs, there is no need to worry about divergence by the other brokers.

The normal data log replications use primary-backup replication where the leader only considers something committed after all the followers acknowledge a write. The transaction log uses quorum replication where the leader considers a commit after the majority of replicas acknowledges a write. This trades away availability guarantees for better replication latencies.

When there is a broker failover, the metadata log is appended within the leader-voter quorum before being replicated by the other brokers. There is no more bottleneck from having a single controller updating all the other brokers. When there is a controller failover, one of the voters will takeover and it will already have the replicated data.

KRaft follows the Raft algorithm to achieve quorum replication while piggybacking on Kafkfa's existing log utilities such as throttling and compression.

### Topics vs Partitions

Topic is a set of partitions grouped together within the business context. Partitions are distributed in a cluster and every broker is responsible for a subset of them as a leader. The followers replicate the data for durability.

### Write Path

- Producer uses an API to write to a given topic.
- If a key exists, it is hashed to determine the partition. If not, a hash is created.
- The network layer writes a Produce Request sends to the leader of the partition.
- The leader does validations and appends the message to its local log in the disk.
- The leader waits until all the followers are done replicating before sending back the Produce Response.

The leaders store a watermark which is the minimum offsets replicated by all the followers. This number is used to decide when to send the Produce Response to the producer. The followers pull from the leader and update their own offsets asynchronously.

There is configuration to control the replication consistency (strong vs eventual). It can be set such that the leader responds back to the producer without any followers acknowledging.

Duplicate data can be written if replication is done but the Produce Response does not reach the producer (which retries). This is why using idempotency operations is important.

Every broker knows the metadata about the cluster such as where the partitions are. The producer refreshes this periodically and assumes it is correct instead of re-checking every Produce Request. On timeout or error, the producer will refresh again.

### Fetch Path

Kafka uses a pull model where consumers pull data from the brokers. This means there is no need for brokers to track where the consumers are, which reduces complexity. Consumers also track how far the data has been fetched.

Consumer Group Protocol makes sure that in each group, consumers can process more than one partition but partitions can be access by only one consumer. This allows for parallel processing of data in those topics, without reading the same data twice.

- Every consumer sends Join Group Request to the Group Coordinator (a broker).
- The Group Coordinator elects a leader from one of the consumers.
- The group leader assigns partitions to the consumers.
- Other consumers starts from the latest offsets (the offstes can be committed into the brokers via API).

The Group Coordinator manages the group membership and initiates the rebalance activity if consumers stops heartbeats. The Group Leader is only responsible for assignment of partitions but this process happens frequently so the offload of works means less CPU usage for Kafka brokers.

### Optimization: Number of Partitions

- Key-based partition: The same key goes into a single partition. From the consumer side, there will be data with the same key in the original order. However, this means that re-partitioning cannot be done. Then it will make sense to over-partition at the beginning.
- Random hash partition: The messages are placed randomly. There will not be a problem to increase the number of partitions in the future.

Currently, there is no way to dynamically change the number of partitions while preserving the ordering.

Make sure there are more partitions than the number of consumers.
