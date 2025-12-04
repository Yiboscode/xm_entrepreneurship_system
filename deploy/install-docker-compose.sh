#!/bin/bash
# 安装 Docker Compose 脚本

echo "=== 安装 Docker Compose ==="

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then 
    echo "请使用 sudo 运行此脚本"
    exit 1
fi

# 方法1: 安装 Docker Compose Plugin (推荐)
echo "方法1: 安装 Docker Compose Plugin..."
apt update
apt install -y docker-compose-plugin

# 验证安装
if docker compose version &> /dev/null; then
    echo "✓ Docker Compose Plugin 安装成功"
    docker compose version
    exit 0
fi

# 方法2: 安装独立的 docker-compose
echo "方法2: 安装独立的 docker-compose..."
apt install -y docker-compose

# 验证安装
if docker-compose --version &> /dev/null; then
    echo "✓ docker-compose 安装成功"
    docker-compose --version
    exit 0
fi

# 方法3: 从 GitHub 下载最新版本
echo "方法3: 从 GitHub 下载..."
COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# 验证安装
if docker-compose --version &> /dev/null; then
    echo "✓ docker-compose 安装成功"
    docker-compose --version
    exit 0
fi

echo "✗ Docker Compose 安装失败"
exit 1

