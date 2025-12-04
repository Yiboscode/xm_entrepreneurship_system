#!/bin/bash
# 创新创业选题系统 - 完整部署脚本
# 放在 /home/ubuntu/ 目录下执行
# 使用方法：./完整部署脚本.sh

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# 配置变量
GITHUB_REPO="https://github.com/Yiboscode/xm_entrepreneurship_system.git"
PROJECT_DIR="/home/ubuntu/xm_entrepreneurship_system"
MYSQL_PASSWORD="root123456"
MYSQL_DATABASE="entrepreneurship_system"

echo -e "${CYAN}================================================${NC}"
echo -e "${CYAN}  创新创业选题系统 - 完整部署脚本${NC}"
echo -e "${CYAN}================================================${NC}"
echo ""
echo -e "${YELLOW}警告：此脚本将：${NC}"
echo -e "${RED}  - 删除所有旧的Docker容器${NC}"
echo -e "${RED}  - 删除所有旧的Docker镜像${NC}"
echo -e "${RED}  - 删除旧的项目目录${NC}"
echo -e "${RED}  - 删除MySQL数据（数据库将重置）${NC}"
echo -e "${GREEN}  - 从GitHub克隆最新代码${NC}"
echo -e "${GREEN}  - 部署全新的MySQL数据库${NC}"
echo -e "${GREEN}  - 部署全新的后端和前端${NC}"
echo ""
read -p "确认继续？(输入 yes 确认): " confirm

if [ "$confirm" != "yes" ]; then
    echo -e "${YELLOW}已取消部署${NC}"
    exit 0
fi

echo ""
echo -e "${CYAN}========== 开始完整部署 ==========${NC}"
echo ""

# ============================================
# 第一步：清理所有旧数据
# ============================================
echo -e "${MAGENTA}[1/8] 清理旧Docker容器和镜像...${NC}"

# 停止所有相关容器
echo "停止容器..."
docker stop entrepreneurship_frontend entrepreneurship_backend entrepreneurship_mysql 2>/dev/null || echo "容器未运行或不存在"

# 删除所有相关容器
echo "删除容器..."
docker rm entrepreneurship_frontend entrepreneurship_backend entrepreneurship_mysql 2>/dev/null || echo "容器不存在"

# 删除所有相关镜像
echo "删除镜像..."
docker rmi entrepreneurship-frontend entrepreneurship-backend collegetopics-frontend collegetopics-backend 2>/dev/null || echo "镜像不存在"

# 删除数据卷（这会删除所有数据库数据）
echo "删除数据卷..."
docker volume rm mysql_data 2>/dev/null || echo "数据卷不存在"

# 清理未使用的资源
echo "清理Docker资源..."
docker system prune -f

echo -e "${GREEN}✓ Docker清理完成${NC}"
echo ""

# ============================================
# 第二步：删除旧项目目录
# ============================================
echo -e "${MAGENTA}[2/8] 删除旧项目目录...${NC}"

# 备份旧目录（如果存在）
if [ -d "$PROJECT_DIR" ]; then
    BACKUP_DIR="${PROJECT_DIR}.backup.$(date +%Y%m%d-%H%M%S)"
    echo "备份旧目录到: $BACKUP_DIR"
    mv "$PROJECT_DIR" "$BACKUP_DIR"
fi

echo -e "${GREEN}✓ 旧目录清理完成${NC}"
echo ""

# ============================================
# 第三步：克隆最新代码
# ============================================
echo -e "${MAGENTA}[3/8] 从GitHub克隆最新代码...${NC}"

cd /home/ubuntu
git clone $GITHUB_REPO

if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}✗ Git克隆失败！${NC}"
    exit 1
fi

cd $PROJECT_DIR
echo -e "${GREEN}✓ 代码克隆成功${NC}"
echo ""

# ============================================
# 第四步：部署MySQL数据库
# ============================================
echo -e "${MAGENTA}[4/8] 部署MySQL数据库...${NC}"

# 检查init.sql是否存在
if [ ! -f "init.sql" ]; then
    echo -e "${YELLOW}⚠ 警告：init.sql文件不存在！${NC}"
    echo "请手动上传 entrepreneurship_system.sql 到 $PROJECT_DIR/init.sql"
    read -p "已上传？按回车继续..."
fi

# 创建数据卷
docker volume create mysql_data

# 启动MySQL容器
docker run -d \
  --name entrepreneurship_mysql \
  --restart always \
  -e MYSQL_ROOT_PASSWORD=$MYSQL_PASSWORD \
  -e MYSQL_DATABASE=$MYSQL_DATABASE \
  -e TZ=Asia/Shanghai \
  -p 3306:3306 \
  -v mysql_data:/var/lib/mysql \
  -v $PROJECT_DIR/init.sql:/docker-entrypoint-initdb.d/init.sql:ro \
  mysql:8.0 \
  --character-set-server=utf8mb4 \
  --collation-server=utf8mb4_unicode_ci \
  --default-authentication-plugin=mysql_native_password

echo "等待MySQL启动并初始化数据库..."
sleep 30

# 验证MySQL
if docker ps | grep -q entrepreneurship_mysql; then
    echo -e "${GREEN}✓ MySQL容器启动成功${NC}"
    
    # 验证数据库表
    TABLE_COUNT=$(docker exec entrepreneurship_mysql mysql -uroot -p$MYSQL_PASSWORD -e "USE $MYSQL_DATABASE; SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$MYSQL_DATABASE';" 2>/dev/null | tail -1)
    echo "数据库表数量: $TABLE_COUNT"
    
    if [ "$TABLE_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✓ 数据库初始化成功${NC}"
    else
        echo -e "${YELLOW}⚠ 数据库可能初始化失败，请检查${NC}"
    fi
else
    echo -e "${RED}✗ MySQL启动失败${NC}"
    docker logs entrepreneurship_mysql
    exit 1
fi
echo ""

# ============================================
# 第五步：打包后端
# ============================================
echo -e "${MAGENTA}[5/8] 打包后端（Maven）...${NC}"

cd $PROJECT_DIR/springboot
mvn clean package -DskipTests

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ 后端打包失败！${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 后端打包成功${NC}"
echo ""

# ============================================
# 第六步：打包前端
# ============================================
echo -e "${MAGENTA}[6/8] 打包前端（npm）...${NC}"

cd $PROJECT_DIR/vue

# 安装依赖
echo "安装前端依赖..."
npm install

# 构建生产版本
npm run build

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ 前端打包失败！${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 前端打包成功${NC}"
echo ""

# ============================================
# 第七步：构建并启动后端
# ============================================
echo -e "${MAGENTA}[7/8] 构建并启动后端容器...${NC}"

cd $PROJECT_DIR

# 构建后端镜像
echo "构建后端Docker镜像..."
docker build -t entrepreneurship-backend -f springboot/Dockerfile.debug ./springboot

# 创建files目录
mkdir -p $PROJECT_DIR/files

# 启动后端容器
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

echo "等待后端启动..."
sleep 20

# 检查后端
if docker ps | grep -q entrepreneurship_backend; then
    echo -e "${GREEN}✓ 后端容器启动成功${NC}"
    
    # 检查是否启动成功
    if docker logs entrepreneurship_backend 2>&1 | grep -q "Started SpringbootApplication"; then
        echo -e "${GREEN}✓ Spring Boot应用启动成功${NC}"
    else
        echo -e "${YELLOW}⚠ Spring Boot可能还在启动中...${NC}"
    fi
else
    echo -e "${RED}✗ 后端容器启动失败${NC}"
    docker logs entrepreneurship_backend
    exit 1
fi
echo ""

# ============================================
# 第八步：构建并启动前端
# ============================================
echo -e "${MAGENTA}[8/8] 构建并启动前端容器...${NC}"

# 构建前端镜像
echo "构建前端Docker镜像..."
docker build -t entrepreneurship-frontend ./vue

# 启动前端容器
docker run -d \
  --name entrepreneurship_frontend \
  --restart always \
  -p 80:80 \
  --link entrepreneurship_backend:backend \
  entrepreneurship-frontend

# 检查前端
if docker ps | grep -q entrepreneurship_frontend; then
    echo -e "${GREEN}✓ 前端容器启动成功${NC}"
else
    echo -e "${RED}✗ 前端容器启动失败${NC}"
    docker logs entrepreneurship_frontend
    exit 1
fi
echo ""

# ============================================
# 部署完成
# ============================================
echo -e "${CYAN}================================================${NC}"
echo -e "${GREEN}  🎉 部署完成！${NC}"
echo -e "${CYAN}================================================${NC}"
echo ""
echo -e "${BLUE}📦 容器状态:${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -1
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep entrepreneurship
echo ""
echo -e "${BLUE}💾 资源使用:${NC}"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" | head -1
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" | grep entrepreneurship
echo ""
echo -e "${GREEN}🌐 访问地址:${NC}"
echo -e "  前端: ${CYAN}http://119.29.152.18${NC}"
echo -e "  后端: ${CYAN}http://119.29.152.18:9090${NC}"
echo -e "  调试: ${CYAN}119.29.152.18:5005${NC}"
echo ""
echo -e "${GREEN}🔐 默认账号:${NC}"
echo -e "  管理员: ${CYAN}admin / admin${NC}"
echo ""
echo -e "${BLUE}📝 常用命令:${NC}"
echo -e "  查看容器: ${CYAN}docker ps${NC}"
echo -e "  查看后端日志: ${CYAN}docker logs -f entrepreneurship_backend${NC}"
echo -e "  查看前端日志: ${CYAN}docker logs -f entrepreneurship_frontend${NC}"
echo -e "  重启后端: ${CYAN}docker restart entrepreneurship_backend${NC}"
echo -e "  重启前端: ${CYAN}docker restart entrepreneurship_frontend${NC}"
echo -e "  连接数据库: ${CYAN}docker exec -it entrepreneurship_mysql mysql -uroot -p$MYSQL_PASSWORD${NC}"
echo ""
echo -e "${YELLOW}⚠ 重要提示:${NC}"
echo -e "  1. 如需保留数据，请先备份数据库"
echo -e "  2. 文件上传目录: $PROJECT_DIR/files"
echo -e "  3. 如需更新代码: cd $PROJECT_DIR && git pull && ./update.sh"
echo ""

