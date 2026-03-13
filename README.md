# Vault PKI Demo

This Terraform module provisions a child namespace in Vault and configures a complete PKI demo workflow:

- Keeps one reusable demo namespace for parallel demos
- Creates two child namespaces under the demo namespace: root and intermediate
- Enables separate root and intermediate PKI secrets engines
- Generates an internal root CA
- Generates and signs an intermediate CA from the root CA
- Creates a certificate issuance role only on the intermediate CA
- Creates a least-privilege PKI policy to attach to existing Vault identities

Implementation note: the default Vault provider creates namespaces, and PKI resources are explicitly targeted with the `namespace` argument on each resource.

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
- PKI demo policy (`vault_policy`)

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

## Usage

```hcl
module "hcpvault_pki_demo" {
  source = "./"

  namespace_path                   = "pki-demo"
  pki_root_namespace_path          = "pki-root"
  pki_intermediate_namespace_path  = "pki-intermediate"
  pki_allowed_domains              = ["demo.example.com"]
  pki_vault_addr_for_urls = "https://my-cluster.vault.hashicorp.cloud:8200"
}
```

## Demo Walkthrough (Vault UI)

1. Run Terraform:
	- `terraform init`
	- `terraform apply`
2. Open Vault UI and select the child namespace from output `namespace_path`.
3. Login using your already-provisioned auth method and user credentials.
4. Ensure your identity has policy output `demo_policy_name` (or the same policy name configured by `demo_policy_name`) in namespace output `pki_intermediate_namespace_path`.
5. Go to namespace output `pki_intermediate_namespace_path` and open the intermediate PKI engine at output `pki_intermediate_mount_path`.
6. In the PKI engine, issue a certificate using role output `pki_role_name`.
7. Use a CN matching one of `pki_allowed_domains` (or its subdomains).

## Inputs

| Name                            | Description                                                           | Type         | Default                         | Required |
|---------------------------------|-----------------------------------------------------------------------|--------------|---------------------------------|----------|
| demo_policy_name                | Name of the Vault policy for UI certificate issuance demo access.     | `string`     | `"pki-demo-ui-issuer"`         | no       |
| namespace_path                  | Path of the child namespace.                                           | `string`     | `"pki-demo"`                   | no       |
| pki_allowed_domains             | Domains allowed for certificate issuance from the intermediate role.   | `list(string)` | `["demo.example.com"]`      | no       |
| pki_cert_max_ttl                | Maximum TTL for certificates issued by the intermediate PKI role.      | `string`     | `"720h"`                       | no       |
| pki_cert_ttl                    | Default TTL for certificates issued by the intermediate PKI role.      | `string`     | `"72h"`                        | no       |
| pki_intermediate_ca_ttl         | TTL for the intermediate CA certificate signed by the root CA.         | `string`     | `"43800h"`                     | no       |
| pki_intermediate_common_name    | Common Name used for the intermediate CA.                              | `string`     | `"demo.example.com Intermediate CA"` | no |
| pki_intermediate_default_lease_ttl_seconds | Default lease TTL for the intermediate PKI mount in seconds. | `number` | `2592000` | no |
| pki_intermediate_max_lease_ttl_seconds | Maximum lease TTL for the intermediate PKI mount in seconds. | `number` | `157680000` | no |
| pki_intermediate_mount_path     | Path where the intermediate PKI engine is enabled.                     | `string`     | `"pki-int"`                    | no       |
| pki_intermediate_namespace_path | Child namespace name under the demo namespace for intermediate PKI resources. | `string` | `"pki-intermediate"` | no |
| pki_role_name                   | Role name used by the UI to issue certificates from the intermediate PKI engine. | `string` | `"ui-issuer"` | no |
| pki_root_ca_ttl                 | TTL for the self-signed root CA certificate used to sign the intermediate. | `string` | `"87600h"` | no |
| pki_root_common_name            | Common Name used for the root CA in the PKI hierarchy.                 | `string`     | `"demo.example.com Root CA"`   | no       |
| pki_root_default_lease_ttl_seconds | Default lease TTL for the root PKI mount in seconds.               | `number`     | `31536000`                      | no       |
| pki_root_max_lease_ttl_seconds  | Maximum lease TTL for the root PKI mount in seconds.                   | `number`     | `315360000`                     | no       |
| pki_root_mount_path             | Path where the root PKI engine is enabled.                             | `string`     | `"pki-root"`                   | no       |
| pki_root_namespace_path         | Child namespace name under the demo namespace for root PKI resources.  | `string`     | `"pki-root"`                   | no       |
| pki_vault_addr_for_urls         | Vault address used to configure issuing certificate and CRL URLs.      | `string`     | `""`                           | no       |

## Outputs

| Name           | Description                                                     |
|----------------|-----------------------------------------------------------------|
| namespace_path | Child namespace path where the PKI demo resources are deployed. |
| pki_intermediate_mount_path | Path of the intermediate PKI secrets engine in the child namespace. |
| pki_intermediate_namespace_path | Child namespace path under the demo namespace for intermediate PKI resources. |
| pki_role_name  | Role name used to issue certificates from Vault UI.             |
| pki_root_mount_path | Path of the root PKI secrets engine in the child namespace. |
| pki_root_namespace_path | Child namespace path under the demo namespace for root PKI resources. |

## Demo Value Proposition

This module gives a fast, repeatable demo where operators use existing Vault authentication, while certificate issuance follows the recommended root/intermediate hierarchy with least-privilege controls and namespace isolation.

# External Documentation

- [Vault PKI Secrets Engine](https://developer.hashicorp.com/vault/docs/secrets/pki)
- [Vault Policy Concepts](https://developer.hashicorp.com/vault/docs/concepts/policies)
- [Vault Provider (Terraform Registry)](https://registry.terraform.io/providers/hashicorp/vault/latest/docs)
