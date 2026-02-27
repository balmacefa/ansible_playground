# Ansible Docker Playground

This project provides a comprehensive, multi-node Docker-based development environment for writing and testing Ansible playbooks locally. It simulates a real-world infrastructure with an Ansible control node (master), Rocky Linux application nodes, a PostgreSQL database cluster, and a Zookeeper ensemble.

## Architecture

The environment spins up multiple containers within dedicated Docker networks:

*   **1x Ansible Master (`ansible-master`)**: The control node where Ansible is executed. The local `./playbooks` directory is volume-mounted here for live editing.
*   **4x Application Nodes (`node-1` to `node-4`)**: Rocky Linux containers that act as target hosts for general configuration and application deployment.
*   **4x Database Nodes (`db-1` to `db-4`)**: PostgreSQL containers set up with built-in replication (1 master, 3 replicas).
*   **4x Zookeeper Nodes (`zookeeper-1` to `zookeeper-4`)**: A complete Zookeeper ensemble (leader, 2 followers, 1 observer) for distributed coordination testing.
*   **1x Zookeeper Proxy (`zookeeper-proxy`)**: An HAProxy container providing a single entry point to the Zookeeper cluster.

## Docker Compose Profiles

To conserve local resources, the environment uses Docker Compose profiles. You do not need to start every container if you are only working on a specific part of the infrastructure.

### Available Profiles
*   **`rocky`**: Starts the 4 Rocky Linux application nodes.
*   **`postgres`**: Starts the 4 PostgreSQL databases.
*   **`zookeeper`**: Starts the 4 Zookeeper nodes and the Zookeeper proxy.

### How to Start the Environment

*   **Start only the Ansible Master (minimal):**
    ```bash
    docker compose up -d
    ```
*   **Start Master + a specific profile (e.g., Rocky nodes):**
    ```bash
    docker compose --profile rocky up -d
    ```
*   **Start everything:**
    ```bash
    docker compose --profile rocky --profile postgres --profile zookeeper up -d
    ```

## Triggering Playbooks

The preferred way to run playbooks is using the provided wrapper scripts. These scripts **automatically detect which Docker profiles are required** for a given playbook, start them if they are not running, and then execute the playbook inside the `ansible-master` container.

### Using the Interactive Menu (Windows)
On Windows, you can simply run the PowerShell script without any arguments to get an interactive selection menu:

```powershell
.\run_playbook.ps1
```
This menu will list all available playbooks, allow you to select one to run, or give you the option to safely tear down active Docker profiles.

### Running a Specific Playbook Directly

**Windows (PowerShell):**
```powershell
.\run_playbook.ps1 -Playbook "site.yml"
```

**Linux/macOS (Bash):**
```bash
./run_playbook.sh site.yml
```

Alternatively, you can trigger them manually via `docker exec` (ensure the required profiles are up first):
```bash
docker exec -it ansible-master bash -c "ansible-playbook -i inventory.ini site.yml"
```

## Available Playbooks & Capabilities

This playground includes several functional playbooks demonstrating advanced Ansible capabilities and infrastructure orchestration. 

For a complete breakdown of each playbook and its specific requirements, refer to the [PLAYBOOKS.md](./PLAYBOOKS.md) document. Key highlights include:

*   **Database Setup (`postgres/setup_dbs.yml`)**: Configures PostgreSQL databases.
*   **Node Setup (`rocky/setup_nodes.yml`)**: Applies basic OS configurations.
*   **OS Patching (`common/patching.yml`)**: OS-level package upgrades with automated reboot handling.
*   **Zookeeper Failover Orchestration (`rocky/failover_orchestration.yml`)**: A complex Proof of Concept (POC) that demonstrates application resilience by identifying the Zookeeper leader, crashing it, and verifying that Rocky Linux application nodes seamlessly recover and reconnect via the Zookeeper proxy.
