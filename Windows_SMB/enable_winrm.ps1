# Enables WinRM for Ansible (HTTP on 5985)
winrm quickconfig -q
Enable-PSRemoting -Force
Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true
Set-Item -Path WSMan:\localhost\Service\AllowUnencrypted -Value $true
Restart-Service WinRM

# Allow WinRM through firewall
netsh advfirewall firewall add rule name="WinRM 5985" dir=in action=allow protocol=TCP localport=5985
