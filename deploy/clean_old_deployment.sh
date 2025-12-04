#!/bin/bash
# 清理旧部署脚本

echo "=== 开始清理旧部署 ==="

# 1. 停止所有容器
echo "1. 停止容器..."
docker stop entrepreneurship_frontend entrepreneurship_backend entrepreneurship_mysql

# 2. 删除容器
echo "2. 删除容器..."
docker rm entrepreneurship_frontend entrepreneurship_backend entrepreneurship_mysql

# 3. 删除镜像（可选）
echo "3. 删除旧镜像..."
docker rmi collegetopics-frontend collegetopics-backend

# 4. 删除数据卷（谨慎！会删除数据）
echo "4. 是否删除MySQL数据卷？这将删除所有数据库数据！"
read -p "输入 'yes' 确认删除: " confirm
if [ "$confirm" = "yes" ]; then
    docker volume rm entrepreneurship_mysql_data 2>/dev/null || echo "数据卷不存在或已删除"
fi

# 5. 清理未使用的资源
echo "5. 清理未使用的Docker资源..."
docker system prune -f

echo "=== 清理完成 ==="

