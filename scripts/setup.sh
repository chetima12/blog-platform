#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🚀 Setting up Blog Platform...${NC}"

# Create .env file if not exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}📝 Creating .env file...${NC}"
    cat > .env << EOL
DB_USER=bloguser
DB_PASSWORD=blogpass
DB_NAME=blogdb
EOL
    echo -e "${GREEN}✅ .env file created${NC}"
fi

# Create uploads directory
mkdir -p app/uploads
echo -e "${GREEN}✅ Uploads directory created${NC}"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

# Build and start containers
echo -e "${YELLOW}🔨 Building and starting containers...${NC}"
docker-compose up -d --build

# Wait for services to be healthy
echo -e "${YELLOW}⏳ Waiting for services to be ready...${NC}"
sleep 10

# Check services
echo -e "${YELLOW}🔍 Checking services...${NC}"
docker-compose ps

# Test application
echo -e "${YELLOW}🧪 Testing application...${NC}"
if curl -s http://localhost/health | grep -q "OK"; then
    echo -e "${GREEN}✅ Application is running! Visit http://localhost${NC}"
else
    echo -e "${RED}❌ Application is not responding. Check logs: docker-compose logs${NC}"
fi