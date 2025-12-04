#!/bin/bash
# 快速更新脚本 - 只更新代码并重启容器（不重新构建镜像）
# 适合小改动，速度更快

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}=========================================${NC}"
echo -e "${CYAN}  快速更新部署${NC}"
echo -e "${CYAN}=========================================${NC}"
echo ""

# 1. 拉取最新代码
echo -e "${YELLOW}1. 拉取最新代码...${NC}"
git pull

# 2. 重新打包后端
echo -e "${YELLOW}2. 重新打包后端...${NC}"
cd springboot
mvn clean package -DskipTests
cd ..

# 3. 重新打包前端
echo -e "${YELLOW}3. 重新打包前端...${NC}"
cd vue
npm run build
cd ..

# 4. 重新构建并重启后端
echo -e "${YELLOW}4. 重新构建后端镜像...${NC}"
docker stop entrepreneurship_backend
docker rm entrepreneurship_backend
docker build -t entrepreneurship-backend -f springboot/Dockerfile.debug ./springboot
docker run -d \
  --name entrepreneurship_backend \
  --restart always \
  -p 9090:9090 \
  -p 5005:5005 \
  -v $(pwd)/files:/app/files \
  --link entrepreneurship_mysql:mysql \
  -e SPRING_DATASOURCE_URL='jdbc:mysql://mysql:3306/entrepreneurship_system?useUnicode=true&characterEncoding=utf-8&allowMultiQueries=true&useSSL=false&serverTimezone=GMT%2b8&allowPublicKeyRetrieval=true' \
  -e SPRING_DATASOURCE_PASSWORD='root123456' \
  entrepreneurship-backend

# 5. 重新构建并重启前端
echo -e "${YELLOW}5. 重新构建前端镜像...${NC}"
docker stop entrepreneurship_frontend
docker rm entrepreneurship_frontend
docker build -t entrepreneurship-frontend ./vue
docker run -d \
  --name entrepreneurship_frontend \
  --restart always \
  -p 80:80 \
  --link entrepreneurship_backend:backend \
  entrepreneurship-frontend

echo ""
echo -e "${GREEN}✓ 更新部署完成！${NC}"
echo ""
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep entrepreneurship

