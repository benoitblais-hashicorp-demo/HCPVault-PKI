variable "aws_auth_backend_description" {
  type        = string
  description = "(Optional) Description for the AWS auth backend used by Lambda authentication workflows."
  default     = "AWS auth backend for Lambda authentication and role management."

  validation {
    condition     = length(var.aws_auth_backend_description) > 0
    error_message = "`aws_auth_backend_description` must not be empty."
  }
}

variable "aws_auth_backend_path" {
  type        = string
  description = "(Optional) Path to mount the AWS auth backend in the intermediate child namespace."
  default     = "aws"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9_-]*$", var.aws_auth_backend_path))
    error_message = "`aws_auth_backend_path` must contain only lowercase letters, numbers, hyphens, and underscores, and must start with an alphanumeric character."
  }
}

variable "azure_automation_approle_backend_path" {
  type        = string
  description = "(Optional) Path that the Azure HCP Terraform role is allowed to use when creating the Azure automation AppRole auth backend in the intermediate child namespace."
  default     = "approle"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9_-]*$", var.azure_automation_approle_backend_path))
    error_message = "`azure_automation_approle_backend_path` must contain only lowercase letters, numbers, hyphens, and underscores, and must start with an alphanumeric character."
  }
}

variable "azure_automation_jwt_backend_path" {
  type        = string
  description = "(Optional) Path that the Azure HCP Terraform role is allowed to use when creating the Azure automation JWT/OIDC auth backend in the intermediate child namespace."
  default     = "jwt_workload"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9_-]*$", var.azure_automation_jwt_backend_path))
    error_message = "`azure_automation_jwt_backend_path` must contain only lowercase letters, numbers, hyphens, and underscores, and must start with an alphanumeric character."
  }
}

variable "azure_kv_v2_mount_path" {
  type        = string
  description = "(Optional) Path that the Azure HCP Terraform role is allowed to use when enabling a KV v2 secrets engine in the intermediate child namespace."
  default     = "kv-azure-pki-demo"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.azure_kv_v2_mount_path))
    error_message = "`azure_kv_v2_mount_path` must contain only lowercase letters, numbers, and hyphens, and must start and end with an alphanumeric character."
  }
}

variable "demo_policy_name" {
  type        = string
  description = "(Optional) Name of the Vault policy for UI certificate issuance demo access."
  default     = "pki-demo-ui-issuer"

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9_-]*$", var.demo_policy_name))
    error_message = "`demo_policy_name` must start with an alphanumeric character and contain only alphanumeric characters, underscores, or hyphens."
  }
}

variable "hcp_jwt_backend_description" {
  type        = string
  description = "(Optional) The description of the HCP Terraform JWT auth backend."
  default     = "JWT auth method for HCP Terraform workload identity tokens."

  validation {
    condition     = length(var.hcp_jwt_backend_description) > 0
    error_message = "`hcp_jwt_backend_description` must not be empty."
  }
}

variable "hcp_jwt_aws_admin_policy_name" {
  type        = string
  description = "(Optional) Name of the Vault policy attached to the HCP Terraform AWS JWT role for AWS auth role and ACL policy management."
  default     = "jwt-hcp-aws-admin"

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9_-]*$", var.hcp_jwt_aws_admin_policy_name))
    error_message = "`hcp_jwt_aws_admin_policy_name` must start with an alphanumeric character and contain only alphanumeric characters, underscores, or hyphens."
  }
}

variable "hcp_jwt_azure_admin_policy_name" {
  type        = string
  description = "(Optional) Name of the Vault policy attached to the HCP Terraform Azure JWT role for Azure auth role and ACL policy management."
  default     = "jwt-hcp-azure-admin"

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9_-]*$", var.hcp_jwt_azure_admin_policy_name))
    error_message = "`hcp_jwt_azure_admin_policy_name` must start with an alphanumeric character and contain only alphanumeric characters, underscores, or hyphens."
  }
}

variable "hcp_jwt_backend_path" {
  type        = string
  description = "(Optional) Path to mount the JWT auth backend for the HCP Terraform JWT."
  default     = "jwt_hcp"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9_-]*$", var.hcp_jwt_backend_path))
    error_message = "`hcp_jwt_backend_path` must contain only lowercase letters, numbers, hyphens, and underscores, and must start with an alphanumeric character."
  }
}

variable "hcp_jwt_bound_issuer" {
  type        = string
  description = "(Optional) Expected issuer (iss claim) of HCP Terraform workload identity JWT tokens."
  default     = "https://app.terraform.io"

  validation {
    condition     = can(regex("^https://", var.hcp_jwt_bound_issuer))
    error_message = "`hcp_jwt_bound_issuer` must be a valid HTTPS URL."
  }
}

variable "hcp_jwt_discovery_url" {
  type        = string
  description = "(Optional) OIDC discovery URL used by Vault to retrieve the HCP Terraform JWKS and validate token signatures."
  default     = "https://app.terraform.io"

  validation {
    condition     = can(regex("^https://", var.hcp_jwt_discovery_url))
    error_message = "`hcp_jwt_discovery_url` must be a valid HTTPS URL."
  }
}

variable "hcp_jwt_role_name_aws" {
  type        = string
  description = "(Optional) Name of the Vault role used by the HCP Terraform AWS workspace during JWT login."
  default     = "jwt_hcp_aws_role"

  validation {
    condition     = length(var.hcp_jwt_role_name_aws) > 0
    error_message = "`hcp_jwt_role_name_aws` must not be empty."
  }
}

variable "hcp_jwt_token_max_ttl_aws" {
  type        = number
  description = "(Optional) Maximum lifetime of an HCP Terraform AWS Vault token, in seconds."
  default     = 600

  validation {
    condition     = var.hcp_jwt_token_max_ttl_aws > 0
    error_message = "`hcp_jwt_token_max_ttl_aws` must be greater than 0."
  }
}

variable "hcp_jwt_token_ttl_aws" {
  type        = number
  description = "(Optional) Default lifetime of an HCP Terraform AWS Vault token, in seconds."
  default     = 300

  validation {
    condition     = var.hcp_jwt_token_ttl_aws > 0
    error_message = "`hcp_jwt_token_ttl_aws` must be greater than 0."
  }
}

variable "hcp_jwt_workspace_name_aws" {
  type        = string
  description = "(Optional) The HCP Terraform AWS workspace name that is allowed to authenticate to Vault. Set to null to skip HCP Terraform AWS JWT auth entirely."
  default     = null

  validation {
    condition     = var.hcp_jwt_workspace_name_aws == null || length(var.hcp_jwt_workspace_name_aws) > 0
    error_message = "`hcp_jwt_workspace_name_aws` must not be an empty string when set."
  }
}

variable "hcp_jwt_role_name_azure" {
  type        = string
  description = "(Optional) Name of the Vault role used by the HCP Terraform Azure workspace during JWT login."
  default     = "jwt_hcp_azure_role"

  validation {
    condition     = length(var.hcp_jwt_role_name_azure) > 0
    error_message = "`hcp_jwt_role_name_azure` must not be empty."
  }
}

variable "hcp_jwt_token_max_ttl_azure" {
  type        = number
  description = "(Optional) Maximum lifetime of an HCP Terraform Azure Vault token, in seconds."
  default     = 600

  validation {
    condition     = var.hcp_jwt_token_max_ttl_azure > 0
    error_message = "`hcp_jwt_token_max_ttl_azure` must be greater than 0."
  }
}

variable "hcp_jwt_token_ttl_azure" {
  type        = number
  description = "(Optional) Default lifetime of an HCP Terraform Azure Vault token, in seconds."
  default     = 300

  validation {
    condition     = var.hcp_jwt_token_ttl_azure > 0
    error_message = "`hcp_jwt_token_ttl_azure` must be greater than 0."
  }
}

variable "hcp_jwt_workspace_name_azure" {
  type        = string
  description = "(Optional) The HCP Terraform Azure workspace name that is allowed to authenticate to Vault. Set to null to skip HCP Terraform Azure JWT auth entirely."
  default     = null

  validation {
    condition     = var.hcp_jwt_workspace_name_azure == null || length(var.hcp_jwt_workspace_name_azure) > 0
    error_message = "`hcp_jwt_workspace_name_azure` must not be an empty string when set."
  }
}

variable "namespace_path" {
  type        = string
  description = "(Optional) The path of the namespace. Must not have a trailing `/`."
  default     = "pki-demo"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.namespace_path))
    error_message = "`namespace_path` must contain only lowercase letters, numbers, and hyphens, and must start and end with an alphanumeric character."
  }
}

variable "pki_allowed_domains" {
  type        = list(string)
  description = "(Optional) Domains allowed for certificate issuance from the intermediate role."
  default     = ["demo.example.com"]

  validation {
    condition = length(var.pki_allowed_domains) > 0 && alltrue([
      for domain_name in var.pki_allowed_domains : can(regex("^([*][.])?[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?(\\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)+$", domain_name))
    ])
    error_message = "`pki_allowed_domains` must contain at least one valid DNS domain name (wildcards like `*.example.com` are allowed)."
  }
}

variable "pki_cert_max_ttl" {
  type        = string
  description = "(Optional) Maximum TTL for certificates issued by the intermediate PKI role. Accepts canonical seconds (recommended) or duration values."
  default     = "2592000"

  validation {
    condition     = can(regex("^[1-9][0-9]*([smhd])?$", var.pki_cert_max_ttl))
    error_message = "`pki_cert_max_ttl` must be a positive duration (for example `72h`, `30m`, or `7d`) or canonical seconds (for example `2592000`)."
  }
}

variable "pki_cert_ttl" {
  type        = string
  description = "(Optional) Default TTL for certificates issued by the intermediate PKI role. Accepts canonical seconds (recommended) or duration values."
  default     = "259200"

  validation {
    condition     = can(regex("^[1-9][0-9]*([smhd])?$", var.pki_cert_ttl))
    error_message = "`pki_cert_ttl` must be a positive duration (for example `72h`, `30m`, or `7d`) or canonical seconds (for example `259200`)."
  }
}

variable "pki_intermediate_ca_ttl" {
  type        = string
  description = "(Optional) TTL for the intermediate CA certificate signed by the root CA."
  default     = "43800h"

  validation {
    condition     = can(regex("^[1-9][0-9]*[smhd]$", var.pki_intermediate_ca_ttl))
    error_message = "`pki_intermediate_ca_ttl` must be a positive duration like `43800h` or `365d`."
  }
}

variable "pki_intermediate_common_name" {
  type        = string
  description = "(Optional) Common Name used for the intermediate CA generated in the demo PKI hierarchy."
  default     = "demo.example.com Intermediate CA"

  validation {
    condition     = length(trimspace(var.pki_intermediate_common_name)) > 2
    error_message = "`pki_intermediate_common_name` must not be empty."
  }
}

variable "pki_intermediate_default_lease_ttl_seconds" {
  type        = number
  description = "(Optional) Default lease TTL for the intermediate PKI mount in seconds."
  default     = 2592000

  validation {
    condition     = var.pki_intermediate_default_lease_ttl_seconds > 0
    error_message = "`pki_intermediate_default_lease_ttl_seconds` must be greater than 0."
  }
}

variable "pki_intermediate_max_lease_ttl_seconds" {
  type        = number
  description = "(Optional) Maximum lease TTL for the intermediate PKI mount in seconds."
  default     = 157680000

  validation {
    condition     = var.pki_intermediate_max_lease_ttl_seconds > 0
    error_message = "`pki_intermediate_max_lease_ttl_seconds` must be greater than 0."
  }
}

variable "pki_intermediate_mount_path" {
  type        = string
  description = "(Optional) Path where the intermediate PKI secrets engine is enabled in the child namespace."
  default     = "pki-int"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.pki_intermediate_mount_path))
    error_message = "`pki_intermediate_mount_path` must contain only lowercase letters, numbers, and hyphens, and must start and end with an alphanumeric character."
  }
}

variable "pki_intermediate_namespace_path" {
  type        = string
  description = "(Optional) Child namespace name under the demo namespace where intermediate PKI resources are provisioned."
  default     = "pki-intermediate"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.pki_intermediate_namespace_path))
    error_message = "`pki_intermediate_namespace_path` must contain only lowercase letters, numbers, and hyphens, and must start and end with an alphanumeric character."
  }
}

variable "pki_role_name" {
  type        = string
  description = "(Optional) Role name used by the UI to issue certificates from the intermediate PKI engine."
  default     = "ui-issuer"

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9_-]*$", var.pki_role_name))
    error_message = "`pki_role_name` must start with an alphanumeric character and contain only alphanumeric characters, underscores, or hyphens."
  }
}

variable "pki_root_ca_ttl" {
  type        = string
  description = "(Optional) TTL for the self-signed root CA certificate used to sign the intermediate."
  default     = "87600h"

  validation {
    condition     = can(regex("^[1-9][0-9]*[smhd]$", var.pki_root_ca_ttl))
    error_message = "`pki_root_ca_ttl` must be a positive duration like `87600h` or `3650d`."
  }
}

variable "pki_root_common_name" {
  type        = string
  description = "(Optional) Common Name used for the root CA generated in the demo PKI hierarchy."
  default     = "demo.example.com Root CA"

  validation {
    condition     = length(trimspace(var.pki_root_common_name)) > 2
    error_message = "`pki_root_common_name` must not be empty."
  }
}

variable "pki_root_default_lease_ttl_seconds" {
  type        = number
  description = "(Optional) Default lease TTL for the root PKI mount in seconds."
  default     = 31536000

  validation {
    condition     = var.pki_root_default_lease_ttl_seconds > 0
    error_message = "`pki_root_default_lease_ttl_seconds` must be greater than 0."
  }
}

variable "pki_root_max_lease_ttl_seconds" {
  type        = number
  description = "(Optional) Maximum lease TTL for the root PKI mount in seconds."
  default     = 315360000

  validation {
    condition     = var.pki_root_max_lease_ttl_seconds > 0
    error_message = "`pki_root_max_lease_ttl_seconds` must be greater than 0."
  }
}

variable "pki_root_mount_path" {
  type        = string
  description = "(Optional) Path where the root PKI secrets engine is enabled in the child namespace."
  default     = "pki-root"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.pki_root_mount_path))
    error_message = "`pki_root_mount_path` must contain only lowercase letters, numbers, and hyphens, and must start and end with an alphanumeric character."
  }
}

variable "pki_root_namespace_path" {
  type        = string
  description = "(Optional) Child namespace name under the demo namespace where root PKI resources are provisioned."
  default     = "pki-root"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.pki_root_namespace_path))
    error_message = "`pki_root_namespace_path` must contain only lowercase letters, numbers, and hyphens, and must start and end with an alphanumeric character."
  }
}

variable "pki_vault_addr_for_urls" {
  type        = string
  description = "(Optional) Vault address used for PKI issuing certificate and CRL URLs. Leave empty to skip URL configuration."
  default     = ""

  validation {
    condition     = var.pki_vault_addr_for_urls == "" || can(regex("^https?://", var.pki_vault_addr_for_urls))
    error_message = "`pki_vault_addr_for_urls` must be empty or start with `http://` or `https://`."
  }
}
