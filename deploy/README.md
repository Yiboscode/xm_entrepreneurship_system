# 创新创业选题系统部署文档

## 📋 部署环境

- 服务器：collegetopics.cn
- 操作系统：Ubuntu
- 容器技术：Docker + Docker Compose
- 数据库：MySQL 8.0

## 🚀 部署步骤

### 步骤1：清理旧部署

在服务器上执行：

```bash
cd ~/xm_entrepreneurship_system

# 停止旧容器
docker stop entrepreneurship_frontend entrepreneurship_backend entrepreneurship_mysql

# 删除旧容器
docker rm entrepreneurship_frontend entrepreneurship_backend entrepreneurship_mysql

# 删除旧镜像
docker rmi collegetopics-frontend collegetopics-backend 2>/dev/null

# 清理未使用的资源
docker system prune -f

# 查看是否清理干净
docker ps -a
```

### 步骤2：准备部署文件

在本地执行：

```bash
# 1. 复制数据库文件到deploy目录
cp entrepreneurship_system.sql deploy/init.sql

# 2. 上传部署文件到服务器
scp -r deploy/* ubuntu@collegetopics.cn:~/xm_entrepreneurship_system/
```

或者使用SFTP工具（推荐）上传以下文件：
- `deploy/docker-compose.yml` → 服务器的 `~/xm_entrepreneurship_system/`
- `entrepreneurship_system.sql` → 服务器的 `~/xm_entrepreneurship_system/init.sql`

### 步骤3：部署MySQL数据库

在服务器上执行：

```bash
cd ~/xm_entrepreneurship_system

# 启动MySQL（仅数据库）
docker-compose up -d mysql

# 查看容器状态
docker-compose ps

# 查看MySQL日志，确保启动成功
docker-compose logs -f mysql
```

等待看到 `ready for connections` 日志后，按 `Ctrl+C` 退出日志查看。

### 步骤4：验证数据库

在服务器上执行：

```bash
# 连接MySQL测试
docker exec -it entrepreneurship_mysql mysql -uroot -proot123456

# 在MySQL中执行
USE entrepreneurship_system;
SHOW TABLES;
SELECT COUNT(*) FROM admin;
EXIT;
```

### 步骤5：修改本地配置文件

#### 5.1 修改后端配置

编辑 `springboot/src/main/resources/application.yml`：

```yaml
server:
  port: 9090

spring:
  servlet:
    multipart:
      max-file-size: 100MB
      max-request-size: 100MB
  datasource:
    driver-class-name: com.mysql.cj.jdbc.Driver
    username: root
    password: root123456  # 改为服务器MySQL密码
    url: jdbc:mysql://collegetopics.cn:3306/entrepreneurship_system?useUnicode=true&characterEncoding=utf-8&allowMultiQueries=true&useSSL=false&serverTimezone=GMT%2b8&allowPublicKeyRetrieval=true

mybatis:
  configuration:
    log-impl: org.apache.ibatis.logging.stdout.StdOutImpl
    map-underscore-to-camel-case: true
  mapper-locations: classpath:mapper/*.xml

fileBaseUrl: https://collegetopics.cn:9090
```

#### 5.2 修改前端配置

创建 `vue/.env.production`：

```env
VITE_BASE_URL=https://collegetopics.cn:9090
```

创建 `vue/.env.development`：

```env
VITE_BASE_URL=http://localhost:9090
```

### 步骤6：本地测试

在本地执行：

```bash
# 启动后端
cd springboot
mvn clean package
java -jar target/springboot-0.0.1-SNAPSHOT.jar

# 另开终端，启动前端
cd vue
npm install
npm run dev
```

访问 http://localhost:5173 测试所有功能。

### 步骤7：部署后端和前端

#### 7.1 创建后端Dockerfile

创建 `springboot/Dockerfile`：

```dockerfile
FROM openjdk:21-jdk-slim
WORKDIR /app
COPY target/springboot-0.0.1-SNAPSHOT.jar app.jar
EXPOSE 9090
ENTRYPOINT ["java", "-Xms512m", "-Xmx2g", "-jar", "app.jar"]
```

#### 7.2 创建前端Dockerfile

创建 `vue/Dockerfile`：

```dockerfile
FROM node:18-alpine as build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

创建 `vue/nginx.conf`：

```nginx
server {
    listen 80;
    server_name collegetopics.cn;
    
    location / {
        root /usr/share/nginx/html;
        index index.html;
        try_files $uri $uri/ /index.html;
    }
    
    location /api {
        proxy_pass http://backend:9090;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

#### 7.3 打包并上传

在本地执行：

```bash
# 打包后端
cd springboot
mvn clean package -DskipTests

# 打包前端
cd ../vue
npm run build

# 上传到服务器
scp -r springboot ubuntu@collegetopics.cn:~/xm_entrepreneurship_system/
scp -r vue ubuntu@collegetopics.cn:~/xm_entrepreneurship_system/
```

#### 7.4 启动完整应用

在服务器上执行：

```bash
cd ~/xm_entrepreneurship_system

# 修改docker-compose.yml，取消backend和frontend的注释

# 启动所有服务
docker-compose up -d

# 查看状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

### 步骤8：配置HTTPS（可选但推荐）

```bash
# 安装Certbot
sudo apt update
sudo apt install certbot python3-certbot-nginx

# 获取SSL证书
sudo certbot --nginx -d collegetopics.cn
```

## 🔍 故障排查

### 查看日志
```bash
# 查看所有日志
docker-compose logs

# 查看特定服务日志
docker-compose logs mysql
docker-compose logs backend
docker-compose logs frontend
```

### 重启服务
```bash
docker-compose restart mysql
docker-compose restart backend
docker-compose restart frontend
```

### 清理并重新部署
```bash
docker-compose down
docker-compose up -d
```

## 📝 注意事项

1. ⚠️ 修改默认密码：将MySQL密码改为更安全的密码
2. ⚠️ 配置防火墙：开放必要端口（80, 443, 9090, 3306）
3. ⚠️ 定期备份数据库
4. ⚠️ 配置HTTPS证书

## 🔐 安全建议

1. 修改MySQL root密码
2. 创建专用数据库用户
3. 配置防火墙规则
4. 启用HTTPS
5. 实施密码加密（参考代码审查报告）

