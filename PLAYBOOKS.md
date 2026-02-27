# Triggering Playbooks

This document explains how to safely trigger each playbook in the Ansible environment.

**Note: Ensure the required containers for a playbook are running via `docker compose` before executing it.** 

The playbooks have been organized into corresponding project folders under the `playbooks/` directory. You can trigger them either through `docker exec` manually, or using the `./run_playbook.sh` wrapper script.

---

## 1. Zookeeper (Day 2 Operations)
**File location:** `playbooks/zookeeper/day2ops.yml`
**Purpose:** Verifies the health and dynamic role (leader, follower, or observer) of the Zookeeper containers by sending direct TCP socket requests.
**Requirements:** `zookeeper` docker profile must be running.

**How to trigger:**
```bash
# Using the helper script
./run_playbook.sh playbooks/zookeeper/day2ops.yml

# Or directly via docker
docker exec -it ansible-master bash -c "ansible-playbook -i playbooks/inventory.ini playbooks/zookeeper/day2ops.yml --limit zookeeper"
```

---

## 2. Postgres (Database Setup)
**File location:** `playbooks/postgres/setup_dbs.yml`
**Purpose:** Sets up and configures the PostgreSQL databases using the `db_setup` role.
**Requirements:** `postgres` docker profile must be running.

**How to trigger:**
```bash
# Using the helper script
./run_playbook.sh playbooks/postgres/setup_dbs.yml

# Or directly via docker
docker exec -it ansible-master bash -c "ansible-playbook -i playbooks/inventory.ini playbooks/postgres/setup_dbs.yml"
```

---

## 3. Rocky Linux (Node Setup)
**File location:** `playbooks/rocky/setup_nodes.yml`
**Purpose:** Applies the initial OS configurations and generic roles applied onto the `node-*` application instances.
**Requirements:** `rocky` docker profile must be running.

**How to trigger:**
```bash
# Using the helper script
./run_playbook.sh playbooks/rocky/setup_nodes.yml

# Or directly via docker
docker exec -it ansible-master bash -c "ansible-playbook -i playbooks/inventory.ini playbooks/rocky/setup_nodes.yml"
```

---

## 4. Common (OS Patching)
**File location:** `playbooks/common/patching.yml`
**Purpose:** Triggers OS-level package upgrades via `apt` or `yum` on all managed nodes, with automatic server rebooting if OS patches require it.
**Requirements:** Target environment containers must be running.

**How to trigger:**
```bash
# Using the helper script
./run_playbook.sh playbooks/common/patching.yml

# Or directly via docker
docker exec -it ansible-master bash -c "ansible-playbook -i playbooks/inventory.ini playbooks/common/patching.yml"
```

---

## 5. Main Site Setup
**File location:** `playbooks/site.yml`
**Purpose:** Triggers the comprehensive setup (combines `rocky/setup_nodes.yml` and `postgres/setup_dbs.yml` natively).

**How to trigger:**
```bash
# Using the helper script
./run_playbook.sh playbooks/site.yml

# Or directly via docker
docker exec -it ansible-master bash -c "ansible-playbook -i playbooks/inventory.ini playbooks/site.yml"
```
