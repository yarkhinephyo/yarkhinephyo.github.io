---
layout: post
title: "Learning Points: Kubernetes Networking Deep Dive"
date: 2024-01-20 11:30:00 +0800
category: [Tech]
tags: [Networking, System-Design, Learning-Points]
---

This [video](https://youtu.be/tq9ng_Nz9j8?si=hv_AtmaoddIL7rBs) is about how networking works in Kubernetes by Bowei Du and Tim Hockin from Google.

### Networking APIs Exposed by Kubernetes

- Service, Endpoint: Service registration and discovery.
- Ingress: L7 HTTP routing.
- Gateway: Next-gen HTTP routing and service ingress.
- NetworkPolicy: Application firewall.

### Pod Networking Model

All pods can reach all other pods across nodes. The network drivers on each node and networking between pods are implemented by Kubelet CNI implementation.

One implementation is using hosts as a router device while a routing entry is added for each pod. For example, Flannel host-gw mode and Calico BGP mode. Another implementation is using overlay networks where layer 2 frames are encapsulated into layer 4 UDP packets alongside a VxLAN header. For example, Flannel and Calico VxLAN mode.

### Service API Implementation

Pod IP addresses are ephemeral. Service API exposes a group of pods via one IP (ClusterIP). This is how the API works:

- A client pod sends a DNS query of to KubeDNS service.
- The KubeProxy sends the query to a KubeDNS pod which returns the ClusterIP.
- The client sends a packet to the ClusterIP.
- The KubeProxy intercepts the packet and sends it to one of the server pods.
- If the server pod goes down, the client can retry with the same ClusterIP.

```
kind: Service
apiVersion: v1
metadata:
  name: my-service
  namespace: default
spec:
  selector:
    app: my-app
  ports:
    - port: 80 # for clients
    - targetPort: 9376 # for backend pods
```

KubeProxy runs on every node in the cluster. It uses iptables, IPVS or userspace options to proxy traffic from pods.

KubeProxy control plane accumulate changes to Endpoints and Services, then updates rules in the node. In the data plane, the sending KubeProxy recognizes ClusterIP/port and rewrites packets to the new destination (DNAT). The recipient KubeProxy un-DNAT the packets.

To disambiguate, CNI ensures the Pod IPs work. KubeProxy redirects ClusterIP to Pod IP before sending over the network.

### Endpoint API Implementation

Endpoint objects are a list of IPs behind a Service. An Endpoint Controller manages them automatically.

When a Service object is created, an Endpoint object is created that has a mapping of service name to pod addresses and ports. This object is fed into the rest of the system such as KubeDNS and KubeProxy.

### Ingress API Implementation

HTTP proxy and L7 routing rules that targets a service for each rule. Kubernetes define the API but implementations are all third party.

Unlike the Ingress API, Service-type load balancers only work at L4 level.

```
Ingress {
  hostname: foo.com
  paths:
  - path: /foo
    service: foo-svc
  - path: /bar
    service: bar-svc
}
```

### Deep Dive: NodeLocal DNS

DNS resource cost is high. There are more microservice addressed by names and more application libraries tending to use DNS names. The solution is to run a DNS cache on every node.

The NodeLocal DNS implementation is deployed on each node as a Daemonset.

Dummy network interface is created that binds to ClusterIP address of KubeDNS. Linux NOTRACK target is added with KubeDNS ClusterIP before any KubeProxy rules. This ensures that NodeLocal DNS can process the packets without them reaching KubeProxy.

A watcher process removes the NOTRACK entries in the event that NodeLocalDNS fails. This defaults back to the original KubeDNS infrastructure.

### Deep Dive: EndpointSlice

Endpoint objects are stored in the Etcd database. When one pod IP changes, the entire object has to be redistributed to all the KubeProxy. If Endpoint objects are large, it may also hit the maximum storage limit in Etcd.

The solution is to represent one original Endpoint object with a set of EndpointSlice objects. A single update to pod IP will only require redistribution of one EndpointSlice object.

The EndpointSlice controller slices from a Service object to create EndpointSlice objects.

Interesting optimization problem:
- Keep number of slices low.
- Minimize changes to slices per update.
- Keep the amount of data sent low.
