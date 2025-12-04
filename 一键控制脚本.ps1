# 远程服务器一键控制脚本
# 使用方法：.\一键控制脚本.ps1 -Action start

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('start','stop','restart','status','logs','deploy','mysql')]
    [string]$Action = "status"
)

$server = "ubuntu@collegetopics.cn"
$projectPath = "~/xm_entrepreneurship_system"

Write-Host "================================" -ForegroundColor Cyan
Write-Host "  创新创业选题系统 远程控制" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

switch ($Action) {
    'start' {
        Write-Host "🚀 启动所有服务..." -ForegroundColor Green
        ssh $server "cd $projectPath && docker start entrepreneurship_mysql entrepreneurship_backend entrepreneurship_frontend"
        Write-Host ""
        Write-Host "✅ 服务启动命令已发送" -ForegroundColor Green
        Write-Host "等待5秒后查看状态..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
        ssh $server "cd $projectPath && docker ps"
    }
    'stop' {
        Write-Host "⏸️  停止所有服务..." -ForegroundColor Yellow
        ssh $server "cd $projectPath && docker stop entrepreneurship_backend entrepreneurship_frontend"
        Write-Host ""
        Write-Host "✅ 服务已停止（MySQL保持运行）" -ForegroundColor Green
    }
    'restart' {
        Write-Host "🔄 重启所有服务..." -ForegroundColor Cyan
        ssh $server "cd $projectPath && docker restart entrepreneurship_backend entrepreneurship_frontend"
        Write-Host ""
        Write-Host "✅ 服务重启命令已发送" -ForegroundColor Green
        Write-Host "等待5秒后查看状态..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
        ssh $server "cd $projectPath && docker ps"
    }
    'status' {
        Write-Host "📊 查看服务状态..." -ForegroundColor Blue
        Write-Host ""
        ssh $server "cd $projectPath && docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep entrepreneurship"
        Write-Host ""
        Write-Host "💾 磁盘使用情况:" -ForegroundColor Magenta
        ssh $server "df -h | grep -E 'Filesystem|/$'"
    }
    'logs' {
        Write-Host "📝 查看后端日志（最近50行）..." -ForegroundColor Magenta
        Write-Host ""
        ssh $server "cd $projectPath && docker logs --tail=50 entrepreneurship_backend"
        Write-Host ""
        Write-Host "按任意键查看前端日志..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        ssh $server "cd $projectPath && docker logs --tail=50 entrepreneurship_frontend"
    }
    'deploy' {
        Write-Host "📦 准备部署最新代码..." -ForegroundColor Green
        Write-Host ""
        Write-Host "步骤1: 打包后端..." -ForegroundColor Yellow
        cd springboot
        mvn clean package -DskipTests
        
        Write-Host "步骤2: 打包前端..." -ForegroundColor Yellow
        cd ..\vue
        npm run build
        
        Write-Host "步骤3: 上传到服务器..." -ForegroundColor Yellow
        scp -r ..\springboot\target\springboot-0.0.1-SNAPSHOT.jar "${server}:${projectPath}/springboot/target/"
        scp -r dist "${server}:${projectPath}/vue/"
        
        Write-Host "步骤4: 重启服务..." -ForegroundColor Yellow
        ssh $server "cd $projectPath && docker restart entrepreneurship_backend entrepreneurship_frontend"
        
        Write-Host ""
        Write-Host "✅ 部署完成！" -ForegroundColor Green
    }
    'mysql' {
        Write-Host "🗄️  连接到MySQL数据库..." -ForegroundColor Blue
        Write-Host ""
        Write-Host "提示：执行以下命令查看数据" -ForegroundColor Yellow
        Write-Host "  USE entrepreneurship_system;" -ForegroundColor Gray
        Write-Host "  SHOW TABLES;" -ForegroundColor Gray
        Write-Host "  SELECT * FROM admin;" -ForegroundColor Gray
        Write-Host "  EXIT;" -ForegroundColor Gray
        Write-Host ""
        ssh -t $server "docker exec -it entrepreneurship_mysql mysql -uroot -proot123456"
    }
}

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "可用命令:" -ForegroundColor White
Write-Host "  .\一键控制脚本.ps1 -Action start    # 启动服务" -ForegroundColor Gray
Write-Host "  .\一键控制脚本.ps1 -Action stop     # 停止服务" -ForegroundColor Gray
Write-Host "  .\一键控制脚本.ps1 -Action restart  # 重启服务" -ForegroundColor Gray
Write-Host "  .\一键控制脚本.ps1 -Action status   # 查看状态" -ForegroundColor Gray
Write-Host "  .\一键控制脚本.ps1 -Action logs     # 查看日志" -ForegroundColor Gray
Write-Host "  .\一键控制脚本.ps1 -Action deploy   # 部署更新" -ForegroundColor Gray
Write-Host "  .\一键控制脚本.ps1 -Action mysql    # 连接数据库" -ForegroundColor Gray
Write-Host ""

