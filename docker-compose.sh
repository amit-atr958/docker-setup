# #!/bin/bash

# # Set system parameters for SonarQube
# echo "Setting system parameters for SonarQube..."
# sudo sysctl -w vm.max_map_count=524288
# sudo sysctl -w fs.file-max=131072

# # Define the ports to check
# PORTS=(2182 9092 9093 29093 8000 9000)

# # Loop through the ports and kill processes if running
# for PORT in "${PORTS[@]}"; do
#   PID=$(sudo lsof -t -i :"$PORT")
#   if [ ! -z "$PID" ]; then
#     echo "Killing process on port $PORT (PID: $PID)"
#     sudo kill -9 $PID
#   fi
# done

# # Run Docker Compose
# docker-compose down
# docker-compose build
# docker-compose up -d

# # update in code run  ./docker-compose.sh 
# # and fixed if any error is getting


#!/bin/bash

echo "=== FORCEFUL DOCKER CLEANUP AND RESTART ==="

# Set system parameters for SonarQube
echo "Setting system parameters for SonarQube..."
sudo sysctl -w vm.max_map_count=524288
sudo sysctl -w fs.file-max=131072

# Method 1: Stop all Docker containers forcefully
echo "Stopping all Docker containers forcefully..."
docker stop $(docker ps -aq) 2>/dev/null || echo "No containers to stop"

# Method 2: Remove all containers forcefully
echo "Removing all Docker containers forcefully..."
docker rm -f $(docker ps -aq) 2>/dev/null || echo "No containers to remove"

# Method 3: Docker compose down with force
echo "Running docker-compose down with cleanup..."
docker-compose down --remove-orphans --volumes

# Method 4: Kill Docker proxy processes specifically
echo "Killing Docker proxy processes..."
sudo pkill -f docker-proxy 2>/dev/null || echo "No docker-proxy processes found"

# Wait for Docker proxy processes to be fully terminated
sleep 3

# Method 5: Kill processes on specific ports more aggressively
echo "Killing processes on ports aggressively..."
PORTS=(2182 9092 9093 29093 8000 9000 5432)

for PORT in "${PORTS[@]}"; do
  echo "Checking port $PORT..."
  # Get all PIDs using the port
  PIDS=$(sudo lsof -t -i :"$PORT" 2>/dev/null)
  if [ ! -z "$PIDS" ]; then
    echo "Killing processes on port $PORT (PIDs: $PIDS)"
    # Kill with SIGTERM first
    sudo kill $PIDS 2>/dev/null
    sleep 2
    # Force kill with SIGKILL
    sudo kill -9 $PIDS 2>/dev/null
  else
    echo "No processes found on port $PORT"
  fi
done

# Method 6: Restart Docker daemon if ports are still occupied
echo "Checking if critical ports are still in use..."
if sudo lsof -i :9092 >/dev/null 2>&1 || sudo lsof -i :29093 >/dev/null 2>&1; then
  echo "Critical ports still in use. Restarting Docker daemon..."
  sudo systemctl restart docker
  sleep 10
  echo "Docker daemon restarted"
fi

# Method 6: Additional cleanup - remove networks
echo "Cleaning up Docker networks..."
docker network prune -f

# Method 7: Additional cleanup - remove volumes
echo "Cleaning up Docker volumes..."
docker volume prune -f

# Wait a moment for cleanup to complete
echo "Waiting for cleanup to complete..."
sleep 5

# Verify ports are free
echo "Verifying ports are free..."
for PORT in "${PORTS[@]}"; do
  if sudo lsof -i :"$PORT" >/dev/null 2>&1; then
    echo "WARNING: Port $PORT is still in use!"
    sudo lsof -i :"$PORT"
  else
    echo "Port $PORT is free"
  fi
done

# Build and start services
echo "Building Docker images..."
docker-compose build --no-cache

echo "Starting Docker services..."
docker-compose up -d

# Show running containers
echo "=== RUNNING CONTAINERS ==="
docker ps -a

echo "=== SETUP COMPLETE ==="