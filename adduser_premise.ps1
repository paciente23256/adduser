# Importa o módulo do Active Directory
Import-Module ActiveDirectory

# Parâmetros do utilizador
$nome = "João Silva"
$utilizador = "jsilva"
$password = ConvertTo-SecureString "SenhaForte123!" -AsPlainText -Force
$ou = "OU=Colaboradores,DC=empresa,DC=local"
$email = "$utilizador@empresa.local"

# Cria o utilizador no AD
New-ADUser -Name $nome -SamAccountName $utilizador -UserPrincipalName $email `
    -AccountPassword $password -Path $ou -Enabled $true

# Cria a mailbox (Exchange local)
Enable-Mailbox -Identity $utilizador -Database "Mailbox Database"
