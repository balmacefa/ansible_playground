# Ansible Docker Playground

This project provides a comprehensive, multi-node Docker-based development environment for writing and testing Ansible playbooks locally. It simulates a real-world infrastructure with an Ansible control node (master), Rocky Linux application nodes, and a Zookeeper ensemble.

## Executive Summary (For Management)

This project serves as a local testing ground and demonstration environment for modern IT automation and high availability concepts. It is designed to simulate a real-world enterprise infrastructure in a safe, controlled way.

**Key Business Values:**
*   **Risk-Free Testing:** Allows engineers to test complex infrastructure changes, OS upgrades, and failover scenarios in a safe, isolated environment before applying them to production systems.
*   **Automated Operations:** Showcases the power of Ansible to configure servers, apply security patches, and manage applications automatically, significantly reducing manual effort and human error.
*   **High Availability & Resilience:** Demonstrates how modern architectures recover automatically from server crashes. Utilizing tools like Zookeeper, the system can automatically reroute traffic and maintain operations without human intervention.
*   **Training & Onboarding:** Provides a hands-on sandbox for new team members to learn about containerization, automation, and distributed systems safely.

In short, this playground helps the engineering team build more reliable systems, deploy faster, and validate disaster recovery plans with zero risk to live business operations.

## Technical Architecture

The environment spins up multiple containers within dedicated Docker networks:

*   **1x Ansible Master (`ansible-master`)**: The control node where Ansible is executed. The local `./playbooks` directory is volume-mounted here for live editing.
*   **4x Application Nodes (`node-1` to `node-4`)**: Rocky Linux containers that act as target hosts for general configuration and application deployment.
*   **4x Zookeeper Nodes (`zookeeper-1` to `zookeeper-4`)**: A complete Zookeeper ensemble (leader, 2 followers, 1 observer) for distributed coordination testing.
*   **1x Zookeeper Proxy (`zookeeper-proxy`)**: An HAProxy container providing a single entry point to the Zookeeper cluster.

## Docker Compose Profiles

To conserve local resources, the environment uses Docker Compose profiles. You do not need to start every container if you are only working on a specific part of the infrastructure.

### Available Profiles
*   **`rocky`**: Starts the 4 Rocky Linux application nodes.
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
    docker compose --profile rocky --profile zookeeper up -d
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

*   **Node Setup (`rocky/setup_nodes.yml`)**: Applies basic OS configurations.
*   **OS Patching (`common/patching.yml`)**: OS-level package upgrades with automated reboot handling.
*   **Zookeeper Ephemeral Nodes Demo (`rocky/zookeeper_ephemeral_demo.yml`)**: Demonstrates how ephemeral nodes interact with a Zookeeper cluster and how they act as a service discovery mechanism.
*   **Zookeeper Ephemeral Failover (`rocky/zookeeper_ephemeral_failover.yml`)**: Demonstrates how Zookeeper ephemeral nodes maintain their sessions through a proxy during a Zookeeper leader failover.
*   **Zookeeper Failover Orchestration (`rocky/failover_orchestration.yml`)**: A complex Proof of Concept (POC) that demonstrates application resilience by identifying the Zookeeper leader, crashing it, and verifying that Rocky Linux application nodes seamlessly recover and reconnect via the Zookeeper proxy.
