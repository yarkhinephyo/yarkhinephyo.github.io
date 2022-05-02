---
layout: post
title: "Solving HTTP/1 Problems With HTTP/2"
date: 2022-05-02 11:09:00 +0800
category: [Tech]
tags: [Software-Engineering, Networking]
---

HTTP/2 has made our applications faster and more robust by providing protocol enhancements over HTTP/1. This post only focuses on the major pain points of HTTP/1 and how the new protocol has been engineered to overcome them. It is assumed that the reader is familiar with how HTTP/1 works.

### Problems with HTTP/1

<ins>Head-of-line blocking</ins>: Browsers typically only allow 6 parallel TCP connections per domain. If the initial requests are not complete, the subsequent requests will be blocked. 

<ins>Unnecessary resource utilization</ins>: With HTTP/1, a single connection is created for every request, even if multiple requests are directed to the same server. As the server has to maintain states for each connection, there is an inefficient utilization of resources.

<ins>Overhead of headers</ins>: Headers in HTTP/1 are in the human-readable text format instead of being encoded to be more space-efficient. As there are numerous headers in complex HTTP requests and responses, it can become a significant overhead.

### Binary Framing "Layer"

In HTTP/2, there is a <ins>binary framing layer</ins> that exists between the original HTTP API exposed to the applications and the transport layer. The rest of TCP/IP stack is unaffected. As long as both client and server implements HTTP/2, the applications will also continue to function as usual.

![](/assets/img/2022-05-02-1.jpg)

### Request and response multiplexing

In HTTP/1, each HTTP request creates a separate TCP connection as shown below.

```
| - Application - | - Transport - |

     request_1  -->  connection_1
     request_2  -->  connection_2
```

In HTTP/2, the binary framing layer breaks down each request into units called <ins>frames</ins>. These frames are interleaved and sent to the transport layer as application data. The transport layer is oblivious to the process and carries on with its own responsibilities. At the server's end, the binary framing layer reconstruct the requests from the frames.

```
| - Application ---------------- | - Transport - |
                | Binary Framing |

     request_1  --->  frames   --->  connection_1
     request_2  -/  
```

### HTTP/2 Frames

To be specific, each HTTP request is broken down into `HEADERS` frame and `DATA` frame/s. The names are self-explanatory. `HEADERS` frame include HTTP headers and `DATA` frame/s include the body.

The diagram below shows the structure of a _frame_.

```
+-----------------------------------------------+
|                 Length (24)                   |
+---------------+---------------+---------------+
|   Type (8)    |   Flags (8)   |
+-+-------------+---------------+-------------------------------+
|R|                 Stream Identifier (31)                      |
+=+=============================================================+
|                   Frame Payload (0...)                      ...
+---------------------------------------------------------------+
```

### HTTP/2 Streams

Notice that each HTTP/2 frame has an associated <ins>stream identifier</ins> which identifies each bidirectional flow of bytes. For example, all the frames in a single request-response exchange will have the same stream identifier.

This means that when frames from different requests are interleaved with one another, the receiving binary framing layer can reconstruct them back into independent <ins>streams</ins>.

![](/assets/img/2022-05-02-2.jpg)
_Interleaving frames with different stream identifiers_

In other words, the hierarchical relationship between _connection_, _stream_ and _frame_ can be represented as shown below.

![](/assets/img/2022-05-02-3.jpg)
_Logical relationship between frames and streams_

### Header compression

Aside from multiplexing HTTP requests over a single TCP connection, HTTP/2 also provides a mechanism for header compression. Instead of transporting textual data, both server and client maintain identical <ins>lookup tables</ins> to remember the headers that have been used. In the subsequent communication, only the pointers into the lookup table are sent over the network. Tests have show that on average, the header size is reduced around 85%-88%.

### Limitation

HTTP/2 solves the head-of-line blocking problem from parallel TCP connections. However, this creates another problem at the TCP level. Due to the nature of TCP implementation, one lost packet can make all the streams wait until the packet is re-transmitted and received.

HTTP/3 addresses this issue by communicating over QUIC (TCP-like protocol over UDP) instead of TCP.

### Resources

1. [A Brief History of SPDY and HTTP/2 by Ilya and Surma](https://web.dev/performance-http2/#a-brief-history-of-spdy-and-http2)
2. [HTTP2 by High Performance Browser Networking](https://hpbn.co/http2/)
