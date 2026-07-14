#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}📊 Blog Platform Monitoring${NC}"
echo "================================"

# Check container status
echo -e "${YELLOW}📦 Container Status:${NC}"
docker-compose ps

# Check resource usage
echo -e "\n${YELLOW}💻 Resource Usage:${NC}"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# Check database connections
echo -e "\n${YELLOW}🔗 Database Connections:${NC}"
docker exec blog-postgres psql -U bloguser -d blogdb -c "SELECT count(*) FROM pg_stat_activity;"

# Check Redis info
echo -e "\n${YELLOW}📊 Redis Info:${NC}"
docker exec blog-redis redis-cli info memory | grep "used_memory_human\|memory_human"

# Check application logs (last 5 lines)
echo -e "\n${YELLOW}📝 Recent Application Logs:${NC}"
docker logs --tail 5 blog-app

# Check system health
echo -e "\n${YELLOW}❤️ Health Check:${NC}"
HEALTH=$(curl -s http://localhost/health)
echo "$HEALTH" | python3 -m json.tool 2>/dev/null || echo "$HEALTH"

echo -e "\n${BLUE}🔄 Refresh: Run this script again${NC}"