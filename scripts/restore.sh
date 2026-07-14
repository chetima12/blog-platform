#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🔄 Starting database restore...${NC}"

# List available backups
echo -e "${YELLOW}📂 Available backups:${NC}"
ls -lh ./backups/*.gz 2>/dev/null || echo "No backups found"

# Get backup file
read -p "Enter backup filename (e.g., backup_20240101_120000.sql.gz): " BACKUP_FILE

if [ ! -f "./backups/$BACKUP_FILE" ]; then
    echo -e "${RED}❌ Backup file not found!${NC}"
    exit 1
fi

# Confirm restore
read -p "⚠️ This will overwrite current database. Continue? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ]; then
    echo -e "${YELLOW}Restore cancelled${NC}"
    exit 0
fi

# Restore database
echo -e "${YELLOW}🔄 Restoring database...${NC}"
gunzip -c "./backups/$BACKUP_FILE" | docker exec -i blog-postgres psql -U bloguser blogdb

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Database restored successfully!${NC}"
else
    echo -e "${RED}❌ Restore failed!${NC}"
    exit 1
fi