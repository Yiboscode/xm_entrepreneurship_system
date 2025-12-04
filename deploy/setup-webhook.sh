#!/bin/bash
# 配置GitHub Webhook自动部署

set -e

echo "========================================="
echo "  配置GitHub Webhook自动部署系统"
echo "========================================="
echo ""

PROJECT_PATH=~/xm_entrepreneurship_system
WEBHOOK_PORT=9999
WEBHOOK_SECRET="your_webhook_secret_123456"

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 1. 检查Node.js
echo -e "${YELLOW}步骤1: 检查Node.js...${NC}"
if ! command -v node &> /dev/null; then
    echo "安装Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi
node --version
npm --version

# 2. 配置Git
echo -e "${YELLOW}步骤2: 配置Git...${NC}"
cd $PROJECT_PATH

# 设置Git用户信息（如果还没设置）
if [ -z "$(git config user.name)" ]; then
    echo "请输入Git用户名:"
    read git_username
    git config --global user.name "$git_username"
fi

if [ -z "$(git config user.email)" ]; then
    echo "请输入Git邮箱:"
    read git_email
    git config --global user.email "$git_email"
fi

# 3. 添加GitHub远程仓库（如果还没添加）
echo -e "${YELLOW}步骤3: 配置GitHub仓库...${NC}"
if ! git remote | grep -q origin; then
    git remote add origin https://github.com/Yiboscode/xm_entrepreneurship_system.git
fi

# 4. 安装PM2（进程管理器）
echo -e "${YELLOW}步骤4: 安装PM2...${NC}"
if ! command -v pm2 &> /dev/null; then
    sudo npm install -g pm2
fi
pm2 --version

# 5. 启动Webhook服务器
echo -e "${YELLOW}步骤5: 启动Webhook服务器...${NC}"
cd $PROJECT_PATH/deploy

# 停止旧的webhook服务
pm2 delete webhook 2>/dev/null || true

# 启动新的webhook服务
pm2 start webhook-server.js --name webhook

# 设置开机自启
pm2 startup
pm2 save

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}  Webhook服务器配置完成！${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "Webhook URL: http://collegetopics.cn:$WEBHOOK_PORT/webhook"
echo "Secret: $WEBHOOK_SECRET"
echo ""
echo -e "${YELLOW}下一步：在GitHub仓库配置Webhook${NC}"
echo ""
echo "1. 访问: https://github.com/Yiboscode/xm_entrepreneurship_system/settings/hooks"
echo "2. 点击 'Add webhook'"
echo "3. 配置:"
echo "   - Payload URL: http://collegetopics.cn:$WEBHOOK_PORT/webhook"
echo "   - Content type: application/json"
echo "   - Secret: $WEBHOOK_SECRET"
echo "   - Which events: Just the push event"
echo "4. 点击 'Add webhook'"
echo ""
echo "常用命令:"
echo "  pm2 status        # 查看服务状态"
echo "  pm2 logs webhook  # 查看日志"
echo "  pm2 restart webhook  # 重启服务"
echo "  pm2 stop webhook  # 停止服务"
echo ""
echo -e "${YELLOW}测试部署：推送代码到GitHub，服务器会自动部署！${NC}"
echo ""

# 6. 配置防火墙
echo -e "${YELLOW}步骤6: 配置防火墙...${NC}"
if command -v ufw &> /dev/null; then
    sudo ufw allow $WEBHOOK_PORT/tcp
    echo "已开放端口 $WEBHOOK_PORT"
fi

# 7. 显示服务状态
echo -e "${YELLOW}当前Webhook服务状态:${NC}"
pm2 status

