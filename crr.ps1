Set-azcontext -subscription 'b7928846-97b8-447d-b04d-0cabfa86e1e2'
$srcRgName = 'RG_CI-5047_PROD_002'
$dstRgName = 'RG_CI-5047_PROD_006'
$srcAccount = 'khaz-eus2-sap-prod-anf-001'
$dstAccount = 'khaz-wus2-sap-prodreg-anf-001'
$srcPool = 'khaz-eus2-sap-prod-anfp-001'
$dstPool = 'khaz-wus2-sap-proddr-anfp-001'

$dstRg = Get-AzResourceGroup -Name $dstRgName

$volumes = Get-AzNetAppFilesVolume -ResourceGroupName $srcRgName -AccountName $srcAccount -PoolName $srcPool

$volumes | ForEach-Object {
    if ($_.Name -like "*-APP*") {
        Write-Host $_.Name.Split('/')[2] "is APP, creating data replication." -ForegroundColor DarkGreen -BackgroundColor Black

        $srcVolume = Get-AzNetAppFilesVolume -ResourceGroupName $srcRgName -AccountName $srcAccount -PoolName $srcPool -VolumeName $_.Name.Split('/')[2]

        $checkTarget = Get-AzResource -Name $_.Name.Split('/')[2] -ResourceGroupName $dstRgName

        if ($checkTarget -eq $null) {
            $DataReplication = New-Object -TypeName Microsoft.Azure.Commands.NetAppFiles.Models.PSNetAppFilesReplicationObject -Property @{EndpointType = "dst"; RemoteVolumeRegion = $srcVolume.Location; RemoteVolumeResourceId = $srcVolume.Id; ReplicationSchedule = "_10minutely" }

            Write-Host " Creating Destination Volume for" $_.Name.Split('/')[2]
            $dstVolume = New-AzNetAppFilesVolume -ResourceGroupName $dstRg.ResourceGroupName `
                -Location $dstRg.Location `
                -AccountName $dstAccount `
                -PoolName $dstPool `
                -Name $srcVolume.Name.Split('/')[2] `
                -UsageThreshold $srcVolume.UsageThreshold `
                -ProtocolType $srcVolume.ProtocolTypes `
                -ServiceLevel $srcVolume.ServiceLevel `
                -SubnetId '/subscriptions/b7928846-97b8-447d-b04d-0cabfa86e1e2/resourceGroups/KHAZEA-WUS2-RG-INFRA-NETWORK-001-PROD/providers/Microsoft.Network/virtualNetworks/KHAZ-WUS2-KEYSTONE-PROD-VNET-001_10.250.40.0_22/subnets/KHAZEA-WUS2-CI-5047-PRODREG-SNET-ANF-001_10.250.40.224_27' `
                -CreationToken $srcVolume.CreationToken `
                -ExportPolicy $srcVolume.ExportPolicy `
                -ReplicationObject $DataReplication `
                -VolumeType "DataProtection"
            Write-Host "  Created."

            Write-Host " Authorizing replication for" $_.Name.Split('/')[2]
            Approve-AzNetAppFilesReplication -ResourceGroupName $srcRgName  `
                -AccountName $srcAccount `
                -PoolName $srcPool `
                -Name $srcVolume.Name.Split('/')[2] `
                -DataProtectionVolumeId $($dstVolume.Id)
            Write-Host "  Authorized.`n"
        }
        else {
            Write-Host $_.Name.Split('/')[2] "data replication already exists.`n" -ForegroundColor Yellow -BackgroundColor Black
        }

 
    }
    else {
        Write-Host $_.Name.Split('/')[2] "is not APP, skipping.`n" -ForegroundColor Red -BackgroundColor Black
    }
}


