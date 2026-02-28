#!/usr/bin/env bash

PLAYBOOK=""
NODES_COUNT=4

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -p|--playbook) PLAYBOOK="$2"; shift ;;
        -n|--nodes) NODES_COUNT="$2"; shift ;;
        *) PLAYBOOK="$1" ;;
    esac
    shift
done

# If no playbook is provided, show interactive menu
if [ -z "$PLAYBOOK" ]; then
    while true; do
        echo -e "\n\e[36m--- Ansible Playbook Interactive Selector ---\e[0m"
        
        # Discovery: Find all .yml and .yaml files in playbooks directory
        mapfile -t PLAYBOOKS_ARRAY < <(find playbooks -name "*.yml" | grep -vE "group_vars|roles|tasks" | sed 's|playbooks/||')
        
        for i in "${!PLAYBOOKS_ARRAY[@]}"; do
            echo "[$((i+1))] ${PLAYBOOKS_ARRAY[$i]}"
        done
        
        echo -e "\e[32m[N] Set Node Count (Current: $NODES_COUNT)\e[0m"
        echo -e "\e[33m[T] Tear Down Project\e[0m"
        echo -e "\e[31m[Q] Quit\e[0m"
        
        read -p $'\nSelect a playbook number, \'N\' for Node Count, \'T\' for Tear Down, or \'Q\' to Quit: ' selection
        
        if [[ "${selection,,}" == "q" ]]; then
            exit 0
        fi
        
        if [[ "${selection,,}" == "n" ]]; then
            read -p $'\nEnter the new number of Rocky nodes: ' nodes_input
            if [[ "$nodes_input" =~ ^[0-9]+$ ]] && [ "$nodes_input" -gt 0 ]; then
                NODES_COUNT=$nodes_input
                echo -e "\e[32mNode count updated to $NODES_COUNT.\e[0m"
            else
                echo -e "\e[31mInvalid input. Node count remains $NODES_COUNT.\e[0m"
            fi
            continue
        fi

        if [[ "${selection,,}" == "t" ]]; then
            echo -e "\n\e[33m--- Tear Down Menu ---\e[0m"
            echo "[1] All Profiles"
            echo "[2] Rocky Linux (rocky)"
            echo "[3] Zookeeper (zookeeper)"
            echo "[4] Cancel (Back to Playbooks)"
            
            read -p $'\nSelect tear down option: ' td_selection
            
            case $td_selection in
                1) 
                    echo -e "\e[31mTearing down all profiles...\e[0m"
                    podman compose --profile rocky --profile zookeeper down
                    ;;
                2) 
                    echo -e "\e[31mTearing down Rocky profile...\e[0m"
                    podman compose --profile rocky down 
                    ;;
                3) 
                    echo -e "\e[31mTearing down Zookeeper profile...\e[0m"
                    podman compose --profile zookeeper down 
                    ;;
                4) continue ;;
                *) echo -e "\e[31mInvalid selection.\e[0m" ;;
            esac
            continue
        fi
        
        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#PLAYBOOKS_ARRAY[@]}" ]; then
            idx=$((selection-1))
            PLAYBOOK="${PLAYBOOKS_ARRAY[$idx]}"
            break
        else
            echo -e "\e[31mInvalid selection: '$selection'.\e[0m"
            continue
        fi
    done
else
    # Make path relative to playbooks
    PLAYBOOK="${PLAYBOOK#playbooks/}"
    PLAYBOOK="${PLAYBOOK#playbooks\\}"
    PLAYBOOK="${PLAYBOOK//\\//}"
fi

REQUIRED_PROFILES=()

if [[ "$PLAYBOOK" == *"zookeeper"* ]]; then REQUIRED_PROFILES+=("zookeeper"); fi
if [[ "$PLAYBOOK" == *"rocky"* ]]; then REQUIRED_PROFILES+=("rocky"); fi
if [[ "$PLAYBOOK" == *"failover_orchestration"* ]]; then REQUIRED_PROFILES+=("zookeeper"); fi
if [[ "$PLAYBOOK" == *"site.yml"* ]]; then REQUIRED_PROFILES+=("rocky"); fi

echo -e "\e[36mChecking if ansible-master is running...\e[0m"
MASTER_STATUS=$(podman inspect -f '{{.State.Running}}' ansible-master 2>/dev/null)
if [ "$MASTER_STATUS" != "true" ]; then
    echo -e "\e[33mStarting ansible-master...\e[0m"
    podman compose up -d ansible-master
fi

# Dynamically generate inventory.ini
INVENTORY_FILE="playbooks/inventory.ini"
echo "[nodes]" > "$INVENTORY_FILE"
for ((n=1; n<=NODES_COUNT; n++)); do
    echo "ansible-node-$n" >> "$INVENTORY_FILE"
done

cat <<EOF >> "$INVENTORY_FILE"

[zookeeper]
zookeeper-1
zookeeper-2
zookeeper-3
zookeeper-4

[zookeeper_nodes]
zookeeper-1
zookeeper-2
zookeeper-3
zookeeper-4
EOF

# Ensure required profiles are running
mapfile -t UNIQUE_PROFILES < <(printf "%s\n" "${REQUIRED_PROFILES[@]}" | sort -u)

for profile in "${UNIQUE_PROFILES[@]}"; do
    if [ -z "$profile" ]; then continue; fi
    echo -e "\e[36mEnsuring profile '$profile' is active...\e[0m"
    if [ "$profile" == "rocky" ]; then
        podman compose --profile rocky up --scale node=$NODES_COUNT -d
    else
        podman compose --profile "$profile" up -d
    fi
done

if [[ " ${REQUIRED_PROFILES[*]} " =~ " rocky " ]] || [[ "$PLAYBOOK" == *"site.yml"* ]]; then
    echo -e "\e[36mSSH connectivity secured via shared keys volume.\e[0m"
fi

podman exec -e ANSIBLE_CONFIG=/playbooks/ansible.cfg ansible-master ansible-playbook -i inventory.ini "$PLAYBOOK"
