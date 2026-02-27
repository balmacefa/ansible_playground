#!/bin/bash
if [ -z "$1" ]; then
  echo "Usage: ./run_playbook.sh <playbook_name.yml>"
  exit 1
fi
echo "Running playbook: $1 inside ansible-master container..."
docker exec -it ansible-master ansible-playbook -i inventory.ini "$1"
