<#
.SYNOPSIS

Deletes the VPC stack

.DESCRIPTION

Delete the VPC stacks in the accounts accessed by the profiles passed in
#>
[CmdletBinding()]
param (
    [Parameter()]
    [string[]]
    $AWSProfiles=@($env:AWS_PROFILE),

    [Parameter()]
    [string]
    $Region = "ap-southeast-2"
)

foreach ($AWSProfile in $AWSProfiles) {
    Write-Verbose "Using profile $AWSProfile"

    $stacks = aws cloudformation list-stacks `
    --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE `
    --region $Region `
    --profile $AWSProfile | ConvertFrom-Json

    $vpcStack = $stacks.StackSummaries | Where-Object StackName -eq "vpc"

    if ($vpcStack.Count -lt 1) {
        Write-Warning "Could not find VPC stack for profile $AWSProfile"
        continue
    }

    Write-Verbose "Deleting the vpc stack for profile $AWSProfile"
    aws cloudformation delete-stack `
        --stack-name "vpc" `
        --region $Region `
        --profile $AWSProfile

    Write-Verbose "Waiting for vpc stack delete to complete"
    aws cloudformation wait stack-delete-complete `
        --stack-name "vpc" `
        --region $Region `
        --profile $AWSProfile
}