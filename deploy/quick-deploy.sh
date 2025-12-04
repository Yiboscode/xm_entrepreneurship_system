#!/bin/bash
# 快速部署脚本 - 在服务器上执行

set -e  # 遇到错误立即退出

echo "=== 创新创业选题系统快速部署 ==="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. 清理旧部署
echo -e "${YELLOW}步骤1: 清理旧部署...${NC}"
docker stop entrepreneurship_frontend entrepreneurship_backend entrepreneurship_mysql 2>/dev/null || echo "容器未运行或不存在"
docker rm entrepreneurship_frontend entrepreneurship_backend entrepreneurship_mysql 2>/dev/null || echo "容器不存在"
docker rmi collegetopics-frontend collegetopics-backend 2>/dev/null || echo "镜像不存在"

# 2. 启动MySQL
echo -e "${YELLOW}步骤2: 启动MySQL数据库...${NC}"
docker-compose up -d mysql

# 等待MySQL启动
echo "等待MySQL启动..."
sleep 20

# 检查MySQL健康状态
if docker ps | grep -q "entrepreneurship_mysql"; then
    echo -e "${GREEN}✓ MySQL启动成功${NC}"
else
    echo -e "${RED}✗ MySQL启动失败，请检查日志${NC}"
    docker-compose logs mysql
    exit 1
fi

# 3. 验证数据库
echo -e "${YELLOW}步骤3: 验证数据库...${NC}"
docker exec entrepreneurship_mysql mysql -uroot -proot123456 -e "USE entrepreneurship_system; SHOW TABLES;" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 数据库初始化成功${NC}"
    docker exec entrepreneurship_mysql mysql -uroot -proot123456 -e "USE entrepreneurship_system; SELECT COUNT(*) as table_count FROM information_schema.tables WHERE table_schema='entrepreneurship_system';"
else
    echo -e "${RED}✗ 数据库初始化失败${NC}"
    exit 1
fi

echo -e "${GREEN}=== 数据库部署完成！===${NC}"
echo ""
echo "下一步："
echo "1. 在本地修改 springboot/src/main/resources/application.yml"
echo "   - 数据库URL改为: jdbc:mysql://119.29.152.18:3306/..."
echo "   - 密码改为: root123456"
echo "2. 在本地测试所有功能"
echo "3. 测试通过后，执行后端前端部署"
echo ""
echo "查看数据库日志："
echo "  docker-compose logs -f mysql"
echo ""
echo "连接数据库："
echo "  docker exec -it entrepreneurship_mysql mysql -uroot -proot123456"

