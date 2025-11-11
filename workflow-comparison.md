# Destroy Workflow Comparison

## Option 1: Single Destroy (Dangerous)
```yaml
terraform-destroy:
  name: "Terraform Destroy"
  runs-on: ubuntu-latest
  if: github.event_name == 'workflow_dispatch' && github.event.inputs.action == 'destroy'
  environment: production  # Only approval gate
  
  steps:
    - name: Terraform Destroy
      run: terraform destroy -auto-approve  # Direct destruction
```

**Problems:**
- No preview of what gets destroyed
- Approval happens without seeing the plan
- Easy to accidentally destroy wrong resources

## Option 2: Two-Step Destroy (Safe)
```yaml
# Step 1: Plan what will be destroyed
terraform-destroy-plan:
  name: "Terraform Destroy Plan"
  runs-on: ubuntu-latest
  if: github.event_name == 'workflow_dispatch' && github.event.inputs.action == 'destroy-plan'
  
  steps:
    - name: Terraform Destroy Plan
      run: terraform plan -destroy -out=destroy-plan  # Shows preview

# Step 2: Actually destroy (with approval)
terraform-destroy-apply:
  name: "Terraform Destroy Apply"
  runs-on: ubuntu-latest
  if: github.event_name == 'workflow_dispatch' && github.event.inputs.action == 'destroy-apply'
  environment: destruction  # Approval gate
  
  steps:
    - name: Terraform Destroy
      run: terraform apply destroy-plan  # Executes planned destruction
```

**Benefits:**
- See exactly what will be destroyed
- Review and discuss before approval
- Safer approval process
- Audit trail of planned vs actual