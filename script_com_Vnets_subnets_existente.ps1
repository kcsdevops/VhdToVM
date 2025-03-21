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
$nicName = "MinhaNIC"
$privateIpAddress = "10.0.0.4"
$diskSizeGB = 2560 # 2.5 TB in GB
$tags = @{
    "Environment" = "Production"
    "Department" = "IT"
    "Project" = "Migration"
    "Owner" = "Admin"
    "CostCenter" = "12345"
    "Application" = "WebApp"
    "Compliance" = "Yes"
    "Backup" = "Enabled"
}

# Crie um grupo de recursos (se necessário)
New-AzResourceGroup -Name $resourceGroupName -Location $location -Tag $tags

# Crie uma conta de armazenamento
New-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -Location $location -SkuName "Standard_LRS" -Tag $tags

# Obtenha a chave de acesso da conta de armazenamento
$storageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName).Value[0]
$context = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

# Crie um contêiner de armazenamento
New-AzStorageContainer -Name $storageContainerName -Context $context

# Carregue o VHD para o contêiner de armazenamento (se necessário)
Set-AzStorageBlobContent -File "C:\caminho\para\seu\vhd.vhd" -Container $storageContainerName -Blob "meuvhd.vhd" -Context $context

# Crie um disco gerenciado a partir do VHD
$diskConfig = New-AzDiskConfig -AccountType "Standard_LRS" -Location $location -CreateOption "Import" -SourceUri $vhdUri
$disk = New-AzDisk -ResourceGroupName $resourceGroupName -DiskName "MeuDisco" -Disk $diskConfig -Tag $tags

# Obtenha a VNet e a Subnet existentes
$vnet = Get-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Name $vnetName
$subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $subnetName

# Crie uma interface de rede com um IP privado
$nic = New-AzNetworkInterface -ResourceGroupName $resourceGroupName -Location $location -Name $nicName -SubnetId $subnet.Id -PrivateIpAddress $privateIpAddress -Tag $tags

# Crie a configuração da VM
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize | `
    Set-AzVMOperatingSystem -Linux -ComputerName $vmName -Credential (New-Object System.Management.Automation.PSCredential($adminUsername, (ConvertTo-SecureString $adminPassword -AsPlainText -Force))) | `
    Set-AzVMSourceImage -Id $disk.Id | `
    Add-AzVMNetworkInterface -Id $nic.Id

# Crie a VM
New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $vmConfig -Tag $tags

# Destrua o contêiner de blob
Remove-AzStorageContainer -Name $storageContainerName -Context $context
