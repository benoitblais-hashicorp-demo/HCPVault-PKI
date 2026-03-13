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
  description = "Mount path of the HCP Terraform JWT auth backend in the intermediate namespace. Null when hcp_jwt_workspace_name is not set."
  value       = try(vault_jwt_auth_backend.jwt_hcp[0].path, null)
}

output "jwt_hcp_role_name" {
  description = "Name of the Vault role that the HCP Terraform workspace must use for dynamic provider credentials. Null when hcp_jwt_workspace_name is not set."
  value       = try(vault_jwt_auth_backend_role.jwt_hcp[0].role_name, null)
}
