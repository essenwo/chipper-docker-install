#!/bin/bash

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker not found. Installing Docker..."
    
    # Install required packages
    apt-get update
    apt-get install -y ca-certificates curl gnupg

    # Add Docker's official GPG key
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker packages
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
else
    echo "Docker already installed, proceeding with setup..."
fi

# Create Dockerfile
cat > Dockerfile << 'EOL'
FROM ubuntu:latest

WORKDIR /app
RUN apt-get update && apt-get install -y wget

COPY start.sh /app/
RUN chmod +x /app/start.sh

ENTRYPOINT ["/app/start.sh"]
EOL

# Create start script
cat > start.sh << 'EOL'
#!/bin/bash
wget https://github.com/web3go-xyz/chipper-node-miner-release/releases/download/v1.0.0/din-chipper-node-cli-linux-amd64
chmod +x din-chipper-node-cli-linux-amd64
./din-chipper-node-cli-linux-amd64 --license=$LICENSE_PATH
EOL

# Build and run Docker container
docker build -t chipper-node .
docker run -d \
    -e LICENSE_PATH="/app/license.txt" \
    -v $1:/app/license.txt \
    --name chipper-node \
    chipper-node
