$envPath = Join-Path $PSScriptRoot ..\.env
$envBackupPath = Join-Path $PSScriptRoot ..\.env.backup
If (-not (Test-Path $envPath))
{
    $values = @{}
    Get-Content -Path $envBackupPath | ForEach-Object {
        $line = $_
        If ($line -Match '%([^%]+)%')
        {
            $key = $matches[1]
            If (-not $values.ContainsKey($key))
            {
                $value = Read-Host -Prompt $key.Replace('_', ' ')
                $values[$key] = $value
            }
            $line = $line.Replace("%$key%", $value)
        }
        $line
    } | Out-File $envPath -Encoding ASCII
}

Get-Content -Path $envPath | ForEach-Object {
    if($_.Trim() -and $_ -notmatch '#.*'){
        $parts = $_.Split('=')
        if($parts.length -eq 2){
            [Environment]::SetEnvironmentVariable($parts[0], $parts[1])
        }
    }
}