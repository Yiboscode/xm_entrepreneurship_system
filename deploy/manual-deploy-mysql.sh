#!/bin/bash
# 手动部署MySQL - 不使用 docker-compose
# 在服务器上执行

set -e

echo "=== 手动部署MySQL数据库 ==="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. 清理旧容器
echo -e "${YELLOW}步骤1: 清理旧MySQL容器...${NC}"
docker stop entrepreneurship_mysql 2>/dev/null || echo "MySQL容器未运行"
docker rm entrepreneurship_mysql 2>/dev/null || echo "MySQL容器不存在"

# 2. 创建数据卷（如果不存在）
echo -e "${YELLOW}步骤2: 创建数据卷...${NC}"
docker volume create mysql_data 2>/dev/null || echo "数据卷已存在"

# 3. 启动MySQL容器
echo -e "${YELLOW}步骤3: 启动MySQL容器...${NC}"
docker run -d \
  --name entrepreneurship_mysql \
  --restart always \
  -e MYSQL_ROOT_PASSWORD=root123456 \
  -e MYSQL_DATABASE=entrepreneurship_system \
  -e TZ=Asia/Shanghai \
  -p 3306:3306 \
  -v mysql_data:/var/lib/mysql \
  -v $(pwd)/init.sql:/docker-entrypoint-initdb.d/init.sql:ro \
  mysql:8.0 \
  --character-set-server=utf8mb4 \
  --collation-server=utf8mb4_unicode_ci \
  --default-authentication-plugin=mysql_native_password

# 4. 等待MySQL启动
echo -e "${YELLOW}步骤4: 等待MySQL启动...${NC}"
echo "等待30秒..."
sleep 30

# 5. 检查容器状态
if docker ps | grep -q "entrepreneurship_mysql"; then
    echo -e "${GREEN}✓ MySQL容器启动成功${NC}"
    docker ps | grep entrepreneurship_mysql
else
    echo -e "${RED}✗ MySQL容器启动失败${NC}"
    docker logs entrepreneurship_mysql
    exit 1
fi

# 6. 验证数据库
echo -e "${YELLOW}步骤5: 验证数据库...${NC}"
sleep 5
docker exec entrepreneurship_mysql mysql -uroot -proot123456 -e "SHOW DATABASES;" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 可以连接到MySQL${NC}"
    
    # 检查表是否导入成功
    TABLE_COUNT=$(docker exec entrepreneurship_mysql mysql -uroot -proot123456 -e "USE entrepreneurship_system; SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='entrepreneurship_system';" 2>/dev/null | tail -1)
    echo "数据库中的表数量: $TABLE_COUNT"
    
    if [ "$TABLE_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✓ 数据库初始化成功${NC}"
    else
        echo -e "${YELLOW}⚠ 数据库为空，可能需要手动导入SQL${NC}"
        echo "手动导入命令："
        echo "docker exec -i entrepreneurship_mysql mysql -uroot -proot123456 entrepreneurship_system < init.sql"
    fi
else
    echo -e "${RED}✗ 无法连接到MySQL${NC}"
    echo "查看日志："
    docker logs entrepreneurship_mysql
    exit 1
fi

echo ""
echo -e "${GREEN}=== MySQL数据库部署完成！===${NC}"
echo ""
echo "数据库连接信息："
echo "  主机: collegetopics.cn"
echo "  端口: 3306"
echo "  用户: root"
echo "  密码: root123456"
echo "  数据库: entrepreneurship_system"
echo ""
echo "常用命令："
echo "  查看日志: docker logs entrepreneurship_mysql"
echo "  连接数据库: docker exec -it entrepreneurship_mysql mysql -uroot -proot123456"
echo "  停止容器: docker stop entrepreneurship_mysql"
echo "  启动容器: docker start entrepreneurship_mysql"

