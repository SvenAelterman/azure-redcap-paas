# PowerShell script to deploy the main.bicep template with parameter values

#Requires -Modules "Az.Resources"
#Requires -Version 7.4

# Use these parameters to customize the deployment instead of modifying the default parameter values
[CmdletBinding()]
Param(
    # [Parameter(Position = 1)]
    # [string]$Location,
    [Parameter()]
    [string]$TemplateParameterFile = "./main.bicepparam",
    [Parameter()]
    [string]$ResourceGroupName = 'redcapdss-network-test-rg-canadacentral-01'
)

# Define common parameters for the New-AzDeployment cmdlet
[hashtable]$CmdLetParameters = @{
    # Location     = $Location
    TemplateFile = './appGateway.bicep'
}

$CmdLetParameters.Add('TemplateParameterFile', $TemplateParameterFile)
$CmdLetParameters.Add('ResourceGroup', $ResourceGroupName)

# Read the values from the parameters file, to use when generating the $DeploymentName value
[string]$WorkloadName = 'AppGW'
[string]$Environment = 'test'

# Generate a unique name for the deployment
[string]$DeploymentName = "$WorkloadName-$Environment-$(Get-Date -Format 'yyyyMMddThhmmssZ' -AsUTC)"
$CmdLetParameters.Add('Name', $DeploymentName)

# Execute the deployment
$DeploymentResult = New-AzResourceGroupDeployment @CmdLetParameters

# Evaluate the deployment results
if ($DeploymentResult.ProvisioningState -eq 'Succeeded') {
    Write-Host "🔥 Deployment succeeded."

    $DeploymentResult.Outputs | Format-Table -Property Key, @{Name = 'Value'; Expression = { $_.Value.Value } }
}
else {
    $DeploymentResult
}