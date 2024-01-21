---
layout: post
title: "Learning Points: Snowflake Iceberg, Streaming, Unistore"
date: 2024-01-21 10:20:00 +0800
category: [Tech]
tags: [Data-Engineering, System-Design, Learning-Points]
---

This [video](https://youtu.be/Kr-Vzvkyabw?si=uo_ZV4IpUHhE9MJU) is about Snowflake Iceberg Tables, Streaming Ingest and Unistore. The presenters are N.Single, T.Jones and A.Motivala as part of the Database Seminar Series by CMU Database Group.
  
### Problems with Traditional Data Lakes

Traditional data lakes use file systems as the metadata layer. For example, data for each table is organized in a directory. Partitioning is implemented through nested directories. Using directories as database tables cause problems.

- Not easy to provide ACID guarantees. Multiple partition inserts were not atomic.
- Tools may directly access the file systems without consistent metadata updates.
- Schema evolution was very error prone.
- No clear way for access control.

### Apache Iceberg

- Describes how to perform updates to the table.
- Specification to achieve snapshot isolation. File memberships are defined to a snapshot.
- Easier schema evolution with Iceberg metadata.

### Snowflake Architecture

Table metadata and data are stored as Parquet files on customers' bucket.

```
                 +-------------------------------------------------+
  Cloud services | Authentication and Authorization                |
                 +-------------------------------------------------+
                 | Infra Manager | Optimizer | Transaction Manager |
                 +-------------------------------------------------+
                 | Metadata Storage (Customer's Bucket)            |
                 +-------------------------------------------------+

                 +-------------------+ +-------------------+
  Compute        | Warehouse         | | Warehouse         |
                 +-------------------+ +-------------------+

                 +-------------------------------------------------+
  Storage        | Data (Customer's Bucket)                        |
                 +-------------------------------------------------+
```

Customers will have to provide Snowflake External Volumes on any the cloud providers with access credentials. Data and metadata files are written to the External Volume.

### Metadata Generation

Snowflake has its own files to store snapshot metadata originally. To support Iceberg format, each table commit requires generation of both Iceberg metadata and internal Snowflake metadata.

The generation of additional metadata files (Iceberg) increases query latency significantly. Thus Iceberg metadata files are generated on the background at the same time.

When Snowflake metadata files are generated, the transaction is considered commited. If the server crashes before Iceberg metadata is generated, the request would come to the new Snowflake server and the Iceberg metadata will be generated on the fly.

### How Spark Accesses Iceberg

The Iceberg SDK accesses a catalog which returns the location of metadata files in customers' buckets. Then the SDK interprets the metadata files and returns the locations of data files in an API to Spark.

```
Spark ---> Iceberg SDK ---> 1. Catalog (Hive, Glue)
  |            |
  |            -----------> 2. Storage (Snapshot Metadata)
  |            
  ------------> 3. Data Files
```

### Snowpipe Streaming

Before this feature, the original Snowpipe did continuous copying from a bucket to a table behind the scenes, in batches. However, there was no low latency, high throughput, in-order processing feature. Snowpipe Streaming provides:

- Ingestion to tables over HTTPs.
- Exactly once (?) and per-channel ordering guarantees.
- Low latency, queryable after seconds.
- High throughput, GB/s supported.
- Low overhead for configuration.

New concepts include:

- Channel - Logical partition that represents a connection from a single client to a destination table.
- Client SDK - Accepts bytes from application, writes data to cloud storage as blobs and registers them to Snowflake.
- Mixed table - Contains both BDEC (Chunks of Arrow format) that is written by the client SDK and Snowflake's propriatory FDN format. In the background, the BDEC files are rewritten into FDN format. The rewriting process is transparent to the users as queries can be done on the mixture of BDEC and FDN files. However, the rewriting process implies additional compute which will be charged to the customer.

The implementation details:

- User code uses the Snowpipe Streaming Client SDK to open a Channel and write rows in the Channel.
- Client SDK writes BDEC files to the Streaming Ingest's internal storage (Blobstore). Note that FDN files exist in the same Blobstore.
- Client SDK registers the blob via REST API to Snowflake's Frontend node.
- Frontend node fans out per-table registration requests to the Snowflake's Commit Service and provides a progress update to the client SDK.
- The Commit Service validates and deduplicates chunks per-table in memory. Then it commits by changing table version references to the new Arrow chunks (BDEC).
- Snowpipe creates regular FDN files from BDEC files. At this point, queries would reflect the newly added data in BDEC files.

### Unistore

Snowflake's product for combining transactional and analytical workload on one platform.

A new table type that works with existing snowflake tables, supports transactional features such as unique keys, referential integrity constraints and cross domain transactions.

```
CREATE HYBRID TABLE CustomerTable {
  customer_id int primary key,
  full_name varchar(256),
  ...
}
```
