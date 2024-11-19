
#!/bin/bash

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker not found. Installing Docker..."
    
    apt-get update
    apt-get install -y ca-certificates curl gnupg
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
else
    echo "Docker already installed, proceeding with setup..."
fi

# Check if license file exists
if [ ! -f "$1" ]; then
    echo "Error: License file not found at $1"
    echo "Usage: $0 /path/to/license.txt"
    exit 1
fi

# Get absolute path of license file
LICENSE_PATH=$(realpath "$1")

# Create Dockerfile
cat > Dockerfile << 'EOL'
FROM ubuntu:latest

WORKDIR /app
RUN apt-get update && apt-get install -y wget

COPY start.sh /app/
COPY license.txt /app/
RUN chmod +x /app/start.sh

ENV LICENSE_PATH=/app/license.txt
ENTRYPOINT ["/app/start.sh"]
EOL

# Create start script
cat > start.sh << 'EOL'
#!/bin/bash
wget https://github.com/web3go-xyz/chipper-node-miner-release/releases/download/v1.0.0/din-chipper-node-cli-linux-amd64
chmod +x din-chipper-node-cli-linux-amd64
./din-chipper-node-cli-linux-amd64 --license=/app/license.txt
EOL

# Copy license file
cp "$LICENSE_PATH" license.txt

# Build and run Docker container
docker build -t chipper-node .
docker run -d --name chipper-node chipper-node
