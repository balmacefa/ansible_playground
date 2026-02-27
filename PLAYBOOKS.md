# Triggering Playbooks

This document explains how to safely trigger each playbook in the Ansible environment.

**Note: Ensure the required containers for a playbook are running via `docker compose` before executing it.** 

The playbooks have been organized into corresponding project folders under the `playbooks/` directory. You can trigger them using the provided wrapper scripts, which **automatically ensure the required Docker Compose profiles are running**:

- **Linux/macOS/Git Bash:** `./run_playbook.sh <playbook_path>`
- **Windows (PowerShell):** `.\run_playbook.ps1 <playbook_path>`

Alternatively, you can trigger them manually via `docker exec` (ensure profiles are up first).

---

## 1. Zookeeper (Day 2 Operations)
**File location:** `playbooks/zookeeper/day2ops.yml`
**Purpose:** Verifies the health and dynamic role (leader, follower, or observer) of the Zookeeper containers by sending direct TCP socket requests.
**Requirements:** `zookeeper` docker profile must be running.

**How to trigger:**
```bash
# Using the helper script
./run_playbook.sh zookeeper/day2ops.yml  # Linux/macOS
.\run_playbook.ps1 zookeeper/day2ops.yml # Windows

# Or directly via docker
docker exec -it ansible-master bash -c "ansible-playbook -i inventory.ini zookeeper/day2ops.yml --limit zookeeper"
```



---

## 3. Rocky Linux (Node Setup)
**File location:** `playbooks/rocky/setup_nodes.yml`
**Purpose:** Applies the initial OS configurations and generic roles applied onto the `node-*` application instances.
**Requirements:** `rocky` docker profile must be running.

**How to trigger:**
```bash
# Using the helper script
./run_playbook.sh rocky/setup_nodes.yml   # Linux/macOS
.\run_playbook.ps1 rocky/setup_nodes.yml  # Windows

# Or directly via docker
docker exec -it ansible-master bash -c "ansible-playbook -i inventory.ini rocky/setup_nodes.yml"
```

---

## 4. Common (OS Patching)
**File location:** `playbooks/common/patching.yml`
**Purpose:** Triggers OS-level package upgrades via `apt` or `yum` on all managed nodes, with automatic server rebooting if OS patches require it.
**Requirements:** Target environment containers must be running.

**How to trigger:**
```bash
# Using the helper script
./run_playbook.sh common/patching.yml   # Linux/macOS
.\run_playbook.ps1 common/patching.yml  # Windows

# Or directly via docker
docker exec -it ansible-master bash -c "ansible-playbook -i inventory.ini common/patching.yml"
```

---

## 5. Main Site Setup
**File location:** `playbooks/site.yml`
**Purpose:** Triggers the comprehensive setup (combines `rocky/setup_nodes.yml` natively).

**How to trigger:**
```bash
# Using the helper script
./run_playbook.sh site.yml   # Linux/macOS
.\run_playbook.ps1 site.yml  # Windows

# Or directly via docker
docker exec -it ansible-master bash -c "ansible-playbook -i inventory.ini site.yml"
---
 
 ## 6. Zookeeper Interaction POC
 **File location:** `playbooks/rocky/zookeeper_poc.yml`
 **Purpose:** Demonstrates Rocky nodes interacting with the Zookeeper layer by creating, reading, and updating node-specific znodes using the `kazoo` library.
 **Requirements:** Both `rocky` and `zookeeper` docker profiles must be running.
 
 **How to trigger:**
 ```bash
 # Using the helper script
 ./run_playbook.sh rocky/zookeeper_poc.yml   # Linux/macOS
 .\run_playbook.ps1 rocky/zookeeper_poc.yml  # Windows
 
 # Or directly via docker
 docker exec -it ansible-master bash -c "ansible-playbook -i inventory.ini rocky/zookeeper_poc.yml"
---
 
 ## 7. Zookeeper Failover Orchestration
 **File location:** `playbooks/rocky/failover_orchestration.yml`
 **Purpose:** Orchestrates a full failover scenario by identifying the current Zookeeper leader, crashing it, and verifying recovery.
 **Requirements:** Both `rocky` and `zookeeper` docker profiles must be running.
 
 **How to trigger:**
 ```bash
 # Using the helper script
 ./run_playbook.sh rocky/failover_orchestration.yml   # Linux/macOS
 .\run_playbook.ps1 rocky/failover_orchestration.yml  # Windows
 
 # Or directly via docker
 docker exec -it ansible-master bash -c "ansible-playbook -i inventory.ini rocky/failover_orchestration.yml"
 ```
