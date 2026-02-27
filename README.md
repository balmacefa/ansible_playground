# Ansible Docker Environment

This project provides a comprehensive Docker-based development environment for Ansible.

## Docker Compose Profiles

The environment is set up with Docker Compose profiles to allow you to run specific components of the stack without starting everything.

### Available Profiles
- **`rocky`**: Runs the 4 rocky linux nodes (`node-1`, `node-2`, `node-3`, `node-4`).
- **`postgres`**: Runs the 4 postgresql databases (`db-1`, `db-2`, `db-3`, `db-4`).
- **`zookeeper`**: Runs the 4 zookeeper nodes (`zookeeper-1`, `zookeeper-2`, `zookeeper-3`, `zookeeper-4` with 1 leader, 2 followers, 1 observer).

### How to run specific components

#### 1. Start only the Ansible Master
This will start only the `ansible-master` container, without any worker nodes or databases.
```bash
docker compose up -d
```

#### 2. Start the Ansible Master + Rocky Nodes
This will start the master container along with all 4 Rocky Linux node containers.
```bash
docker compose --profile rocky up -d
```

#### 3. Start the Ansible Master + Postgres Databases
This will start the master container along with all 4 PostgreSQL databases.
```bash
docker compose --profile postgres up -d
```

#### 4. Start the Ansible Master + Zookeeper Nodes
This will start the master container along with all 4 Zookeeper nodes.
```bash
docker compose --profile zookeeper up -d
```

#### 5. Start everything (Master + Rocky Nodes + Postgres Databases + Zookeeper Nodes)
This will bring up the entire environment.
```bash
docker compose --profile rocky --profile postgres --profile zookeeper up -d
```

 
 ## Proof of Concept: Zookeeper Interaction
 
 You can verify the interaction between the Rocky Linux nodes and the Zookeeper ensemble by running the POC playbook:
 
 ```bash
 # Starts required nodes and runs the POC
 COMPOSE_PROFILES=rocky,zookeeper docker compose up -d
 ./run_playbook.sh rocky/zookeeper_poc.yml
 ```
 
 For more details on all available playbooks, see [PLAYBOOKS.md](file:///c:/Users/fabia/OneDrive/Escritorio/repos/ansible/PLAYBOOKS.md).
