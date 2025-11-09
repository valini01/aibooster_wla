# Terraform + GitHub Actions Azure Deployment

This repository contains a complete Terraform setup with GitHub Actions workflows for deploying Azure resources with modern best practices.

## 📁 Project Structure

```
├── terraform/
│   ├── main.tf         # Azure Resource Group configuration
│   ├── variables.tf    # Input variables (name, location)
│   └── outputs.tf      # Output values
├── .github/workflows/
│   ├── main.yml                # Orchestrator workflow
│   ├── terraform-init.yml      # Auto-runs on push to main
│   ├── terraform-plan.yml      # Manual trigger with approval
│   ├── terraform-apply.yml     # Manual trigger with approval
│   └── terraform-destroy.yml   # Manual trigger for cleanup
└── .gitignore          # Git ignore patterns
```

## 🚀 Setup Instructions

### 1. Configure Azure OIDC Authentication

Add these secrets in **Settings** → **Secrets and variables** → **Actions**:

- `AZURE_CLIENT_ID` - Application (client) ID of your Azure AD app
- `AZURE_TENANT_ID` - Directory (tenant) ID of your Azure AD
- `AZURE_SUBSCRIPTION_ID` - Your Azure subscription ID

### 2. Create GitHub Environment (for manual approvals)

1. Go to **Settings** → **Environments**
2. Create environment named `production`
3. Add **Required reviewers** (yourself or team members)
4. Save protection rules

### 3. Usage Workflow

1. **Push to main** → `terraform-init` runs automatically
2. **Actions tab** → Run `terraform-plan` workflow → Approve → View plan
3. **Actions tab** → Run `terraform-apply` workflow → Approve → Deploy resources
4. **Actions tab** → Run `terraform-destroy` workflow → Clean up resources

## 🔧 Features

- ✅ OIDC-based Azure authentication (no secrets)
- ✅ Manual approval gates for plan/apply
- ✅ Latest GitHub Actions and Terraform versions
- ✅ Local state storage (simple setup)
- ✅ Clean, minimal workflow configurations
- ✅ Auto-triggered init on code changes

## 📋 Default Configuration

- **Resource Group**: `rg-terraform-demo`
- **Location**: `East US`
- **Environment**: `production` (with approval gates)

Customize these values in `terraform/variables.tf` as needed.

## 🎯 Next Steps

1. Configure the Azure secrets (if using service principal)
2. Set up the production environment
3. Push changes to trigger the init workflow
4. Use the Actions tab to manage your infrastructure!

<!-- Trigger update -->