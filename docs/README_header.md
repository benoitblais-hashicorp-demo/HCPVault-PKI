# Vault PKI Demo

This Terraform module provisions a Vault PKI environment designed for strong certificate authority separation. It creates a reusable demo namespace with dedicated child namespaces for an offline-style root CA and an online intermediate CA, then configures issuance so end-entity certificates are generated only from the intermediate. The repository is intended to demonstrate a production-aligned PKI pattern in Vault while keeping the deployment repeatable for multiple concurrent demos.

## What This Demo Demonstrates

- How to isolate certificate operations in a child namespace
- How to issue certificates from an intermediate CA instead of directly from a root CA
- How to use existing Vault authentication and attach a least-privilege PKI policy

## Demo Components

- Child namespace (`vault_namespace`)
- Root child namespace (`vault_namespace`)
- Intermediate child namespace (`vault_namespace`)
- Root PKI mount (`vault_mount`)
- Intermediate PKI mount (`vault_mount`)
- Internal root CA (`vault_pki_secret_backend_root_cert`)
- Intermediate CSR (`vault_pki_secret_backend_intermediate_cert_request`)
- Intermediate signing and import (`vault_pki_secret_backend_root_sign_intermediate`, `vault_pki_secret_backend_intermediate_set_signed`)
- Optional AIA/CRL URL configuration (`vault_pki_secret_backend_config_urls`)
- PKI role for issuance (`vault_pki_secret_backend_role`)

## Permissions

### Vault

The principal used by Terraform (token or dynamic credentials) must be able to:

- Manage namespaces (create/read)
- Manage policies in the target namespace
- Manage mounts in the target namespace
- Manage PKI resources in the target namespace
- Read existing auth method and identity data if needed for policy attachment workflows

## Authentications

Authentication to Vault can be configured using one of the following methods:

### Static Token

Use environment variables to authenticate with a static Vault token:

- `VAULT_ADDR`: Set to your HCP Vault Dedicated cluster address (e.g., `https://my-cluster.vault.hashicorp.cloud:8200`).
- `VAULT_TOKEN`: Set to a valid Vault token with the permissions listed above.
- `VAULT_NAMESPACE`: Set to the parent namespace (e.g., `admin`) if applicable.

### HCP Terraform Dynamic Credentials (Recommended)

For enhanced security, use HCP Terraform's dynamic provider credentials to authenticate to Vault without storing static tokens.
This method uses workload identity (JWT/OIDC) to generate short-lived Vault tokens automatically.

- `TFC_VAULT_PROVIDER_AUTH`: Set to `true`.
- `TFC_VAULT_ADDR`: Set to your HCP Vault Dedicated cluster address.
- `TFC_VAULT_NAMESPACE`: Set to the parent namespace.
- `TFC_VAULT_RUN_ROLE`: Set to the JWT role name configured in Vault.

Documentation:

- [HCP Terraform Dynamic Credentials](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials)
- [Vault JWT Auth Method](https://developer.hashicorp.com/vault/docs/auth/jwt)

## Features

- Namespace-scoped PKI demo infrastructure
- Dedicated root and intermediate child namespaces under one demo namespace
- Root/intermediate CA hierarchy for PKI best practice
- Policy-limited certificate issuance path (`pki-int/issue/<role>`)
- Opinionated defaults with variables for domain, role name, and TTLs

## Demo Value Proposition

This module gives a fast, repeatable demo where operators use existing Vault authentication, while certificate issuance follows the recommended root/intermediate hierarchy with least-privilege controls and namespace isolation.
