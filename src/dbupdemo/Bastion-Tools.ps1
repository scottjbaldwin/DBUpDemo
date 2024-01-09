<#
.SYNOPSIS
    Deploys the Bastion Stack to the environment
.DESCRIPTION
    Deploys a single basion host and corresponding infrastructure
.NOTES
    Only one bastion host is required per environment
.EXAMPLE
    Deploy-BastionStack -Verbose

    Deploys the bastion stack to the environment
#>
function Deploy-BastionStack {
    param (
        # Environment for Bastion Stack Name
        [ValidateSet('develop', 'test', 'staging', 'prod')]
        [string]
        $Environment = "develop",

        [Parameter()]
        [string]
        $Region = "ap-southeast-2"
    )

    $stackName = "$Environment-bastion"
    $templatePath = ".\src\ropp\bastionhost.yml"

    Write-Verbose "Verifying Cloudformation Template at $templatePath"

    cfn-lint $templatePath

    $paramOverridesJson = @(
        @{ParameterKey = "Environment"; ParameterValue = $Environment }
    ) | ConvertTo-Json -AsArray

    Write-Verbose $paramOverridesJson

    Write-Verbose "Deploying stack $stackName"
    aws cloudformation deploy `
        --stack-name $stackName `
        --capabilities CAPABILITY_IAM `
        --parameter-overrides $paramOverridesJson `
        --template-file $templatePath `
        --region $Region
}

<#
.SYNOPSIS
    Starts a SSM Session for port forwarding to RDS
.DESCRIPTION
    Starts a SSM Session for port forwarding a local port to the RDS endpoint.
    The session must be left open while you connect to the database.
    Press CTRL+C to exit.
.NOTES
    Requires the SSM Session Manager Plugin - https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html
.EXAMPLE
    Open-SSMSession -Stack $env:ROPPStack -Verbose

    Opens a SSM Session to your local stack.
.EXAMPLE
    Open-SSMSession -Environment staging -LocalPort 3309 -Verbose

    Opens a SSM Session to an environment.
#>
function Open-SSMSession {
    param(
        [Parameter(Mandatory=$True)]
        [string]
        $Endpoint,

        [Parameter()]
        [ValidateSet('develop', 'test', 'staging', 'prod')]
        [string]
        $Environment = "develop",

        # Remote Port to connect to
        [Parameter()]
        [int]
        $PortNumber = 3306,

        # Local Port to connect to
        [Parameter()]
        [int]
        $LocalPort = 3306,

        [Parameter()]
        [string]
        $Region = "ap-southeast-2",

        # Stops the bastion host after the SSM session has been closed
        [Parameter()]
        [switch]
        $StopInstanceAfterwards = $false
    )

    Write-Verbose "Getting instance id of bastion host from bastion"
    $instanceId = aws cloudformation describe-stack-resource --stack-name "bastion" `
        --logical-resource-id BastionEc2Instance --query 'StackResourceDetail.PhysicalResourceId' --output text

    Write-Verbose "Instance ID is $instanceId"

    Write-Verbose "Starting instance (if not already running)"
    aws ec2 start-instances --instance-ids $instanceId | Out-Null

    Write-Verbose "Waiting for $instanceId to be in a ready state"
    aws ec2 wait instance-running --instance-ids $instanceId

    $paramOverridesJson = @{
        host            = @($Endpoint)
        portNumber      = @("$PortNumber")
        localPortNumber = @("$LocalPort")
    } | ConvertTo-Json

    Write-Verbose "Opening tunnel from localhost:$LocalPort to ${Endpoint}:$PortNumber on $env:AWS_PROFILE"

    try {
        aws ssm start-session `
            --target $instanceId `
            --region ap-southeast-2 `
            --document-name AWS-StartPortForwardingSessionToRemoteHost `
            --parameters $paramOverridesJson
    }
    finally {
        if ($StopInstanceAfterwards) {
            Write-Verbose "Stopping instance $instanceId"
            aws ec2 stop-instances --instance-ids $instanceId | Out-Null
        }
    }
}
