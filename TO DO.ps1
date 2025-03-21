#Vamos instalar e importar o módulo Azure PowerShell antes de tentar novamente.

#Instale o módulo Azure PowerShell:
#Abra o PowerShell como administrador e execute o seguinte comando para instalar o módulo:

Install-Module -Name Az -AllowClobber -Scope CurrentUser

#Importe o módulo Azure PowerShell: #Depois de instalar o módulo, importe-o:

Import-Module Az

#Autentique-se no Azure: #Agora, você deve ser capaz de se autenticar no Azure:

Connect-AzAccount


#Começa agora o show da xuxa!

# Autentique-se no Azure
Connect-AzAccount

# Defina as variáveis necessárias
# Autentique-se no Azure
Connect-AzAccount

# Defina as variáveis necessárias
$resourceGroupName = "MeuGrupoDeRecursos"
$location = "BrazilSouth"
$vmName = "MinhaVM"
$vhdUri = "https://sourceforge.net/projects/osboxes/files/v/vb/55-U-u/24.10/64bit.7z/download"
$storageAccountName = "meuarmazenamento"
$storageContainerName = "vhds"
$vmSize = "Standard_DS1_v2"
$adminUsername = "adminuser"
$adminPassword = "SenhaSegura123!"
$vnetName = "MinhaVNet"
$subnetName = "MinhaSubnet"
$ipConfigName = "MinhaIPConfig"
$nicName = "MinhaNIC"
$privateIpAddress = "10.0.0.4"

# Crie um grupo de recursos
New-AzResourceGroup -Name $resourceGroupName -Location $location

# Crie uma conta de armazenamento
New-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -Location $location -SkuName "Standard_LRS"

# Obtenha a chave de acesso da conta de armazenamento
$storageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName).Value[0]
$context = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

# Crie um contêiner de armazenamento
New-AzStorageContainer -Name $storageContainerName -Context $context

# Carregue o VHD para o contêiner de armazenamento (se necessário)
Set-AzStorageBlobContent -File "C:\caminho\para\seu\vhd.vhd" -Container $storageContainerName -Blob "meuvhd.vhd" -Context $context

# Crie um disco gerenciado a partir do VHD
$diskConfig = New-AzDiskConfig -AccountType "Standard_LRS" -Location $location -CreateOption "Import" -SourceUri $vhdUri
$disk = New-AzDisk -ResourceGroupName $resourceGroupName -DiskName "MeuDisco" -Disk $diskConfig

#Crie uma rede virtual e uma sub-rede (se não houver ou):
$vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Location $location -Name $vnetName -AddressPrefix "10.0.0.0/16"
$subnet = Add-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix "10.0.0.0/24" -VirtualNetwork $vnet
$vnet | Set-AzVirtualNetwork

# Obtenha a VNet e a Subnet existentes:
$vnet = Get-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Name $vnetName
$subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $subnetName


#Crie uma interface de rede com um IP privado:
$nic = New-AzNetworkInterface -ResourceGroupName $resourceGroupName -Location $location -Name $nicName -SubnetId $subnet.Id -PrivateIpAddress $privateIpAddress


# Crie a configuração da VM
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize | `
    Set-AzVMOperatingSystem -Linux -ComputerName $vmName -Credential (New-Object System.Management.Automation.PSCredential($adminUsername, (ConvertTo-SecureString $adminPassword -AsPlainText -Force))) | `
    Set-AzVMSourceImage -Id $disk.Id | `
    Add-AzVMNetworkInterface -Id $nic.Id

# Crie a VM
New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $vmConfig

# Destrua o contêiner de blob
Remove-AzStorageContainer -Name $storageContainerName -Context $context

