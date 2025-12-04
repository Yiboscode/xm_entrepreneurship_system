#!/bin/bash
# 服务器管理脚本（在服务器上使用）

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

PROJECT_PATH=~/xm_entrepreneurship_system

show_menu() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}  创新创业选题系统 管理菜单${NC}"
    echo -e "${CYAN}================================${NC}"
    echo ""
    echo -e "${GREEN}1)${NC} 启动所有服务"
    echo -e "${YELLOW}2)${NC} 停止所有服务"
    echo -e "${CYAN}3)${NC} 重启所有服务"
    echo -e "${BLUE}4)${NC} 查看服务状态"
    echo -e "${MAGENTA}5)${NC} 查看后端日志"
    echo -e "${MAGENTA}6)${NC} 查看前端日志"
    echo -e "${MAGENTA}7)${NC} 查看MySQL日志"
    echo -e "${GREEN}8)${NC} 连接MySQL数据库"
    echo -e "${CYAN}9)${NC} 备份数据库"
    echo -e "${YELLOW}10)${NC} 清理Docker资源"
    echo -e "${RED}11)${NC} 完全重新部署"
    echo -e "${NC}0)${NC} 退出"
    echo ""
    echo -n "请选择操作 [0-11]: "
}

start_services() {
    echo -e "${GREEN}启动所有服务...${NC}"
    cd $PROJECT_PATH
    docker start entrepreneurship_mysql
    sleep 5
    docker start entrepreneurship_backend
    sleep 3
    docker start entrepreneurship_frontend
    echo -e "${GREEN}✅ 服务启动完成${NC}"
    docker ps
}

stop_services() {
    echo -e "${YELLOW}停止应用服务（保留MySQL）...${NC}"
    cd $PROJECT_PATH
    docker stop entrepreneurship_backend entrepreneurship_frontend
    echo -e "${GREEN}✅ 应用服务已停止${NC}"
}

restart_services() {
    echo -e "${CYAN}重启应用服务...${NC}"
    cd $PROJECT_PATH
    docker restart entrepreneurship_backend entrepreneurship_frontend
    echo -e "${GREEN}✅ 服务重启完成${NC}"
    sleep 3
    docker ps
}

show_status() {
    echo -e "${BLUE}服务状态：${NC}"
    docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "NAMES|entrepreneurship"
    echo ""
    echo -e "${BLUE}资源使用：${NC}"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" | grep -E "NAME|entrepreneurship"
}

view_backend_logs() {
    echo -e "${MAGENTA}查看后端日志（按Ctrl+C退出）：${NC}"
    docker logs -f --tail=100 entrepreneurship_backend
}

view_frontend_logs() {
    echo -e "${MAGENTA}查看前端日志（按Ctrl+C退出）：${NC}"
    docker logs -f --tail=100 entrepreneurship_frontend
}

view_mysql_logs() {
    echo -e "${MAGENTA}查看MySQL日志（按Ctrl+C退出）：${NC}"
    docker logs -f --tail=100 entrepreneurship_mysql
}

connect_mysql() {
    echo -e "${GREEN}连接到MySQL数据库...${NC}"
    echo -e "${YELLOW}提示：使用 'EXIT;' 退出MySQL${NC}"
    docker exec -it entrepreneurship_mysql mysql -uroot -proot123456
}

backup_database() {
    echo -e "${CYAN}备份数据库...${NC}"
    BACKUP_FILE="backup-$(date +%Y%m%d-%H%M%S).sql"
    docker exec entrepreneurship_mysql mysqldump -uroot -proot123456 entrepreneurship_system > $PROJECT_PATH/$BACKUP_FILE
    echo -e "${GREEN}✅ 数据库备份完成: $BACKUP_FILE${NC}"
    ls -lh $PROJECT_PATH/$BACKUP_FILE
}

clean_docker() {
    echo -e "${YELLOW}清理Docker资源...${NC}"
    docker system prune -f
    echo -e "${GREEN}✅ 清理完成${NC}"
}

full_redeploy() {
    echo -e "${RED}警告：将停止所有容器并重新部署！${NC}"
    read -p "确认继续？(yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
        echo -e "${CYAN}1. 停止容器...${NC}"
        docker stop entrepreneurship_backend entrepreneurship_frontend entrepreneurship_mysql
        
        echo -e "${CYAN}2. 删除容器...${NC}"
        docker rm entrepreneurship_backend entrepreneurship_frontend
        
        echo -e "${CYAN}3. 删除镜像...${NC}"
        docker rmi entrepreneurship-backend entrepreneurship-frontend 2>/dev/null || true
        
        echo -e "${CYAN}4. 重新构建...${NC}"
        cd $PROJECT_PATH
        docker build -t entrepreneurship-backend ./springboot
        docker build -t entrepreneurship-frontend ./vue
        
        echo -e "${CYAN}5. 启动服务...${NC}"
        ./deploy/一键部署脚本.sh
        
        echo -e "${GREEN}✅ 重新部署完成${NC}"
    else
        echo "已取消"
    fi
}

# 主循环
while true; do
    show_menu
    read choice
    echo ""
    
    case $choice in
        1) start_services ;;
        2) stop_services ;;
        3) restart_services ;;
        4) show_status ;;
        5) view_backend_logs ;;
        6) view_frontend_logs ;;
        7) view_mysql_logs ;;
        8) connect_mysql ;;
        9) backup_database ;;
        10) clean_docker ;;
        11) full_redeploy ;;
        0) echo "退出"; exit 0 ;;
        *) echo -e "${RED}无效选项${NC}" ;;
    esac
    
    echo ""
    read -p "按回车键继续..."
    clear
done

