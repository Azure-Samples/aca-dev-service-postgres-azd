$output = azd env get-values

foreach ($line in $output) {
  if (!$line.Contains('=')) {
    continue
  }

  $name, $value = $line.Split("=")
  $value = $value -replace '^\"|\"$'
  [Environment]::SetEnvironmentVariable($name, $value)
}

Write-Host "Exec: az containerapp exec -n $env:PSQL_CLI_APP_NAME -g $env:RESOURCE_GROUP --command /bin/bash"
Write-Host "Url: $env:PGWEB_URL"
