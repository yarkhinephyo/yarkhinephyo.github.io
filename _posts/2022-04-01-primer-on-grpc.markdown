---
layout: post
title: "Why gRPC Was Invented and Its Pros and Cons"
date: 2022-04-01 11:13:41 +0800
category: [Tech]
tags: [Networking, Software-Engineering]
---

For a client to communicate with a server with a communication protocol, we need a client library. It can be of any type such as REST/SOAP but at the very least, we need something that understands the protocol. For example in HTTP, a client library needs to understand ALPN and establish TLS connection. There are many client libraries for each language and they are difficult to maintain. For example in Python, the application developers can simply `import requests` but the library itself still requires maintainence in the background. If the client libraries are no longer maintained actively to keep up with new protocols, there will be many problems for projects that depend on them.

### gRPC

Google introduced it to unify the client libraries. Google will build and maintain the client libraries for popular languages while "hiding" the communication protocols from the developers. This is so that if the maintainer of the gRPC project decides to the change the underlying protocols, projects depending on the client libraries will still continue to work. 😲

### Benefits

<ins>Protobuf payload</ins>: The common client-server communication in the web is JSON-over-REST. Even though JSON is flexible and human-readable, there is no data compression which means that payload size is not optimal for transmission over the network. Protocol buffer is the message format in gRPC. It solves the problems with JSON by applying data compression on the payload before sending over the network. Protocol buffer also provides type safety as schemas are encoded along with the data to ensure that signals do not get lose between applications. Validation in JSON has to be done at code level, but it is automatically done during encoding and decoding for protobuf.

{% highlight protobuf %}
message SearchRequest {
  string query = 1;
  int32 page_number = 2;
  int32 result_per_page = 3;
  enum Corpus {
    UNIVERSAL = 0;
    WEB = 1;
    IMAGES = 2;
    LOCAL = 3;
  }
  Corpus corpus = 4;
}
{% endhighlight %}

<ins>HTTP/2</ins>: The current gRPC implementation utilizes HTTP/2 as the underlying mechanism which provides multiple streams along a single TCP connection. This solves the head-of-line blocking issue of HTTP/1.1 thus packets will generally be transport faster. With the multiplexing mechanism of HTTP/2, gRPC also allows cancellation of requests. Unlike REST APIs, cancellation of request can propagate to the server to reduce any unnecessary workload.

![HTTP/2](/assets/img/2022-04-01-1.jpg)
_Image taken from wallarm.com_

<ins>Various communication modes</ins>: Unlike traditional REST APIs, gRPC provides multiple modes of communications. Unary RPC sends a single request to get a single response. Server streaming RPC returns a stream of messages in response to a client request. Client streaming RPC sends a stream of messages to the server for a single response. Bidirectional streaming RPC provides two independent streams for the client and server to stream messages.

![gRPC modes](/assets/img/2022-04-01-2.jpg)
_Image taken from ionos.com_

### What gRPC cannot solve

<ins>Lack of browser support</ins>: Not all browsers support HTTP/2. Thus gRPC may be more viable for communications between microservices as compared to browser-server.

<ins>Unreadability of protocol buffers</ins>: As the protocol buffer is a binary format, data is not human-readable unlike JSON/XML. Developers require additional tools to perform debugging.

<ins>Lack of developer tooling</ins>: Most developer tools are still designed for HTTP/1.1.

### Resources

1. [Hussein's gRPC crash course](https://www.youtube.com/watch?v=Yw4rkaTc0f8)
2. [HEVO gRPC vs REST](https://hevodata.com/learn/grpc-vs-rest-apis/#D2)
3. [sConnector's Blog](https://sconnector.dev/blog/in-depth-comparison-of-grpc-quic/)
4. [gRPC documentation](https://grpc.io/docs/what-is-grpc/core-concepts/)