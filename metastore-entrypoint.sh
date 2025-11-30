#!/bin/bash

# Fix warehouse directory permissions (requires root)
# The hive user (uid=1000) needs write access to the warehouse
if [ -d "/opt/hive/warehouse" ]; then
    chown -R hive:hive /opt/hive/warehouse 2>/dev/null || true
    chmod -R 755 /opt/hive/warehouse 2>/dev/null || true
fi

# Drop to hive user and start the Hive service
exec su -s /bin/bash hive -c "/entrypoint.sh"
