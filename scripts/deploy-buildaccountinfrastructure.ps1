<#
.SYNOPSIS

Script to deploy the build account infrastructure

.DESCRIPTION

This script allows for easy deployment of the Pipeline. 
It assumes you have the AWS cli installed, and have the necessary permissions
to deploy cloudformation templates to the build or tools account.

.PARAMETER ProjectName

The name of the project the infrastructure is for

.PARAMETER AWSProfile

The AWS profile to use to execute the aws cli command. This defaults to the current 
AWS_PROFILE environment variable

.PARAMETER CloudFormationBucket

The bucket to upload the cloudformation to during deployment. Defaults
to <accountno>-cloudformationbased on the account of the AWS profile 
being used to execute the script.

.PARAMETER KMSKeyAdministratorArn

The arn the IAM user or role that should be set up as the KMS Key administrator.
This will default to the ARN aof the calling user if not specified.

.PARAMETER Region

The region to deploy the cloudformation to

.PARAMETER CreateChangeSetOnly

Switch to only create the changeset and wait for review, but not execute the changeset.
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
    $KMSKeyAdministratorArn="$((aws sts get-caller-identity --profile $AWSProfile | ConvertFrom-Json).Arn)",

    [Parameter()]
    [string]
    $Region = "ap-southeast-2",

    [Parameter()]
    [switch]
    $CreateChangeSetOnly
)

$cfnPath = Join-Path $PSScriptRoot "..\Pipeline\BuildAccountBaseInfrastructure.yml"
Write-Verbose "cfn path is $cfnPath"

if (-not (Test-Path $cfnPath)) {
    throw "Unable to locate cloudformation template"
}

$cliParameters = @()

if ($CreateChangeSetOnly) {
    $cliParameters += "--no-execute-changeset"
}

# deploy to AWS

aws cloudformation deploy `
    --template-file $cfnPath `
    --s3-bucket $CloudFormationBucket `
    --s3-prefix "$ProjectName-BaseInfrastructure" `
    --stack-name "$ProjectName-BaseInfrastructure" `
    --capabilities CAPABILITY_NAMED_IAM `
    --region $Region `
    --no-fail-on-empty-changeset `
    --profile $AWSProfile `
    --parameter-overrides ProjectName=$ProjectName DevAccountNo=$DevAccountNo ProdAccountNo=$ProdAccountNo KeyAdministratorArn=$KMSKeyAdministratorArn `
    @cliParameters