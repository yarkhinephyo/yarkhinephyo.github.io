---
layout: post
title: "Learning Points: Hashicorp Vault"
date: 2024-01-30 12:20:00 +0800
category: [Tech]
tags: [System-Design, Learning-Points]
---

In this [video](https://youtu.be/GG2LHHERL6Q?si=i-kstaXO6RE0dYZT), Rob Barnes, a developer advocate from Hashicorp, talks about the services provided by Hashicorp Vault.

### Overview

Vault handles machine-to-machine authentication and authorization.

- Secret management platform - Platform to store credentials.
- Identity broker - Brokers identity on behalf of other platforms and databases.
- Encryption as a service - Cryptographic solutions to manage own keys or government's keys.

Vault's fundamental abstraction is the idea of secrets engines. Secrets engines are different Vault components which store, generate or encrypt secrets. The client has to specify with filesystem-like identifiers to select the secret engine to use.

### Engine Type 1: KV Secrets

The client provides a secret to Vault API. Vault encrypts the secret and stores in a storage backend. If the storage is breached, the secrets remain safe. The applications have to retrieve the secrets through Vault. Vault can also rotate secrets by using a new key for new secrets and re-encrypting the old secrets in storage.

In the second version of KV engine, a number of secret versions are retained. this enables the older versions to be retrievable in case of unwanted deletion or updates.

### Engine Type 2: Dynamic Secrets

With dynamic secrets, Vault generates credentials for a particular database or platform only when the client wants to access it. There are no long-living secrets to be stolen outside of Vault. Imagine that a sample application, there exists a profile API that requires access to a Postgres database.

- The application authenticates to Vault via methods such as such as OIDC/JWT, Okta, Github etc.
- Once authenticated, Vault creates new secrets on the target platform with a short-lived TTL. For example, a new user and password are created on the Postgres database.
- Vault returns a Vault-token which includes authorization details such as which Vault APIs are usable.
- The application requests for the database credentials with the token.
- When the TTL is up, Vault revokes the database credentials.

### Engine Type 3: Encryption Service

The burden of encryption and decryption with specific cryptographic protocols is moved from the application developers to Vault.

- The application sends base64 encoded data to the encryption service by Vault.
- Vault encrypts the data, appends the encryption versioning and returns the encrypted data.
- The application stores the encrypted data in Vault or another database. Note that Vault does not act as a proxy in this case.

### Vault as a Service

Hashicorp cloud platform provides this service in a virtual network via peer connection with the application's virtual network. For example with peering in Azure, the network traffic stays within the Microsoft backbone infrastructure.

### Credential Lifetime

The TTL depends on the configuration by the administrator. With longer TTLs, one pattern is to have the application cache the credentials from Vault to avoid refetching every API call.
