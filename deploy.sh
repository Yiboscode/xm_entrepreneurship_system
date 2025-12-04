#!/bin/bash
# 一键部署脚本 - 部署最新代码到Docker
# 使用方法：./deploy.sh

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

PROJECT_PATH=$(pwd)

echo -e "${CYAN}=========================================${NC}"
echo -e "${CYAN}  创新创业选题系统 - 一键部署${NC}"
echo -e "${CYAN}=========================================${NC}"
echo ""

# 1. 停止并删除旧容器
echo -e "${YELLOW}步骤1: 停止并删除旧容器...${NC}"
docker stop entrepreneurship_backend entrepreneurship_frontend 2>/dev/null || echo "容器未运行"
docker rm entrepreneurship_backend entrepreneurship_frontend 2>/dev/null || echo "容器不存在"

# 2. 删除旧镜像
echo -e "${YELLOW}步骤2: 删除旧镜像...${NC}"
docker rmi entrepreneurship-backend entrepreneurship-frontend 2>/dev/null || echo "镜像不存在"

# 3. 打包后端
echo -e "${YELLOW}步骤3: 打包后端（Maven）...${NC}"
cd $PROJECT_PATH/springboot
mvn clean package -DskipTests

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ 后端打包失败！${NC}"
    exit 1
fi
echo -e "${GREEN}✓ 后端打包成功${NC}"

# 4. 打包前端
echo -e "${YELLOW}步骤4: 打包前端（npm）...${NC}"
cd $PROJECT_PATH/vue

# 检查node_modules是否存在
if [ ! -d "node_modules" ]; then
    echo "首次部署，安装依赖..."
    npm install
fi

npm run build

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ 前端打包失败！${NC}"
    exit 1
fi
echo -e "${GREEN}✓ 前端打包成功${NC}"

# 5. 构建Docker镜像
echo -e "${YELLOW}步骤5: 构建Docker镜像...${NC}"
cd $PROJECT_PATH

echo "构建后端镜像..."
docker build -t entrepreneurship-backend -f springboot/Dockerfile.debug ./springboot

echo "构建前端镜像..."
docker build -t entrepreneurship-frontend ./vue

echo -e "${GREEN}✓ Docker镜像构建成功${NC}"

# 6. 启动MySQL（如果未运行）
echo -e "${YELLOW}步骤6: 检查MySQL...${NC}"
if ! docker ps | grep -q entrepreneurship_mysql; then
    echo "MySQL未运行，正在启动..."
    docker start entrepreneurship_mysql 2>/dev/null || \
    docker run -d \
      --name entrepreneurship_mysql \
      --restart always \
      -e MYSQL_ROOT_PASSWORD=root123456 \
      -e MYSQL_DATABASE=entrepreneurship_system \
      -e TZ=Asia/Shanghai \
      -p 3306:3306 \
      -v mysql_data:/var/lib/mysql \
      -v $PROJECT_PATH/init.sql:/docker-entrypoint-initdb.d/init.sql:ro \
      mysql:8.0 \
      --character-set-server=utf8mb4 \
      --collation-server=utf8mb4_unicode_ci \
      --default-authentication-plugin=mysql_native_password
    
    echo "等待MySQL启动..."
    sleep 20
fi
echo -e "${GREEN}✓ MySQL运行正常${NC}"

# 7. 启动后端容器
echo -e "${YELLOW}步骤7: 启动后端容器...${NC}"
docker run -d \
  --name entrepreneurship_backend \
  --restart always \
  -p 9090:9090 \
  -p 5005:5005 \
  -v $PROJECT_PATH/files:/app/files \
  --link entrepreneurship_mysql:mysql \
  -e SPRING_DATASOURCE_URL='jdbc:mysql://mysql:3306/entrepreneurship_system?useUnicode=true&characterEncoding=utf-8&allowMultiQueries=true&useSSL=false&serverTimezone=GMT%2b8&allowPublicKeyRetrieval=true' \
  -e SPRING_DATASOURCE_PASSWORD='root123456' \
  entrepreneurship-backend

echo "等待后端启动..."
sleep 15
echo -e "${GREEN}✓ 后端容器启动成功${NC}"

# 8. 启动前端容器
echo -e "${YELLOW}步骤8: 启动前端容器...${NC}"
docker run -d \
  --name entrepreneurship_frontend \
  --restart always \
  -p 80:80 \
  --link entrepreneurship_backend:backend \
  entrepreneurship-frontend

echo -e "${GREEN}✓ 前端容器启动成功${NC}"

# 9. 显示部署结果
echo ""
echo -e "${CYAN}=========================================${NC}"
echo -e "${GREEN}  ✓ 部署完成！${NC}"
echo -e "${CYAN}=========================================${NC}"
echo ""
echo "📦 容器状态:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep entrepreneurship
echo ""
echo "🌐 访问地址:"
echo -e "  前端: ${GREEN}http://119.29.152.18${NC}"
echo -e "  后端: ${GREEN}http://119.29.152.18:9090${NC}"
echo -e "  调试: ${GREEN}119.29.152.18:5005${NC}"
echo ""
echo "📝 查看日志:"
echo "  docker logs -f entrepreneurship_backend"
echo "  docker logs -f entrepreneurship_frontend"
echo ""
echo "🔄 重启服务:"
echo "  docker restart entrepreneurship_backend"
echo "  docker restart entrepreneurship_frontend"
echo ""

