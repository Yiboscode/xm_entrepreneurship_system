#!/bin/bash
# 服务器一键部署脚本

set -e

echo "=== 创新创业选题系统 - 完整部署 ==="

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. 停止旧容器
echo -e "${YELLOW}1. 清理旧容器...${NC}"
docker stop entrepreneurship_backend entrepreneurship_frontend 2>/dev/null || true
docker rm entrepreneurship_backend entrepreneurship_frontend 2>/dev/null || true

# 2. 构建镜像
echo -e "${YELLOW}2. 构建应用镜像...${NC}"
docker build -t entrepreneurship-backend ./springboot
docker build -t entrepreneurship-frontend ./vue

# 3. 确保MySQL运行
echo -e "${YELLOW}3. 检查MySQL...${NC}"
if ! docker ps | grep -q entrepreneurship_mysql; then
    echo "MySQL未运行，正在启动..."
    docker start entrepreneurship_mysql || echo "请先部署MySQL"
    sleep 10
fi

# 4. 启动后端
echo -e "${YELLOW}4. 启动后端服务...${NC}"
docker run -d \
  --name entrepreneurship_backend \
  --restart always \
  -p 9090:9090 \
  -v $(pwd)/files:/app/files \
  --link entrepreneurship_mysql:mysql \
  -e SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/entrepreneurship_system?useUnicode=true&characterEncoding=utf-8&allowMultiQueries=true&useSSL=false&serverTimezone=GMT%2b8&allowPublicKeyRetrieval=true \
  -e SPRING_DATASOURCE_PASSWORD=root123456 \
  entrepreneurship-backend

# 5. 等待后端启动
echo "等待后端启动..."
sleep 15

# 6. 启动前端
echo -e "${YELLOW}5. 启动前端服务...${NC}"
docker run -d \
  --name entrepreneurship_frontend \
  --restart always \
  -p 80:80 \
  --link entrepreneurship_backend:backend \
  entrepreneurship-frontend

# 7. 显示状态
echo ""
echo -e "${GREEN}=== 部署完成！===${NC}"
echo ""
docker ps
echo ""
echo "访问地址："
echo "  前端: http://collegetopics.cn"
echo "  后端: http://collegetopics.cn:9090"
echo ""
echo "查看日志："
echo "  docker logs -f entrepreneurship_backend"
echo "  docker logs -f entrepreneurship_frontend"

