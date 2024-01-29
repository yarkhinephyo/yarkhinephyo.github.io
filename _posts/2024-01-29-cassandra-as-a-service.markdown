---
layout: post
title: "Learning Points: Cassandra as a Service (AstraDB)"
date: 2024-01-29 14:00:00 +0800
category: [Tech]
tags: [Database, System-Design, Learning-Points]
---

This [video](https://youtu.be/Z5NdkKeqCxA?si=iEpMDAGiIoWCh78M) talks about how Apache Cassandra is restructured for the cloud native environment. The presenter is Jake Luciani, the chief architect from DataStax.

### Cassandra Operational Challenges in Production

- All nodes perform all actions in Cassandra. CPU, memory, disk has to scale at the same amount with the original architecture.
- No isolation between multiple tenants.
- Cassandra clusters run at maximum scale because there is no in-built elasticity.

By 2019, there were Cassandra operators for Kubernetes to make deployments on clouds possible. This works but it does not have the features that other SaaS cloud solutions have.

Requirements for an SaaS Cassandra include:

- Pay for what you use.
- Can scale storage, compute and network up and down independently.
- Integrated with the cloud ecosystem.
- Data can be secured by the users.
- Simple from the operational standpoint for the customers.

### Towards Serverless Cassandra

- Write data into object storage instead of the attached disks. Flushing data from the memtable writes to S3.
- Use Etcd instead of a custom Java service for the cluster metadata such as schema management and topology changes.
- Separate functionalities of Cassandra such as authentication, data serving, data compaction into different services. For example, data compaction is moved to AWS lambda while data serving remains in containers.
- Kubernetes Operators for scaling and upgrades.

```
     requests
         |
         v
coordination service    coordination service  <---
         |         \   /         |               Metadata Service
         v          \ /          v                    (Etcd)
  data service             data service       <---
  (with cache)             (with cache)
         |                       |
         v                       v
        Object Storage (S3, GCS, ABS)
         ^                       ^
         |                       |
  compaction service   commitlog replay service
      (lambda)                (lambda)
```

Benefits include:

- Consistent schema and topology.
- Independently scalable components.
- All pods have access to data without streaming. A new node does not have to stream from other nodes when joining the cluster.
- Local disk is used for predictive caching.
- No need attached disks in Kubernetes. State management is troublesome with PVCs. Coordinator and data services are stateless.
- The backing up of data (replication) is done in S3.

The new architecture allows multi-tenancy. Each tenant is assigned to a single shared-tenancy Kubernetes cluster. Each tenant has a separate bucket in the object storage service for isolation. A given set of nodes can be part of a ring of one or more databases. Each node may process data from multiple tenants but there are isolations in place. This saves compute for Datastax.
