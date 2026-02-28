param (
    [Parameter(Mandatory=$false)]
    [string]$Playbook,
    
    [Parameter(Mandatory=$false)]
    [int]$NodesCount = 4
)

# If no playbook is provided, show interactive menu
if ([string]::IsNullOrWhiteSpace($Playbook)) {
    while ($true) {
        Write-Host "`n--- Ansible Playbook Interactive Selector ---" -ForegroundColor Cyan
        
        # Discovery: Find all .yml and .yaml files in playbooks directory
        $playbooksPath = Join-Path (Get-Location).Path "playbooks"
        $playbookFiles = Get-ChildItem -Path $playbooksPath -Filter "*.yml" -Recurse | Where-Object { 
            $_.FullName -notmatch "group_vars" -and 
            $_.FullName -notmatch "roles" -and
            $_.FullName -notmatch "tasks"  # Exclude task fragments
        } | Select-Object -ExpandProperty FullName

        # Convert absolute paths to relative paths (relative to 'playbooks' directory)
        $relativePlaybooks = $playbookFiles | ForEach-Object {
            $_.Replace($playbooksPath + "\", "").Replace("\", "/")
        }

        # Display menu
        for ($i = 0; $i -lt $relativePlaybooks.Count; $i++) {
            Write-Host ("[{0}] {1}" -f ($i + 1), $relativePlaybooks[$i])
        }
        Write-Host "[N] Set Node Count (Current: $NodesCount)" -ForegroundColor Green
        Write-Host "[T] Tear Down Project" -ForegroundColor Yellow
        Write-Host "[Q] Quit" -ForegroundColor Red

        # Get user selection
        $selection = Read-Host "`nSelect a playbook number, 'N' for Node Count, 'T' for Tear Down, or 'Q' to Quit"
        
        if ($selection -eq "Q") { return }
        
        if ($selection -eq "N") {
            $nodesInput = Read-Host "`nEnter the new number of Rocky nodes"
            if (-not [string]::IsNullOrWhiteSpace($nodesInput) -and [int]::TryParse($nodesInput, [ref]$NodesCount) -and $NodesCount -gt 0) {
                Write-Host "Node count updated to $NodesCount." -ForegroundColor Green
            } else {
                Write-Host "Invalid input. Node count remains $NodesCount." -ForegroundColor Red
            }
            continue
        }
        
        if ($selection -eq "T") {
            Write-Host "`n--- Tear Down Menu ---" -ForegroundColor Yellow
            Write-Host "[1] All Profiles"
            Write-Host "[2] Rocky Linux (rocky)"
            Write-Host "[3] Zookeeper (zookeeper)"
            Write-Host "[4] Cancel (Back to Playbooks)"
            
            $tdSelection = Read-Host "`nSelect tear down option"
            
            switch ($tdSelection) {
                "1" { 
                    Write-Host "Tearing down all profiles..." -ForegroundColor Red
                    docker compose --profile rocky --profile zookeeper down
                }
                "2" { 
                    Write-Host "Tearing down Rocky profile..." -ForegroundColor Red
                    docker compose --profile rocky down 
                }
                "3" { 
                    Write-Host "Tearing down Zookeeper profile..." -ForegroundColor Red
                    docker compose --profile zookeeper down 
                }
                "4" { continue }
                default { Write-Host "Invalid selection." -ForegroundColor Red }
            }
            continue # Go back to main menu after action or invalid selection
        }

        $index = 0
        if (-not [int]::TryParse($selection, [ref]$index) -or $index -lt 1 -or $index -gt $relativePlaybooks.Count) {
            Write-Host "Invalid selection: '$selection'." -ForegroundColor Red
            continue
        }

        $Playbook = $relativePlaybooks[$index - 1]
        break # Exit loop to run the playbook
    }
} else {
    # If a path was provided, ensure it's relative to 'playbooks/' for the container
    $Playbook = $Playbook.Replace("playbooks/", "").Replace("playbooks\", "").Replace("\", "/")
}

# Define profile mapping based on directory/filename
$requiredProfiles = @()

if ($Playbook -match "zookeeper") { $requiredProfiles += "zookeeper" }
if ($Playbook -match "rocky") { $requiredProfiles += "rocky" }
if ($Playbook -match "failover_orchestration") { $requiredProfiles += "zookeeper" }
if ($Playbook -eq "site.yml" -or $Playbook -match "site.yml") { 
    $requiredProfiles += "rocky"
}

# Always ensure ansible-master is running
Write-Host "Checking if ansible-master is running..." -ForegroundColor Cyan
$masterStatus = docker inspect -f '{{.State.Running}}' ansible-master 2>$null
if ($masterStatus -ne "true") {
    Write-Host "Starting ansible-master..." -ForegroundColor Yellow
    docker compose up -d ansible-master
}

# Dynamically generate inventory.ini
$inventoryContent = "[nodes]`n"
for ($n = 1; $n -le $NodesCount; $n++) {
    $inventoryContent += "ansible-node-$n`n"
}
$inventoryContent += "`n[zookeeper]`nzookeeper-1`nzookeeper-2`nzookeeper-3`nzookeeper-4`n`n[zookeeper_nodes]`nzookeeper-1`nzookeeper-2`nzookeeper-3`nzookeeper-4`n"
Set-Content -Path "playbooks/inventory.ini" -Value $inventoryContent

# Ensure required profiles are running
foreach ($profile in ($requiredProfiles | Select-Object -Unique)) {
    Write-Host "Ensuring profile '$profile' is active..." -ForegroundColor Cyan
    if ($profile -eq "rocky") {
        docker compose --profile rocky up --scale node=$NodesCount -d
    } else {
        docker compose --profile $profile up -d
    }
}

# Ensure SSH connectivity (Keys are shared via Docker volume)
if ($requiredProfiles -contains "rocky" -or $Playbook -eq "site.yml" -or $Playbook -match "site.yml") {
    Write-Host "SSH connectivity secured via shared keys volume." -ForegroundColor Cyan
}

docker exec -e ANSIBLE_CONFIG=/playbooks/ansible.cfg ansible-master ansible-playbook -i inventory.ini "$Playbook"
