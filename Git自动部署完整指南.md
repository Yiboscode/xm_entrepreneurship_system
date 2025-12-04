# Git + Webhook + 远程调试 完整配置指南

## 📋 目标

实现：**本地推送代码 → GitHub → 服务器自动部署 + 支持远程调试**

---

## 第一阶段：配置本地Git仓库

### 1. 初始化Git（您已完成）

```bash
cd C:\Users\ya942\Desktop\college\xm_entrepreneurship_system

git init
git add .
git commit -m "Initial commit: 创新创业选题系统"
git branch -M main
git remote add origin https://github.com/Yiboscode/xm_entrepreneurship_system.git
git push -u origin main
```

### 2. 验证推送

访问：https://github.com/Yiboscode/xm_entrepreneurship_system

确认代码已上传成功。

---

## 第二阶段：服务器端配置

### 1. 连接到服务器

```bash
ssh ubuntu@119.29.152.18
```

### 2. 克隆仓库到服务器

```bash
cd ~
# 如果已有项目目录，先备份
mv xm_entrepreneurship_system xm_entrepreneurship_system.backup

# 克隆仓库
git clone https://github.com/Yiboscode/xm_entrepreneurship_system.git
cd xm_entrepreneurship_system

# 查看文件
ls -la
```

### 3. 上传部署文件

**重要**：需要上传以下文件到服务器（因为.gitignore中排除了）：

```bash
# 在本地执行，上传必要文件
scp entrepreneurship_system.sql ubuntu@119.29.152.18:~/xm_entrepreneurship_system/init.sql
scp deploy/setup-webhook.sh ubuntu@119.29.152.18:~/xm_entrepreneurship_system/deploy/
scp deploy/webhook-server.js ubuntu@119.29.152.18:~/xm_entrepreneurship_system/deploy/
```

### 4. 配置Webhook服务器

在服务器上执行：

```bash
cd ~/xm_entrepreneurship_system/deploy

# 设置执行权限
chmod +x setup-webhook.sh

# 运行配置脚本
./setup-webhook.sh
```

脚本会自动：
- ✅ 安装Node.js（如果需要）
- ✅ 安装PM2进程管理器
- ✅ 启动Webhook服务器
- ✅ 配置开机自启
- ✅ 开放防火墙端口

### 5. 验证Webhook服务

```bash
# 查看服务状态
pm2 status

# 查看日志
pm2 logs webhook

# 测试访问
curl http://localhost:9999/webhook
```

---

## 第三阶段：配置GitHub Webhook

### 1. 访问GitHub仓库设置

打开：https://github.com/Yiboscode/xm_entrepreneurship_system/settings/hooks

### 2. 添加Webhook

点击 **Add webhook** 按钮

### 3. 配置Webhook

```
Payload URL: http://119.29.152.18:9999/webhook
Content type: application/json
Secret: your_webhook_secret_123456
```

**SSL verification**: 如果没有HTTPS证书，选择 "Disable"

**Which events would you like to trigger this webhook?**
- 选择 "Just the push event"

点击 **Add webhook** 保存

### 4. 测试Webhook

GitHub会自动发送一个ping事件测试连接。

查看 **Recent Deliveries** 标签，应该看到：
- ✅ 绿色勾号 = 连接成功
- ❌ 红色叉号 = 连接失败（检查防火墙和端口）

---

## 第四阶段：配置IDEA远程调试

### 1. 修改服务器部署脚本

确保使用调试版Dockerfile：

```bash
# 在服务器上
cd ~/xm_entrepreneurship_system

# 编辑webhook-server.js中的Docker启动命令
# 已经包含了 -p 5005:5005 调试端口
```

### 2. 在IDEA中配置Remote Debug

1. 打开IDEA
2. **Run** → **Edit Configurations...**
3. 点击 **+** → **Remote JVM Debug**
4. 配置：

```
Name: 远程调试-创业系统
Host: 119.29.152.18
Port: 5005
Command line arguments: 
  -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005
```

5. 点击 **OK**

### 3. 使用远程调试

1. 在代码中设置断点
2. 点击IDEA右上角的 **Debug** 按钮
3. 选择 **远程调试-创业系统**
4. 看到 "Connected to the target VM" 表示连接成功
5. 访问网站，触发断点

---

## 第五阶段：完整工作流程

### 日常开发流程

```bash
# 1. 本地修改代码（IDEA或VSCode）

# 2. 测试（可选，连接远程MySQL）
cd springboot
mvn spring-boot:run

# 3. 提交到Git
git add .
git commit -m "feat: 添加新功能"
git push

# 4. GitHub自动触发Webhook
# 5. 服务器自动：
#    - 拉取代码
#    - 打包
#    - 构建Docker镜像
#    - 重启容器
# 6. 部署完成！
```

### 查看自动部署日志

```bash
# 在服务器上
pm2 logs webhook

# 或查看日志文件
tail -f ~/xm_entrepreneurship_system/deploy/webhook.log
```

### 如果部署失败

```bash
# 查看详细日志
pm2 logs webhook --lines 100

# 手动触发部署
cd ~/xm_entrepreneurship_system
git pull
cd springboot && mvn clean package -DskipTests
cd ../vue && npm run build

# 重启容器
docker restart entrepreneurship_backend entrepreneurship_frontend
```

---

## 第六阶段：环境配置管理

### 创建环境配置文件

在服务器上创建 `.env.production`（不提交到Git）：

```bash
cd ~/xm_entrepreneurship_system

# 创建环境配置
cat > .env.production <<EOF
# 数据库配置
DB_HOST=mysql
DB_PORT=3306
DB_NAME=entrepreneurship_system
DB_USER=root
DB_PASSWORD=root123456

# 应用配置
SERVER_PORT=9090
DEBUG_PORT=5005

# 文件上传
FILE_BASE_URL=http://119.29.152.18:9090
EOF
```

---

## 🎯 测试自动部署

### 1. 本地修改代码

例如修改 `README.md`：

```bash
echo "测试自动部署功能" >> README.md
git add README.md
git commit -m "test: 测试自动部署"
git push
```

### 2. 观察服务器

```bash
# 在服务器上实时查看日志
pm2 logs webhook --lines 0
```

您应该看到：
```
收到GitHub事件: push
提交信息: test: 测试自动部署
开始自动部署
步骤1: 拉取最新代码...
步骤2: 打包后端...
步骤3: 打包前端...
步骤4: 重启Docker容器...
部署成功完成
```

### 3. 验证部署

访问：http://119.29.152.18

检查修改是否生效。

---

## 📊 监控和管理

### PM2常用命令

```bash
# 查看所有进程
pm2 list

# 查看webhook状态
pm2 status webhook

# 实时日志
pm2 logs webhook

# 重启webhook
pm2 restart webhook

# 停止webhook
pm2 stop webhook

# 删除webhook
pm2 delete webhook

# 查看详细信息
pm2 info webhook

# 监控面板
pm2 monit
```

### Docker容器管理

```bash
# 查看容器状态
docker ps

# 查看容器日志
docker logs -f entrepreneurship_backend
docker logs -f entrepreneurship_frontend

# 重启容器
docker restart entrepreneurship_backend

# 进入容器
docker exec -it entrepreneurship_backend bash
```

---

## 🔧 故障排查

### 问题1：Webhook连接失败

**检查端口**：
```bash
sudo netstat -tulpn | grep 9999
```

**检查防火墙**：
```bash
sudo ufw status
sudo ufw allow 9999/tcp
```

**检查服务**：
```bash
pm2 logs webhook
```

### 问题2：Git拉取失败

**配置Git凭证**：
```bash
# 生成SSH密钥
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# 查看公钥
cat ~/.ssh/id_rsa.pub

# 添加到GitHub: Settings → SSH and GPG keys → New SSH key
```

**或使用HTTPS + Token**：
```bash
# 配置GitHub Token
git config --global credential.helper store
git pull  # 输入用户名和Token
```

### 问题3：Docker构建失败

**查看详细错误**：
```bash
docker build -t entrepreneurship-backend ./springboot --no-cache
```

**清理Docker资源**：
```bash
docker system prune -f
```

---

## 🚀 进阶功能

### 1. 添加构建状态通知

修改 `webhook-server.js`，在部署完成后发送通知：

```javascript
// 可以集成：
// - 邮件通知
// - 钉钉/企业微信机器人
// - Slack通知
```

### 2. 多分支部署

```javascript
// 根据不同分支部署到不同环境
if (payload.ref === 'refs/heads/main') {
    // 部署到生产环境
} else if (payload.ref === 'refs/heads/dev') {
    // 部署到测试环境
}
```

### 3. 回滚功能

```bash
# 保存每次部署的版本
git tag -a v1.0.0 -m "发布版本1.0.0"
git push origin v1.0.0

# 回滚到指定版本
git checkout v1.0.0
```

---

## ✅ 检查清单

部署前确认：

- [ ] 本地代码已推送到GitHub
- [ ] 服务器已克隆仓库
- [ ] Webhook服务器已启动（pm2 status）
- [ ] GitHub Webhook已配置
- [ ] 防火墙端口9999已开放
- [ ] MySQL数据库正常运行
- [ ] 远程调试端口5005已开放
- [ ] IDEA远程调试已配置

---

## 🎉 总结

现在您的开发流程是：

1. **本地开发** → IDEA编写代码
2. **本地测试** → 连接远程MySQL测试
3. **提交代码** → git push
4. **自动部署** → 服务器自动更新
5. **远程调试** → IDEA连接服务器调试
6. **持续迭代** → 循环往复

**这是最专业的开发部署流程！** 🚀

