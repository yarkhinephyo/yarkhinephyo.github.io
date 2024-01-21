---
layout: post
title: "Learning Points: Streamlining FedRAMP Compliance with CNCF"
date: 2024-01-21 11:55:00 +0800
category: [Tech]
tags: [System-Design, Learning-Points]
---

This [video](https://youtu.be/UlLmHc4PfhM?si=kHiTGCgiTIwzeVxu) is about streamlining FedRAMP compliance with CNCF technologies. The presenters are Ali Monfre and Vlad Ungureanu from Palantir Technologies.

### FedRAMP Overview

FedRAMP is the accreditation required for companies to sell SaaS solutions to the government instead of on-prem solutions. General steps include:

- Identify a sponsor to join the authorization board.
- Document security controls and validate them with third-party assessments.
- Final review with the sponsor and FedRAMP management office.

### Challenges Pre-Kubernetes

- Scanning requirements included vulnerability scans, virus scans, configuration scans. They had to be done weekly or monthly basis. Before Kubernetes adoption, there was no uniform infrastructure or standardized immutable AMIs and container images. Palantir had to scan every single piece of live infrastructure.
- Security patching requirements required constant host reboots. Orchestrating reboot cycles without downtime was a lot of engineering effort.
- FIPS encryption is the government approved standards for cypher suites and cryptographic libraries. It takes a while for newly introduced cypher suites to be FIPS validated. As Palantir relies on open source technology, maintaining FIPS validated traffic between diverse services was a very difficult problem.

### How Palantir Solved

For operating systems, major vendors have STIGs published. Palantir started running immutable machine images which were scanned during the CI process. This provided a faster feedback loop for the developers. Every host was also terminated every 72 hours. One side effect was that the vulnerabilities would be patched within three days.

For container images, an internal "golden image" was used by all products. The downstream images that used this were built automatically. Trivy (a scanning tool) was also embedded into CI.

Regarding FIPS, there is a long processing time for NIST (government agency) to validate new kernels and cryptographic libraries. Thus, Palantir cannot used features offered by new versions of the kernel.

Regarding service-to-service communication, Cilium CNI is used for k8s clusters. IPSec encryption in Cilium ensures FIPS validated encryption between pods. Cilium also has powerful network policy primitives which made it easier to adhere to FedRAMP standards.

Regarding Ingress/ Egress traffic, NGINX+ provides FIPS validation but there were performance problems encountered by Palantir. The decision was made to switched to Envoy, which is an open sourced service proxy designed for cloud native applications. BoringSSL with FIPS configured was used as the TLS provider.

Regarding Host Intrusion Detection System, originally OSQUERY tool was used. However, it did not integrate well with k8s so all the pods showed up as similar processes. The decision was made to switch to Isovalent Tetragon which was an eBPF tool that integrated well with k8s.

### Continuing Challenges

There are more challenges not solved by CNCF technologies out of the box. To solve this, Palantir created Apollo and FedStart which helps companies to deploy software for the federal environment.

- Change Management: Security relevant changes must be approved by authorized US person. Combining compliance checks with other automation tools is challenging. Policy-based rollouts allow CICD while enforcing approvals from the US persons.
- Process Controls: A lot of FedRAMP controls are not technical, but more of procedure-related. Standardized infrastructure provided by Palantir means that the companies can just follow the provided templates for the documentation rather than creating from scratch.
- Vulnerability Management: Palantir manages minimized images to reduce exposures to CVEs.
