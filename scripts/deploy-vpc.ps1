[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("dev", "prod")]
    [String]
    $Environment,

    [Parameter()]
    [String]
    $Region = "ap-southeast-2",

    [Parameter()]
    [string]
    $AWSProfile = $env:AWS_PROFILE,

    [Parameter()]
    [switch]
    $CreateChangesetOnly
)

$cfnPath = Join-Path $PSScriptRoot "../infrastructure/vpc.yml"
$parametersPath = Join-Path $PSScriptRoot "../infrastructure/VPC-Parameters.${Environment}.json"

$cmdParameters = @(
    "--template-file", $cfnPath,
    "--stack-name", "vpc",
    "--capabilities", "CAPABILITY_NAMED_IAM",
    "--parameter-overrides", "file://$parametersPath",
    "--region", $Region,
    "--no-fail-on-empty-changeset",
    "--profile", $AWSProfile
)

if ($CreateChangesetOnly -eq $true) {
    $cmdParameters += "--no-execute-changeset"
    Write-Verbose "Creating changeset only!"
}

Write-Verbose "Deploying cloudformation template $cfnPath, with parameter file $parametersPath"
aws cloudformation deploy @cmdParameters