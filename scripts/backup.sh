#!/bin/bash

# Configuration
BACKUP_DIR="./backups"
DB_CONTAINER="blog-postgres"
DB_NAME="blogdb"
DB_USER="bloguser"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}📦 Starting database backup...${NC}"

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup database
echo -e "${YELLOW}📤 Exporting database...${NC}"
docker exec $DB_CONTAINER pg_dump -U $DB_USER $DB_NAME > "$BACKUP_DIR/backup_$TIMESTAMP.sql"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Backup created: backup_$TIMESTAMP.sql${NC}"
    
    # Compress backup
    echo -e "${YELLOW}📦 Compressing backup...${NC}"
    gzip "$BACKUP_DIR/backup_$TIMESTAMP.sql"
    echo -e "${GREEN}✅ Backup compressed: backup_$TIMESTAMP.sql.gz${NC}"
    
    # Keep only last 7 backups
    echo -e "${YELLOW}🧹 Cleaning old backups...${NC}"
    ls -t $BACKUP_DIR/*.gz | tail -n +8 | xargs -r rm
    echo -e "${GREEN}✅ Old backups cleaned${NC}"
    
    # Show backup info
    echo -e "${GREEN}📊 Backup info:${NC}"
    ls -lh $BACKUP_DIR/backup_$TIMESTAMP.sql.gz
else
    echo -e "${RED}❌ Backup failed!${NC}"
    exit 1
fi