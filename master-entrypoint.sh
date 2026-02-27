#!/bin/bash

echo "Starting master initialization..."

# Wait for nodes to be up and running ssh
sleep 5

# Copy SSH keys to nodes
for i in {1..4}; do
  echo "Attempting to copy SSH key to node-$i..."
  sshpass -p 'root' ssh-copy-id -o StrictHostKeyChecking=no root@node-$i || echo "Failed to copy key to node-$i"
done

echo "Master node is ready. Playbooks can be executed now."

# Keep container alive
tail -f /dev/null
