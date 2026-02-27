param (
    [Parameter(Mandatory=$true)]
    [string]$Playbook
)

# Define profile mapping based on directory/filename
$requiredProfiles = @()

if ($Playbook -match "zookeeper") { $requiredProfiles += "zookeeper" }
if ($Playbook -match "postgres") { $requiredProfiles += "postgres" }
if ($Playbook -match "rocky") { $requiredProfiles += "rocky" }
if ($Playbook -match "failover_orchestration") { $requiredProfiles += "zookeeper" }
if ($Playbook -eq "site.yml") { 
    $requiredProfiles += "rocky"
    $requiredProfiles += "postgres" 
}

# Always ensure ansible-master is running
Write-Host "Checking if ansible-master is running..." -ForegroundColor Cyan
$masterStatus = docker inspect -f '{{.State.Running}}' ansible-master 2>$null
if ($masterStatus -ne "true") {
    Write-Host "Starting ansible-master..." -ForegroundColor Yellow
    docker compose up -d ansible-master
}

# Ensure required profiles are running
foreach ($profile in ($requiredProfiles | Select-Object -Unique)) {
    Write-Host "Ensuring profile '$profile' is active..." -ForegroundColor Cyan
    # Check if at least one container for this profile is running
    # This is a bit complex via CLI, so we just run 'up -d' which is idempotent
    docker compose --profile $profile up -d
}

Write-Host "Running playbook: $Playbook inside ansible-master container..." -ForegroundColor Green
docker exec -it ansible-master ansible-playbook -i inventory.ini "$Playbook"
