<#
.SYNOPSIS

Deploys cross account infrastructure for the codepipeline.

.DESCRIPTION

Deploys a stack set into the build account that manages the cross account
roles used to deploy the application into the environments. NOTE this script uses
SELF-MANAGED permissions role and expects the appropriate roles to be in place
in the administator and target accounts.

.PARAMETER ProjectName

The name of the project.

.PARAMETER AWSProfile

The AWS profile to use to deploy the stackset. NOTE this should be a profile
tied to thebuild account.

.PARAMETER DevAccountNo

The AWS Account Number for the Dev account

.PARAMETER ProdAccountNo

The AWS Account Number for the Prod account

.PARAMETER CloudFormationBucket

The bucket to upload the cloudformation to during deployment. Defaults
to <accountno>-cloudformation based on the account of the AWS profile 
being used to execute the script.

.PARAMETER Region

The region to deploy the cloudformation to

#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $ProjectName = "dbupdemo",

    [Parameter()]
    [string]
    $AWSProfile = $env:AWS_PROFILE,

    [Parameter(Mandatory=$true)]
    [string]
    $DevAccountNo,

    [Parameter(Mandatory=$true)]
    [string]
    $ProdAccountNo,

    [Parameter()]
    [string]
    $CloudFormationBucket="$((aws sts get-caller-identity --profile $AWSProfile | ConvertFrom-Json).Account)-cloudformation",

    [Parameter()]
    [string]
    $Region = "ap-southeast-2"
)

$stackSetName = "$ProjectName-CrossAccountRoles"
$buildAccountNo = (aws sts get-caller-identity --profile $AWSProfile | ConvertFrom-Json).Account
$templateBody = Get-Content (Join-Path $PSScriptRoot "..\pipeline\CrossAccountCFNRole.yml") -Raw

$baseInfraStackInfo = aws cloudformation describe-stacks `
    --stack-name "$ProjectName-BaseInfrastructure" `
    --region $Region | ConvertFrom-Json

$operationPreferences = @{
    RegionConcurrencyType="PARALLEL";
    FailureToleranceCount=1;
    MaxConcurrentCount=2
} | ConvertTo-Json

$kmsKey = ($baseInfraStackInfo.Stacks[0].Outputs | Where OutputKey -eq "ArtefactKMSKey").OutputValue
$cfnParams = @(
    @{
        ParameterKey="ProjectName";
        ParameterValue=$ProjectName
    },
    @{
        ParameterKey="BuildAccountNo";
        ParameterValue=$buildAccountNo
    },
    @{
        ParameterKey="ArtefactKMSKeyArn";
        ParameterValue=$kmsKey
    }
) | ConvertTo-Json

$stackSetInfo = aws cloudformation list-stack-sets `
    --status ACTIVE `
    --region $Region | ConvertFrom-Json

if (($stackSetInfo.Summaries | where StackSetName -eq $stackSetName).Count -eq 0){
    Write-Verbose "Creating new stackset $stackSetName"

    aws cloudformation create-stack-set `
        --stack-set-name $stackSetName `
        --capabilities CAPABILITY_NAMED_IAM `
        --template-body $templateBody `
        --parameters $cfnParams `
        --region $Region

    aws cloudformation create-stack-instances `
        --stack-set-name $stackSetName `
        --accounts $DevAccountNo $ProdAccountNo `
        --regions $Region `
        --operation-preferences $operationPreferences `
        --region $Region
}
else {
    Write-Verbose "Updateing existing stackset $stackSetName"

    aws cloudformation update-stack-set `
        --stack-set-name $stackSetName `
        --capabilities CAPABILITY_NAMED_IAM `
        --template-body $templateBody `
        --parameters $cfnParams `
        --operation-preferences $operationPreferences `
        --region $Region
}