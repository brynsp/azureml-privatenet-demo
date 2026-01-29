# Azure ML Private Network Project

## Project Goal

Build a secure Azure Machine Learning (Azure ML) Workspace using **only** private link and private endpoint connections for network communication. This ensures that the workspace and its associated resources are not exposed to the public internet.

## Architecture Overview

The infrastructure is deployed using **Terraform**, leveraging **Azure Verified Modules (AVM)** where applicable.

### Key Components

1. **Networking**
   * **Virtual Network (VNet)**: The backbone of the private network.
   * **Subnets**: Dedicated subnets for:
     * Private Endpoints (for Azure services).
     * Training Compute (Azure ML Compute Clusters).
     * Inference Compute (if applicable).
   * **Private DNS Zones**: To resolve private endpoint IP addresses.

2. **Storage**
   * **Azure Storage Account**: Stores datasets and code.
   * **Private Endpoints**: Enabled for `blob` (data) and `file` (code mounting).
   * **Code Management**: Training scripts and inference code will be mounted from Azure Files/Blob rather than baked into container images.

3. **Container Registry**
   * **Azure Container Registry (ACR)**: Stores Docker images (Triton, vLLM).
   * **Private Endpoint**: Ensures images are pulled over the private network.

4. **Security**
   * **Azure Key Vault**: Stores secrets and keys.
   * **Private Endpoint**: Secure access to secrets.

5. **Azure ML Workspace**
   * **Workspace**: The central hub for ML activities.
   * **Private Endpoint**: Disables public access to the workspace.
   * **Compute**:
     * **Compute Instance**: Used for development. Configured with a **User Assigned Identity** to ensure secure access to storage and container registries without public access.
     * **Compute Cluster**: Used for training jobs. Configured with auto-scaling.

## Deployment

### Repository Layout

This repo is split into two Terraform runs:

* [bootstrap](bootstrap) - Creates the dedicated state storage account in a separate resource group.
* [infra](infra) - Deploys the Azure ML private network stack using the remote backend.

### Prerequisites

* Terraform >= 1.5.0
* Azure CLI
* An Azure Subscription

### Configuration

#### Bootstrap configuration

1. Copy [bootstrap/terraform.tfvars.example](bootstrap/terraform.tfvars.example) to bootstrap/terraform.tfvars.
2. Update the values for the state resource group and storage account (same subscription as your app).

#### Infra configuration

1. Copy [infra/terraform.tfvars.example](infra/terraform.tfvars.example) to infra/terraform.tfvars.
2. Create infra/backend.hcl from [infra/backend.hcl.example](infra/backend.hcl.example) and fill in the state storage account details.

### Storage Account Authentication

This project configures Azure Storage Accounts with **Shared Access Keys disabled** for enhanced security. Terraform authenticates using Azure AD for both the application storage account and the remote state backend.

1. **Terraform Configuration**: The `azurerm` provider is configured with `storage_use_azuread = true` in [infra/versions.tf](infra/versions.tf).
2. **Backend Configuration**: The backend uses `use_azuread_auth = true` in [infra/backend.hcl.example](infra/backend.hcl.example).
3. **User Permissions (State)**: The identity running Terraform for infra must have the **Storage Blob Data Owner** role on the state storage account or container.
4. **User Permissions (Bootstrap)**: If bootstrap assigns roles, the identity running bootstrap must also have permission to create role assignments (Owner or User Access Administrator) at the state storage account scope.

### Bootstrap (State Storage)

From the repo root:

1. `cd bootstrap`
2. `terraform init`
3. `terraform apply`

This creates a state resource group, storage account, and container in the same subscription as the app.

### Infra (Application Stack)

From the repo root:

1. `cd infra`
2. `terraform init -backend-config=backend.hcl`
3. `terraform apply`

### Secrets Handling

* Do not commit `terraform.tfvars` or backend configuration files. They are ignored by [.gitignore](.gitignore).
* Store sensitive values in Azure Key Vault; this stack already provisions a Key Vault and uses it for secrets like the jumpbox password.
* Never commit `terraform.tfstate` or backups (local state is ignored by default).

### Conditional Features (Why/When to Toggle)

The stack includes several feature toggles to adapt to different security and governance environments. Set these in infra/terraform.tfvars (unless noted as bootstrap).

* `manage_defender_plans`:
  * **true** to have Terraform manage Defender for Cloud subscription pricing.
  * **false** to leave existing/policy‑managed pricing untouched (avoids imports in managed subscriptions).

* `manage_defender_contact`:
  * **true** to manage the Defender security contact in Terraform.
  * **false** to avoid import conflicts when a default contact already exists.

* `jumpbox_auth_mode`:
  * **"entra"** (default) for Entra ID login with the AAD extension; local credentials still exist but Entra is preferred.
  * **"password"** to allow local admin sign‑in (use only when required by tooling or offline access).

* `jumpbox_admin_username`:
  * **Any non‑empty string** (default: `azureadmin`) to set the local admin username for the jumpbox VM.
  * The username and generated password are stored in Key Vault as `jumpbox-username` and `jumpbox-password`.

* `aml_workspace_enable_managed_network`:
  * **true** to enable AML managed virtual network for the workspace. This is best when you want Azure ML to own outbound control/isolation with minimal networking setup in locked‑down environments.
  * **false** to keep managed network disabled and use your own VNet controls. Choose this when you need full control of routing, NSGs, custom firewalls, or advanced hub‑and‑spoke designs.

* `aml_workspace_managed_network_isolation_mode`:
  * **"Disabled"** to keep managed network isolation off.
  * **"AllowInternetOutbound"** to allow outbound internet access.
  * **"AllowOnlyApprovedOutbound"** to restrict outbound to approved service tags/FQDNs.

* `aml_workspace_provision_network_now_enabled`:
  * **true** to provision the managed network immediately during apply.
  * **false** to defer managed network provisioning.

* `enable_compute_instance`:
  * **true** to create the AML compute instance.
  * **false** to skip the instance (useful if the region is out of capacity).

* `enable_compute_cluster`:
  * **true** to create the AML compute cluster.
  * **false** to skip the cluster.

* `resource_group_security_control_ignore`:
  * **true** to add the `SecurityControl=Ignore` tag to the infra resource group for policy exemption. When enabled, the Key Vault also allows public access from the Terraform runner’s public IP so secrets can be written during apply.
  * **false** to leave tags unchanged and keep Key Vault public access disabled (run Terraform from inside the VNet).

* `resource_group_security_control_ignore` (bootstrap):
  * **true** to add the `SecurityControl=Ignore` tag to the bootstrap state resource group.
  * **false** to leave tags unchanged.

### Design Tradeoffs (Security, Cost, Best Practices)

This repo prioritizes **private networking and RBAC** by default. It is secure‑by‑design, but not cost‑optimized. Below are the key tradeoffs and how to tune them based on your goal.

**Secure‑by‑design (tighten further):**

* Keep `public_network_access_enabled = false` across core resources (default).
* Set `aml_workspace_managed_network_isolation_mode = "AllowOnlyApprovedOutbound"` once you are ready to define outbound rules.
* Keep `resource_group_security_control_ignore = false` after the initial deployment to avoid public Key Vault access.

**Cost‑optimized (lower spend):**

* Disable compute when not needed: `enable_compute_instance = false` and/or `enable_compute_cluster = false`.
* Consider smaller VM sizes in `ds_vm_size` and `training_cluster_vm_size`.
* Review ACR SKU (`Premium` is required for private endpoints; if private endpoints are not needed, a lower SKU is cheaper).
* Reduce diagnostics volume by selecting specific log categories instead of all categories.

**Best‑practice balance (recommended default path):**

* Start with the current defaults for a secure private baseline.
* After validation, tighten AML managed network egress and reduce diagnostics to critical categories.
* Keep Bastion and NAT only if you need interactive admin access; otherwise remove them to save cost.

### Apply

Use the bootstrap and infra steps above rather than running Terraform from the repo root.

### Defender for Cloud (Subscription Pricing)

Terraform can optionally manage Defender for Cloud subscription pricing. This is useful when you own the subscription security baseline and want it codified for repeatability, auditability, and drift detection. However, in shared or centrally governed subscriptions, Defender plans are often already enabled by policy. In that case, Terraform will require imports and can conflict with centralized controls.

**Recommendation:** leave `manage_defender_plans = false` unless you explicitly want Terraform to own Defender plan settings for the subscription.
