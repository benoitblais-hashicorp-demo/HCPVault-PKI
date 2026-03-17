output "aws_auth_backend_path" {
  description = "Path of the AWS auth backend in the intermediate namespace."
  value       = vault_auth_backend.aws.path
}

output "azure_devops_jwt_backend_path" {
  description = "Path that the Azure HCP Terraform role is allowed to use when creating the Azure DevOps JWT/OIDC auth backend in the intermediate namespace."
  value       = var.azure_devops_jwt_backend_path
}

output "azure_kv_v2_mount_path" {
  description = "Path that the Azure HCP Terraform role is allowed to use when enabling a KV v2 secrets engine in the intermediate namespace."
  value       = var.azure_kv_v2_mount_path
}

output "demo_policy_name" {
  description = "Name of the PKI issuance policy created for existing Vault identities."
  value       = vault_policy.pki_demo.name
}

output "namespace_path" {
  description = "Child namespace path where the PKI demo resources are deployed."
  value       = vault_namespace.demo.path
}

output "pki_intermediate_mount_path" {
  description = "Path of the intermediate PKI secrets engine in the child namespace."
  value       = vault_mount.pki_intermediate.path
}

output "pki_intermediate_namespace_path" {
  description = "Child namespace path under the demo namespace for intermediate PKI resources."
  value       = "${vault_namespace.demo.path}/${vault_namespace.pki_intermediate.path}"
}

output "pki_role_name" {
  description = "Role name used to issue certificates from Vault UI."
  value       = vault_pki_secret_backend_role.issue_role.name
}

output "pki_root_mount_path" {
  description = "Path of the root PKI secrets engine in the child namespace."
  value       = vault_mount.pki_root.path
}

output "pki_root_namespace_path" {
  description = "Child namespace path under the demo namespace for root PKI resources."
  value       = "${vault_namespace.demo.path}/${vault_namespace.pki_root.path}"
}

output "jwt_hcp_backend_path" {
  description = "Mount path of the HCP Terraform JWT auth backend in the intermediate namespace. Null when hcp_jwt_workspace_name_aws is not set."
  value       = try(vault_jwt_auth_backend.jwt_hcp[0].path, null)
}

output "jwt_hcp_role_name_aws" {
  description = "Name of the Vault role that the HCP Terraform AWS workspace must use for dynamic provider credentials. Null when hcp_jwt_workspace_name_aws is not set."
  value       = try(vault_jwt_auth_backend_role.jwt_hcp_aws[0].role_name, null)
}

output "jwt_hcp_aws_admin_policy_name" {
  description = "Name of the Vault policy granting HCP Terraform AWS JWT role access to manage AWS auth roles and ACL policies. Null when hcp_jwt_workspace_name_aws is not set."
  value       = try(vault_policy.hcp_jwt_aws_admin[0].name, null)
}

output "jwt_hcp_azure_admin_policy_name" {
  description = "Name of the Vault policy granting HCP Terraform Azure JWT role access to manage PKI roles/certificates and ACL policies. Null when hcp_jwt_workspace_name_azure is not set."
  value       = try(vault_policy.hcp_jwt_azure_admin[0].name, null)
}

output "jwt_hcp_role_name_azure" {
  description = "Name of the Vault role that the HCP Terraform Azure workspace must use for dynamic provider credentials. Null when hcp_jwt_workspace_name_azure is not set."
  value       = try(vault_jwt_auth_backend_role.jwt_hcp_azure[0].role_name, null)
}
