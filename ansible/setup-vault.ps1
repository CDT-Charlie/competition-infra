# PowerShell script for Ansible Vault setup on Windows
# This script helps create and manage the vault.yml file

$VaultFile = "group_vars\vault.yml"
$VaultExample = "group_vars\vault.yml.example"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Ansible Vault Setup" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Check if vault file already exists
if (Test-Path $VaultFile) {
    Write-Host "⚠️  Vault file already exists: $VaultFile" -ForegroundColor Yellow
    $response = Read-Host "Do you want to recreate it? (y/N)"
    if ($response -ne "y" -and $response -ne "Y") {
        Write-Host "Keeping existing vault file."
        exit 0
    }
    Remove-Item $VaultFile
}

# Check if example file exists
if (-not (Test-Path $VaultExample)) {
    Write-Host "❌ Error: Example file not found: $VaultExample" -ForegroundColor Red
    exit 1
}

Write-Host "Creating vault file from example..."
Write-Host "You will be prompted to enter a vault password."
Write-Host "Remember this password - you'll need it to run playbooks!"
Write-Host ""

# Copy example and encrypt it
Copy-Item $VaultExample $VaultFile
ansible-vault encrypt $VaultFile

Write-Host ""
Write-Host "✅ Vault file created successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Edit the vault file: ansible-vault edit $VaultFile"
Write-Host "2. Change all 'ChangeMe_*' passwords to secure values"
Write-Host "3. Run playbooks with: ansible-playbook playbook.yml --ask-vault-pass"
Write-Host ""
Write-Host "Or use a password file:"
Write-Host "  Set-Content -Path `$HOME\.vault_pass -Value 'your-vault-password'"
Write-Host "  ansible-playbook playbook.yml --vault-password-file `$HOME\.vault_pass"
