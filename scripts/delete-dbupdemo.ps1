<#
.SYNOPSIS

Deletes the dbupdemo resources

.DESCRIPTION

Deletes all the resources associated with the DbUpDemo to ensure no costs are incurred.

.PARAMETER AWSProfiles

An array of AWS Profiles to remove the DbUpDemo from

.PARAMETER Region

The AWS region to perform the operations in
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

    $dbupStacks = $stacks.StackSummaries | Where-Object StackName -like "dbupdemo-*" | Sort-Object StackName

    if ($dbupStacks.Count -ne 2) {
        Write-Warning "dbupdemo stack count not correct. Expected 2 and found $($dbupStacks.Count)"

        continue;
    }

    foreach ($dbupStack in $dbupStacks) {
        Write-Verbose "Detecting Network interfaces"

        $ni = aws ec2 describe-network-interfaces `
            --profile $AWSProfile `
            --region $Region | ConvertFrom-Json
        
        $dbupni = $ni.NetworkInterfaces | Where-Object { $_.Groups.GroupName -like "dbupdemo-*"}
        
        Write-Verbose "Found $($dbupni.Count) network interfaces"

        Write-Verbose "Deleting the $($dbupStack.StackName)"

        aws cloudformation delete-stack `
            --stack-name $dbupStack.StackName `
            --region $Region `
            --profile $AWSProfile

        Write-Verbose "Waiting for $($dbupStack.StackName) delete to complete"
        aws cloudformation wait stack-delete-complete `
            --stack-name $dbupStack.StackName `
            --region $Region `
            --profile $AWSProfile

        if ($LASTEXITCODE -eq 255) {
            Write-Error "Delete of stack $($dbupStack.Stackname) has failed. Please check the console for details."
            exit 255
        }
        
        if ($dbupni.Count -gt 0) {
            Write-Verbose "Delete the network interfaces"

            foreach ($networkInterface in $dbupni) {
                aws ec2 delete-network-interface `
                    --profile $AWSProfile `
                    --region $Region `
                    --network-interface-id $networkInterface.NetworkInterfaceId
            }
        }
    }
}