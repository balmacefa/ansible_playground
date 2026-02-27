#!/usr/bin/env python3
import sys
import time
import logging
from kazoo.client import KazooClient
from kazoo.client import KazooState

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

zk_hosts = 'zookeeper-1:2181,zookeeper-2:2181,zookeeper-3:2181,zookeeper-4:2181'
poc_path = "/failover_status"

def my_listener(state):
    if state == KazooState.LOST:
        logger.warning("CONNECTION LOST")
    elif state == KazooState.SUSPENDED:
        logger.warning("CONNECTION SUSPENDED")
    else:
        logger.info("CONNECTION CONNECTED")

zk = KazooClient(hosts=zk_hosts)
zk.add_listener(my_listener)

try:
    logger.info("Starting Kazoo client...")
    zk.start()

    # Ensure path exists
    if not zk.exists(poc_path):
        zk.create(poc_path, b"initial")

    logger.info("Starting interaction loop (30 seconds)...")
    for i in range(30):
        try:
            timestamp = str(time.time()).encode('utf-8')
            zk.set(poc_path, timestamp)
            logger.info(f"Iteration {i}: Successfully updated znode with timestamp {timestamp.decode()}")
        except Exception as e:
            logger.error(f"Iteration {i}: Failed to update znode: {e}")
        
        time.sleep(1)

except Exception as e:
    logger.critical(f"POC failed: {e}")
finally:
    logger.info("Stopping Kazoo client...")
    zk.stop()
    logger.info("POC Finished.")
