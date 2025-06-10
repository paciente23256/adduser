#  Script PowerShell Unificado com Seleção de Ambiente
# Criar utilizadores com Email


# Caminho do ficheiro CSV
$csvPath = "C:\utilizadores.csv"

# Função para mostrar menu
function Mostrar-Menu {
    Write-Host "Selecione o ambiente:" -ForegroundColor Cyan
    Write-Host "1 - Ambiente Local (AD + Exchange)"
    Write-Host "2 - Cloud (Microsoft 365)"
    Write-Host "3 - Híbrido (AD local + Exchange Online)"
    $opcao = Read-Host "Digite a opção (1, 2 ou 3)"
    return $opcao
}

# Lê ficheiro CSV
if (-Not (Test-Path $csvPath)) {
    Write-Error "Ficheiro CSV não encontrado em: $csvPath"
    exit
}
$users = Import-Csv $csvPath

# Executa função de acordo com a escolha
switch (Mostrar-Menu) {
    "1" {
        Import-Module ActiveDirectory

        foreach ($user in $users) {
            $securePassword = ConvertTo-SecureString $user.Password -AsPlainText -Force

            Write-Host "Criando utilizador $($user.Username) no AD local..." -ForegroundColor Green
            New-ADUser -Name $user.Name `
                       -SamAccountName $user.Username `
                       -UserPrincipalName "$($user.Username)@dominio.local" `
                       -AccountPassword $securePassword `
                       -Enabled $true `
                       -Path $user.OU

            Write-Host "Criando mailbox no Exchange On-Premises..."
            Enable-Mailbox -Identity $user.Username -Database "Mailbox Database"
        }
    }
    "2" {
        Write-Host "Conectando ao Microsoft 365..." -ForegroundColor Yellow
        Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All"

        foreach ($user in $users) {
            $passwordProfile = @{
                ForceChangePasswordNextSignIn = $true
                Password = $user.Password
            }

            Write-Host "Criando utilizador $($user.Username) no Microsoft 365..." -ForegroundColor Green
            New-MgUser -DisplayName $user.Name `
                       -UserPrincipalName "$($user.Username)@seudominio.com" `
                       -MailNickname $user.Username `
                       -AccountEnabled $true `
                       -PasswordProfile $passwordProfile
        }
    }
    "3" {
        Import-Module ActiveDirectory

        foreach ($user in $users) {
            $securePassword = ConvertTo-SecureString $user.Password -AsPlainText -Force

            Write-Host "Criando utilizador $($user.Username) no AD local (modo híbrido)..." -ForegroundColor Green
            New-ADUser -Name $user.Name `
                       -SamAccountName $user.Username `
                       -UserPrincipalName "$($user.Username)@seudominio.com" `
                       -AccountPassword $securePassword `
                       -Enabled $true `
                       -Path $user.OU

            Write-Host "Configurando mailbox remota para Exchange Online..."
            Enable-RemoteMailbox -Identity $user.Username `
                                 -RemoteRoutingAddress "$($user.Username)@seudominio.mail.onmicrosoft.com"
        }

        Write-Host "Sincronizando com Azure AD Connect..." -ForegroundColor Yellow
        Start-ADSyncSyncCycle -PolicyType Delta
    }
    default {
        Write-Error "Opção inválida. Encerrando script."
    }
}

Write-Host "`nProcesso concluído." -ForegroundColor Cyan
