# ------------------------------------------------------------------------------
# Child Namespace
# ------------------------------------------------------------------------------

resource "vault_namespace" "demo" {
  path = var.namespace_path
}

resource "vault_namespace" "pki_root" {
  namespace = var.namespace_path
  path      = var.pki_root_namespace_path

  depends_on = [vault_namespace.demo]
}

resource "vault_namespace" "pki_intermediate" {
  namespace = var.namespace_path
  path      = var.pki_intermediate_namespace_path

  depends_on = [vault_namespace.demo]
}

locals {
  pki_root_namespace_full_path         = "${var.namespace_path}/${var.pki_root_namespace_path}"
  pki_intermediate_namespace_full_path = "${var.namespace_path}/${var.pki_intermediate_namespace_path}"
}

# ------------------------------------------------------------------------------
# Root PKI (Child Namespace)
# ------------------------------------------------------------------------------

resource "vault_mount" "pki_root" {
  namespace = local.pki_root_namespace_full_path

  path                      = var.pki_root_mount_path
  type                      = "pki"
  description               = "Offline-style root PKI mount for signing an intermediate CA"
  max_lease_ttl_seconds     = var.pki_root_max_lease_ttl_seconds
  default_lease_ttl_seconds = var.pki_root_default_lease_ttl_seconds

  depends_on = [vault_namespace.pki_root]
}

resource "vault_pki_secret_backend_root_cert" "root_ca" {
  namespace = local.pki_root_namespace_full_path

  backend              = vault_mount.pki_root.path
  type                 = "internal"
  common_name          = var.pki_root_common_name
  ttl                  = var.pki_root_ca_ttl
  format               = "pem"
  private_key_format   = "der"
  key_type             = "rsa"
  key_bits             = 4096
  exclude_cn_from_sans = true

  depends_on = [vault_mount.pki_root]
}

resource "vault_pki_secret_backend_config_urls" "root_urls" {
  count     = var.pki_vault_addr_for_urls == "" ? 0 : 1
  namespace = local.pki_root_namespace_full_path

  backend = vault_mount.pki_root.path

  issuing_certificates    = ["${var.pki_vault_addr_for_urls}/v1/${local.pki_root_namespace_full_path}/${vault_mount.pki_root.path}/ca"]
  crl_distribution_points = ["${var.pki_vault_addr_for_urls}/v1/${local.pki_root_namespace_full_path}/${vault_mount.pki_root.path}/crl"]

  depends_on = [vault_pki_secret_backend_root_cert.root_ca]
}

# ------------------------------------------------------------------------------
# Intermediate PKI (Child Namespace)
# ------------------------------------------------------------------------------

resource "vault_mount" "pki_intermediate" {
  namespace = local.pki_intermediate_namespace_full_path

  path                      = var.pki_intermediate_mount_path
  type                      = "pki"
  description               = "Online intermediate PKI mount for end-entity certificate issuance"
  max_lease_ttl_seconds     = var.pki_intermediate_max_lease_ttl_seconds
  default_lease_ttl_seconds = var.pki_intermediate_default_lease_ttl_seconds

  depends_on = [vault_namespace.pki_intermediate]
}

resource "vault_pki_secret_backend_intermediate_cert_request" "intermediate_csr" {
  namespace = local.pki_intermediate_namespace_full_path

  backend     = vault_mount.pki_intermediate.path
  type        = "internal"
  common_name = var.pki_intermediate_common_name
  key_type    = "rsa"
  key_bits    = 4096

  depends_on = [vault_mount.pki_intermediate]
}

resource "vault_pki_secret_backend_root_sign_intermediate" "intermediate_signed" {
  namespace = local.pki_root_namespace_full_path

  backend              = vault_mount.pki_root.path
  csr                  = vault_pki_secret_backend_intermediate_cert_request.intermediate_csr.csr
  common_name          = var.pki_intermediate_common_name
  ttl                  = var.pki_intermediate_ca_ttl
  format               = "pem_bundle"
  exclude_cn_from_sans = true

  depends_on = [
    vault_pki_secret_backend_root_cert.root_ca,
    vault_pki_secret_backend_intermediate_cert_request.intermediate_csr
  ]
}

resource "vault_pki_secret_backend_intermediate_set_signed" "intermediate_import" {
  namespace = local.pki_intermediate_namespace_full_path

  backend     = vault_mount.pki_intermediate.path
  certificate = vault_pki_secret_backend_root_sign_intermediate.intermediate_signed.certificate

  depends_on = [vault_pki_secret_backend_root_sign_intermediate.intermediate_signed]
}

resource "vault_pki_secret_backend_config_urls" "intermediate_urls" {
  count     = var.pki_vault_addr_for_urls == "" ? 0 : 1
  namespace = local.pki_intermediate_namespace_full_path

  backend = vault_mount.pki_intermediate.path

  issuing_certificates    = ["${var.pki_vault_addr_for_urls}/v1/${local.pki_intermediate_namespace_full_path}/${vault_mount.pki_intermediate.path}/ca"]
  crl_distribution_points = ["${var.pki_vault_addr_for_urls}/v1/${local.pki_intermediate_namespace_full_path}/${vault_mount.pki_intermediate.path}/crl"]

  depends_on = [vault_pki_secret_backend_intermediate_set_signed.intermediate_import]
}

resource "vault_pki_secret_backend_role" "issue_role" {
  namespace = local.pki_intermediate_namespace_full_path

  backend            = vault_mount.pki_intermediate.path
  name               = var.pki_role_name
  ttl                = var.pki_cert_ttl
  max_ttl            = var.pki_cert_max_ttl
  allowed_domains    = var.pki_allowed_domains
  allow_subdomains   = true
  allow_bare_domains = true

  depends_on = [vault_pki_secret_backend_intermediate_set_signed.intermediate_import]
}

# ------------------------------------------------------------------------------
# PKI Access Policy for Existing Auth Method (Child Namespace)
# ------------------------------------------------------------------------------

resource "vault_policy" "pki_demo" {
  namespace = local.pki_intermediate_namespace_full_path

  name = var.demo_policy_name

  policy = <<EOT
path "${var.pki_intermediate_mount_path}/issue/${var.pki_role_name}" {
  capabilities = ["create", "update"]
}

path "${var.pki_intermediate_mount_path}/roles" {
  capabilities = ["list"]
}

path "${var.pki_intermediate_mount_path}/roles/${var.pki_role_name}" {
  capabilities = ["read"]
}

path "${var.pki_intermediate_mount_path}/cert/*" {
  capabilities = ["read", "list"]
}

path "${var.pki_intermediate_mount_path}/ca/pem" {
  capabilities = ["read"]
}
EOT

  depends_on = [vault_pki_secret_backend_role.issue_role]
}

# ------------------------------------------------------------------------------
# HCP Terraform Client Authentication (Child Namespace)
# ------------------------------------------------------------------------------

resource "vault_jwt_auth_backend" "jwt_hcp" {
  count = var.hcp_jwt_workspace_name_aws != null ? 1 : 0

  namespace = local.pki_intermediate_namespace_full_path

  description        = var.hcp_jwt_backend_description
  path               = var.hcp_jwt_backend_path
  type               = "jwt"
  oidc_discovery_url = var.hcp_jwt_discovery_url
  bound_issuer       = var.hcp_jwt_bound_issuer

  depends_on = [vault_namespace.pki_intermediate]
}

resource "vault_jwt_auth_backend_role" "jwt_hcp_aws" {
  count = length(vault_jwt_auth_backend.jwt_hcp) > 0 ? 1 : 0

  namespace = local.pki_intermediate_namespace_full_path

  backend         = vault_jwt_auth_backend.jwt_hcp[0].path
  role_name       = var.hcp_jwt_role_name_aws
  role_type       = "jwt"
  user_claim      = "terraform_workspace_name"
  bound_audiences = ["vault.workload.identity"]

  bound_claims = {
    terraform_workspace_name = var.hcp_jwt_workspace_name_aws
  }

  token_policies          = [vault_policy.pki_demo.name]
  token_ttl               = var.hcp_jwt_token_ttl_aws
  token_max_ttl           = var.hcp_jwt_token_max_ttl_aws
  token_no_default_policy = true

  depends_on = [vault_policy.pki_demo]
}
