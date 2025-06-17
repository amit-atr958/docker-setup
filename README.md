# docker-setup

`chmod +x docker-compose.sh ./docker-compose.sh`


The key additions in the script:

Forceful container removal with docker rm -f
Multiple kill attempts (SIGTERM then SIGKILL)
Network and volume cleanup
Port verification before restart
No-cache build to ensure fresh start
Kills docker-proxy processes first using pkill -f docker-proxy
Restarts Docker daemon if critical ports are still occupied
Waits appropriately between operations