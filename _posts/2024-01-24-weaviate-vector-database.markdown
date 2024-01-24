---
layout: post
title: "Learning Points: Weaviate Vector Database"
date: 2024-01-24 12:20:00 +0800
category: [Tech]
tags: [Database, System-Design, Learning-Points]
---

This [video](https://youtu.be/4sLJapXEPd4?si=iLZ6ejpmIEuyHE6g) is a deep dive on the vector database Weaviate as part of the weekly database seminars by CMU Database Group. The presenter is Etienne Dilocker from Weaviate.

### Why a Vector Database

Instead of indexing literal keywords from paragraphs, meanings (embeddings) can be indexed for search purposes.

LLMs tend to hallucinate less when some context around the question is given.

Retrieval Augmented Generation (RAG) retrieves the top few relevant documents from a vector database before providing as a context to LLMs. There is no need to retrain LLMs to keep updated with the latest information.

### Weaviate Architecture

Collections are logical groups by the user. Shards distribute data across multiple nodes.

In each shard, the HNSW index is used most of the time. The object store can keep any binary files that are related to the embeddings. There is no need to have secondary storage for non-key-value data. The inverted index allows searching by properties and BM25 (bag-of-words retrieval) queries.

```
      +-----------------------+
      | Weaviate Setup        |
      +-----------------------+
  +-- | Collection "Articles" |
  |   | Collection "Authors"  |
  |   | ...                   |
  |   +-----------------------+
  |
  |   +-----------------------+
  +-> | Collection "Articles" |
      +-----------------------+
  +-- | Shard A               |
  |   | Shard B               |
  |   | ...                   |
  |   +-----------------------+
  |
  |   +-----------------------+
  +-> | Shard A               |
      +-----------------------+
      | HNSW Index            |
      | Object Store (LSM)    |
      | Inverted Index (LSM)  |
      +-----------------------+
```

Consistent hashing on a specific key is used for sharding. On each node (physical shard), there can be multiple logical shards.

If the number of shards are changed on the fly, there are measures to ensure that minimal amount of data is moved around the nodes.

### Hierarchical Navigable Small World (HNSW)

The index approximates nearest neighbor proximity graph with multiple layers. Compared to other indexes, it is slower to build but faster to query with.

Algorithm for querying a Navigable Small World (NSW) graph:

- Pick a random entry point.
- Follow all the edges and evaluate if the newly discovered points are closer.
- Recenter on the best known point.
- Don't score any points twice.
- Stop when there is no more improvement.

Considerations when building a NSW graph:

- A real life dataset with natural clusters would be more efficient as compared to randomly generated points.
- The number of connections between each point.
- During the build phase, there is a search on the graph to decide where to place nodes. The more time spent on the build phase, the more efficient the search phase is.

Layers of NSW is HNSW. There are fewer connections per point on higher layers of HNSW. Few connections also means the connections "travel" longer distances. The search starts from the higher layers then move to lower layers.

### Rebuilding NSW

Adding new data points do not degrade the graph. When one point has too many connections, pruning is done by reducing first-grade connections (direct) to second-grade connections (indirect).

Deleting points degrades the query time. When a point is marked as tombstone, it can still be used for traversing the graph but not be included in the result set. When the proportion of tombstones is large, the graph is rebuilt. On the fly, there are also reassignments of the tombstone's connections to other points to make sure clusters remain connected. This operation is expensive but works well if there are not too many deletes.
