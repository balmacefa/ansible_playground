#!/bin/bash

PLAYBOOK=$1

if [ -z "$PLAYBOOK" ]; then
  echo "Usage: ./run_playbook.sh <playbook_name.yml>"
  exit 1
fi

# Define profile mapping
PROFILES=()
[[ "$PLAYBOOK" == *"zookeeper"* ]] && PROFILES+=("zookeeper")
[[ "$PLAYBOOK" == *"rocky"* ]] && PROFILES+=("rocky")
[[ "$PLAYBOOK" == "site.yml" ]] && PROFILES+=("rocky")

# Always ensure ansible-master is running
if [ "$(docker inspect -f '{{.State.Running}}' ansible-master 2>/dev/null)" != "true" ]; then
    echo "Starting ansible-master..."
    docker compose up -d ansible-master
fi

# Ensure required profiles are running
# Use an associative array-like approach to unique profiles
for profile in $(echo "${PROFILES[@]}" | tr ' ' '\n' | sort -u); do
    echo "Ensuring profile '$profile' is active..."
    docker compose --profile "$profile" up -d
done

echo "Running playbook: $PLAYBOOK inside ansible-master container..."
docker exec -it ansible-master ansible-playbook -i inventory.ini "$PLAYBOOK"
