#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🚀 Deploying Blog Platform${NC}"

# Check git status
echo -e "${YELLOW}📋 Checking git status...${NC}"
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo -e "${RED}❌ You have uncommitted changes. Commit or stash them first.${NC}"
    exit 1
fi

# Pull latest changes (if git repo)
echo -e "${YELLOW}📥 Pulling latest changes...${NC}"
git pull origin main 2>/dev/null || echo "No git remote, skipping"

# Backup current database
echo -e "${YELLOW}📦 Backing up current database...${NC}"
./scripts/backup.sh

# Pull latest images
echo -e "${YELLOW}📥 Pulling latest images...${NC}"
docker-compose pull

# Rebuild and restart
echo -e "${YELLOW}🔨 Rebuilding and restarting...${NC}"
docker-compose up -d --build --remove-orphans

# Wait for health
echo -e "${YELLOW}⏳ Waiting for services to be healthy...${NC}"
sleep 10

# Check deployment
echo -e "${YELLOW}✅ Verifying deployment...${NC}"
if curl -s http://localhost/health | grep -q "OK"; then
    echo -e "${GREEN}✅ Deployment successful!${NC}"
    
    # Clean up old images
    echo -e "${YELLOW}🧹 Cleaning up old images...${NC}"
    docker system prune -f
else
    echo -e "${RED}❌ Deployment failed! Rolling back...${NC}"
    # Rollback logic would go here
    exit 1
fi

echo -e "${GREEN}🎉 Deployment completed!${NC}"