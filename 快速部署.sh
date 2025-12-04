#!/bin/bash
# 快速部署脚本 - 更新已有项目（不删除数据库）
# 放在 /home/ubuntu/ 目录下执行
# 使用方法：./快速部署.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

PROJECT_DIR="/home/ubuntu/xm_entrepreneurship_system"
MYSQL_PASSWORD="root123456"

echo -e "${CYAN}=========================================${NC}"
echo -e "${CYAN}  快速更新部署（保留数据库）${NC}"
echo -e "${CYAN}=========================================${NC}"
echo ""

# 1. 拉取最新代码
echo -e "${MAGENTA}[1/6] 拉取最新代码...${NC}"
cd $PROJECT_DIR
git pull
echo -e "${GREEN}✓ 代码更新成功${NC}"
echo ""

# 2. 停止并删除应用容器
echo -e "${MAGENTA}[2/6] 停止旧容器...${NC}"
docker stop entrepreneurship_backend entrepreneurship_frontend 2>/dev/null || echo "容器未运行"
docker rm entrepreneurship_backend entrepreneurship_frontend 2>/dev/null || echo "容器不存在"
docker rmi entrepreneurship-backend entrepreneurship-frontend 2>/dev/null || echo "镜像不存在"
echo -e "${GREEN}✓ 旧容器清理完成${NC}"
echo ""

# 3. 打包后端
echo -e "${MAGENTA}[3/6] 打包后端...${NC}"
cd $PROJECT_DIR/springboot
mvn clean package -DskipTests
echo -e "${GREEN}✓ 后端打包成功${NC}"
echo ""

# 4. 打包前端
echo -e "${MAGENTA}[4/6] 打包前端...${NC}"
cd $PROJECT_DIR/vue

# 创建生产环境配置文件
cat > .env.production << EOF
# 生产环境配置
# 使用相对路径，通过Nginx代理转发到后端
VITE_BASE_URL=/api
EOF

npm run build
echo -e "${GREEN}✓ 前端打包成功${NC}"
echo ""

# 5. 构建并启动后端
echo -e "${MAGENTA}[5/6] 启动后端...${NC}"
cd $PROJECT_DIR
docker build -t entrepreneurship-backend -f springboot/Dockerfile.debug ./springboot
docker run -d \
  --name entrepreneurship_backend \
  --restart always \
  -p 9090:9090 \
  -p 5005:5005 \
  -v $PROJECT_DIR/files:/app/files \
  --link entrepreneurship_mysql:mysql \
  -e SPRING_DATASOURCE_URL='jdbc:mysql://mysql:3306/entrepreneurship_system?useUnicode=true&characterEncoding=utf-8&allowMultiQueries=true&useSSL=false&serverTimezone=GMT%2b8&allowPublicKeyRetrieval=true' \
  -e SPRING_DATASOURCE_PASSWORD=$MYSQL_PASSWORD \
  entrepreneurship-backend

sleep 15
echo -e "${GREEN}✓ 后端启动成功${NC}"
echo ""

# 6. 构建并启动前端
echo -e "${MAGENTA}[6/6] 启动前端...${NC}"
docker build -t entrepreneurship-frontend ./vue
docker run -d \
  --name entrepreneurship_frontend \
  --restart always \
  -p 80:80 \
  --link entrepreneurship_backend:backend \
  entrepreneurship-frontend

echo -e "${GREEN}✓ 前端启动成功${NC}"
echo ""

# 显示结果
echo -e "${CYAN}=========================================${NC}"
echo -e "${GREEN}✓ 快速部署完成！${NC}"
echo -e "${CYAN}=========================================${NC}"
echo ""
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep entrepreneurship
echo ""
echo -e "访问: ${CYAN}http://119.29.152.18${NC}"

