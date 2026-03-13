# Vault PKI Demo

This Terraform module provisions a child namespace in Vault and configures a complete PKI demo workflow:

- Keeps one reusable demo namespace for parallel demos
- Creates two child namespaces under the demo namespace: root and intermediate
- Enables separate root and intermediate PKI secrets engines
- Generates an internal root CA
- Generates and signs an intermediate CA from the root CA
- Creates a certificate issuance role only on the intermediate CA
- Creates a least-privilege PKI policy to attach to existing Vault identities
- Enables JWT authentication for HCP Terraform workspaces to access Vault as organization clients

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
- HCP Terraform JWT auth backend and role (`vault_jwt_auth_backend`, `vault_jwt_auth_backend_role`)

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
- HCP Terraform JWT login path scoped to AWS Sandbox project by default
- Opinionated defaults with variables for domain, role name, and TTLs

## Usage

```hcl
module "hcpvault_pki_demo" {
  source = "./"

  namespace_path                   = "pki-demo"
  pki_root_namespace_path          = "pki-root"
  pki_intermediate_namespace_path  = "pki-intermediate"
  pki_allowed_domains              = ["demo.example.com"]
  pki_vault_addr_for_urls          = "https://my-cluster.vault.hashicorp.cloud:8200"
  tfc_organization_name            = "your-tfc-organization"
  tfc_project_name                 = "AWS Sandbox Account"
  tfc_workspace_name               = "*"
}
```

## HCP Terraform Client Access

This module configures a Vault JWT auth backend and role so a separate HCP Terraform workspace
can authenticate using dynamic credentials and provision client-side Vault configuration.

Set these environment variables in the client workspace:

- `TFC_VAULT_PROVIDER_AUTH=true`
- `TFC_VAULT_ADDR=<your vault address>`
- `TFC_VAULT_NAMESPACE=<output pki_intermediate_namespace_path>`
- `TFC_VAULT_RUN_ROLE=<output tfc_vault_run_role_name>`

The JWT role is restricted to:

- Organization: `tfc_organization_name`
- Project: `tfc_project_name` (default `AWS Sandbox Account`)
- Workspace: `tfc_workspace_name` (default `*`)

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
| tfc_enable_jwt_auth             | Enable JWT authentication for HCP Terraform workspaces in the intermediate namespace. | `bool` | `true` | no |
| tfc_organization_name           | HCP Terraform organization name allowed to authenticate to Vault.      | `string`     | `"your-tfc-organization"`      | no       |
| tfc_project_name                | HCP Terraform project name allowed to authenticate to Vault.           | `string`     | `"AWS Sandbox Account"`        | no       |
| tfc_vault_auth_path             | Path where JWT auth for HCP Terraform is enabled in the intermediate namespace. | `string` | `"jwt"` | no |
| tfc_vault_run_role_name         | Vault JWT auth role name used by HCP Terraform dynamic credentials.    | `string`     | `"tfc-aws-sandbox-client"`     | no       |
| tfc_workspace_name              | HCP Terraform workspace name allowed to authenticate to Vault (`*` allowed). | `string` | `"*"` | no |

## Outputs

| Name           | Description                                                     |
|----------------|-----------------------------------------------------------------|
| namespace_path | Child namespace path where the PKI demo resources are deployed. |
| pki_intermediate_mount_path | Path of the intermediate PKI secrets engine in the child namespace. |
| pki_intermediate_namespace_path | Child namespace path under the demo namespace for intermediate PKI resources. |
| pki_role_name  | Role name used to issue certificates from Vault UI.             |
| pki_root_mount_path | Path of the root PKI secrets engine in the child namespace. |
| pki_root_namespace_path | Child namespace path under the demo namespace for root PKI resources. |
| tfc_vault_auth_path | JWT auth mount path for HCP Terraform dynamic credentials in the intermediate namespace. |
| tfc_vault_run_role_name | Vault run role name to use in HCP Terraform (`TFC_VAULT_RUN_ROLE`). |

## Demo Value Proposition

This module gives a fast, repeatable demo where operators use existing Vault authentication, while certificate issuance follows the recommended root/intermediate hierarchy with least-privilege controls and namespace isolation.

# External Documentation

- [Vault PKI Secrets Engine](https://developer.hashicorp.com/vault/docs/secrets/pki)
- [Vault Policy Concepts](https://developer.hashicorp.com/vault/docs/concepts/policies)
- [Vault Provider (Terraform Registry)](https://registry.terraform.io/providers/hashicorp/vault/latest/docs)

<!-- BEGIN_TF_DOCS -->
# Vault PKI Demo

This Terraform module provisions a Vault PKI environment designed for strong certificate authority
separation. It creates a reusable demo namespace with dedicated child namespaces for an
offline-style root CA and an online intermediate CA, then configures issuance so end-entity
certificates are generated only from the intermediate. The repository is intended to demonstrate a
production-aligned PKI pattern in Vault while keeping the deployment repeatable for multiple
concurrent demos.

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

## Documentation

## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.10)

- <a name="requirement_vault"></a> [vault](#requirement\_vault) (5.7.0)

## Modules

No modules.

## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_demo_policy_name"></a> [demo\_policy\_name](#input\_demo\_policy\_name)

Description: (Optional) Name of the Vault policy for UI certificate issuance demo access.

Type: `string`

Default: `"pki-demo-ui-issuer"`

### <a name="input_namespace_path"></a> [namespace\_path](#input\_namespace\_path)

Description: (Optional) The path of the namespace. Must not have a trailing `/`.

Type: `string`

Default: `"pki-demo"`

### <a name="input_pki_allowed_domains"></a> [pki\_allowed\_domains](#input\_pki\_allowed\_domains)

Description: (Optional) Domains allowed for certificate issuance from the intermediate role.

Type: `list(string)`

Default:

```json
[
  "demo.example.com"
]
```

### <a name="input_pki_cert_max_ttl"></a> [pki\_cert\_max\_ttl](#input\_pki\_cert\_max\_ttl)

Description: (Optional) Maximum TTL for certificates issued by the intermediate PKI role.

Type: `string`

Default: `"720h"`

### <a name="input_pki_cert_ttl"></a> [pki\_cert\_ttl](#input\_pki\_cert\_ttl)

Description: (Optional) Default TTL for certificates issued by the intermediate PKI role.

Type: `string`

Default: `"72h"`

### <a name="input_pki_intermediate_ca_ttl"></a> [pki\_intermediate\_ca\_ttl](#input\_pki\_intermediate\_ca\_ttl)

Description: (Optional) TTL for the intermediate CA certificate signed by the root CA.

Type: `string`

Default: `"43800h"`

### <a name="input_pki_intermediate_common_name"></a> [pki\_intermediate\_common\_name](#input\_pki\_intermediate\_common\_name)

Description: (Optional) Common Name used for the intermediate CA generated in the demo PKI hierarchy.

Type: `string`

Default: `"demo.example.com Intermediate CA"`

### <a name="input_pki_intermediate_default_lease_ttl_seconds"></a> [pki\_intermediate\_default\_lease\_ttl\_seconds](#input\_pki\_intermediate\_default\_lease\_ttl\_seconds)

Description: (Optional) Default lease TTL for the intermediate PKI mount in seconds.

Type: `number`

Default: `2592000`

### <a name="input_pki_intermediate_max_lease_ttl_seconds"></a> [pki\_intermediate\_max\_lease\_ttl\_seconds](#input\_pki\_intermediate\_max\_lease\_ttl\_seconds)

Description: (Optional) Maximum lease TTL for the intermediate PKI mount in seconds.

Type: `number`

Default: `157680000`

### <a name="input_pki_intermediate_mount_path"></a> [pki\_intermediate\_mount\_path](#input\_pki\_intermediate\_mount\_path)

Description: (Optional) Path where the intermediate PKI secrets engine is enabled in the child namespace.

Type: `string`

Default: `"pki-int"`

### <a name="input_pki_intermediate_namespace_path"></a> [pki\_intermediate\_namespace\_path](#input\_pki\_intermediate\_namespace\_path)

Description: (Optional) Child namespace name under the demo namespace where intermediate PKI resources are provisioned.

Type: `string`

Default: `"pki-intermediate"`

### <a name="input_pki_role_name"></a> [pki\_role\_name](#input\_pki\_role\_name)

Description: (Optional) Role name used by the UI to issue certificates from the intermediate PKI engine.

Type: `string`

Default: `"ui-issuer"`

### <a name="input_pki_root_ca_ttl"></a> [pki\_root\_ca\_ttl](#input\_pki\_root\_ca\_ttl)

Description: (Optional) TTL for the self-signed root CA certificate used to sign the intermediate.

Type: `string`

Default: `"87600h"`

### <a name="input_pki_root_common_name"></a> [pki\_root\_common\_name](#input\_pki\_root\_common\_name)

Description: (Optional) Common Name used for the root CA generated in the demo PKI hierarchy.

Type: `string`

Default: `"demo.example.com Root CA"`

### <a name="input_pki_root_default_lease_ttl_seconds"></a> [pki\_root\_default\_lease\_ttl\_seconds](#input\_pki\_root\_default\_lease\_ttl\_seconds)

Description: (Optional) Default lease TTL for the root PKI mount in seconds.

Type: `number`

Default: `31536000`

### <a name="input_pki_root_max_lease_ttl_seconds"></a> [pki\_root\_max\_lease\_ttl\_seconds](#input\_pki\_root\_max\_lease\_ttl\_seconds)

Description: (Optional) Maximum lease TTL for the root PKI mount in seconds.

Type: `number`

Default: `315360000`

### <a name="input_pki_root_mount_path"></a> [pki\_root\_mount\_path](#input\_pki\_root\_mount\_path)

Description: (Optional) Path where the root PKI secrets engine is enabled in the child namespace.

Type: `string`

Default: `"pki-root"`

### <a name="input_pki_root_namespace_path"></a> [pki\_root\_namespace\_path](#input\_pki\_root\_namespace\_path)

Description: (Optional) Child namespace name under the demo namespace where root PKI resources are provisioned.

Type: `string`

Default: `"pki-root"`

### <a name="input_pki_vault_addr_for_urls"></a> [pki\_vault\_addr\_for\_urls](#input\_pki\_vault\_addr\_for\_urls)

Description: (Optional) Vault address used for PKI issuing certificate and CRL URLs. Leave empty to skip URL configuration.

Type: `string`

Default: `""`

## Resources

The following resources are used by this module:

- [vault_mount.pki_intermediate](https://registry.terraform.io/providers/hashicorp/vault/5.7.0/docs/resources/mount) (resource)
- [vault_mount.pki_root](https://registry.terraform.io/providers/hashicorp/vault/5.7.0/docs/resources/mount) (resource)
- [vault_namespace.demo](https://registry.terraform.io/providers/hashicorp/vault/5.7.0/docs/resources/namespace) (resource)
- [vault_namespace.pki_intermediate](https://registry.terraform.io/providers/hashicorp/vault/5.7.0/docs/resources/namespace) (resource)
- [vault_namespace.pki_root](https://registry.terraform.io/providers/hashicorp/vault/5.7.0/docs/resources/namespace) (resource)
- [vault_pki_secret_backend_config_urls.intermediate_urls](https://registry.terraform.io/providers/hashicorp/vault/5.7.0/docs/resources/pki_secret_backend_config_urls) (resource)
- [vault_pki_secret_backend_config_urls.root_urls](https://registry.terraform.io/providers/hashicorp/vault/5.7.0/docs/resources/pki_secret_backend_config_urls) (resource)
- [vault_pki_secret_backend_intermediate_cert_request.intermediate_csr](https://registry.terraform.io/providers/hashicorp/vault/5.7.0/docs/resources/pki_secret_backend_intermediate_cert_request) (resource)
- [vault_pki_secret_backend_intermediate_set_signed.intermediate_import](https://registry.terraform.io/providers/hashicorp/vault/5.7.0/docs/resources/pki_secret_backend_intermediate_set_signed) (resource)
- [vault_pki_secret_backend_role.issue_role](https://registry.terraform.io/providers/hashicorp/vault/5.7.0/docs/resources/pki_secret_backend_role) (resource)
- [vault_pki_secret_backend_root_cert.root_ca](https://registry.terraform.io/providers/hashicorp/vault/5.7.0/docs/resources/pki_secret_backend_root_cert) (resource)
- [vault_pki_secret_backend_root_sign_intermediate.intermediate_signed](https://registry.terraform.io/providers/hashicorp/vault/5.7.0/docs/resources/pki_secret_backend_root_sign_intermediate) (resource)
- [vault_policy.pki_demo](https://registry.terraform.io/providers/hashicorp/vault/5.7.0/docs/resources/policy) (resource)

## Outputs

The following outputs are exported:

### <a name="output_demo_policy_name"></a> [demo\_policy\_name](#output\_demo\_policy\_name)

Description: Name of the PKI issuance policy created for existing Vault identities.

### <a name="output_namespace_path"></a> [namespace\_path](#output\_namespace\_path)

Description: Child namespace path where the PKI demo resources are deployed.

### <a name="output_pki_intermediate_mount_path"></a> [pki\_intermediate\_mount\_path](#output\_pki\_intermediate\_mount\_path)

Description: Path of the intermediate PKI secrets engine in the child namespace.

### <a name="output_pki_intermediate_namespace_path"></a> [pki\_intermediate\_namespace\_path](#output\_pki\_intermediate\_namespace\_path)

Description: Child namespace path under the demo namespace for intermediate PKI resources.

### <a name="output_pki_role_name"></a> [pki\_role\_name](#output\_pki\_role\_name)

Description: Role name used to issue certificates from Vault UI.

### <a name="output_pki_root_mount_path"></a> [pki\_root\_mount\_path](#output\_pki\_root\_mount\_path)

Description: Path of the root PKI secrets engine in the child namespace.

### <a name="output_pki_root_namespace_path"></a> [pki\_root\_namespace\_path](#output\_pki\_root\_namespace\_path)

Description: Child namespace path under the demo namespace for root PKI resources.

<!-- markdownlint-enable -->
# External Documentation

- [Vault PKI Secrets Engine](https://developer.hashicorp.com/vault/docs/secrets/pki)
- [Vault Policy Concepts](https://developer.hashicorp.com/vault/docs/concepts/policies)
- [Vault Provider (Terraform Registry)](https://registry.terraform.io/providers/hashicorp/vault/latest/docs)
<!-- END_TF_DOCS -->