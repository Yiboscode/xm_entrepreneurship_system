# 创新创业课程考核项目选题系统

## 📋 项目简介

这是一个基于 Spring Boot + Vue 3 的创新创业课程考核项目选题系统，支持学生选题、教师评价、团队管理等功能。

## 🛠️ 技术栈

### 后端
- Spring Boot 3.3.1
- MyBatis 3.0.3
- MySQL 8.0
- JWT 认证
- Hutool 工具库

### 前端
- Vue 3.4.29
- Element Plus 2.8.4
- Vite 5.3.1
- Axios
- ECharts

### 部署
- Docker + Docker Compose
- Nginx
- Git + Webhook 自动部署

## 📦 快速开始

### 本地开发

#### 1. 克隆项目
```bash
git clone https://github.com/Yiboscode/xm_entrepreneurship_system.git
cd xm_entrepreneurship_system
```

#### 2. 配置数据库
修改 `springboot/src/main/resources/application.yml`：
```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/entrepreneurship_system
    username: root
    password: your_password
```

#### 3. 启动后端
```bash
cd springboot
mvn spring-boot:run
```

#### 4. 启动前端
```bash
cd vue
npm install
npm run dev
```

#### 5. 访问系统
打开浏览器访问：http://localhost:5173

默认管理员账号：`admin` / `admin`

## 🐳 Docker部署

### 1. 构建镜像
```bash
docker build -t entrepreneurship-backend ./springboot
docker build -t entrepreneurship-frontend ./vue
```

### 2. 启动服务
```bash
docker-compose up -d
```

### 3. 查看状态
```bash
docker-compose ps
```

## 🔧 自动化部署

项目支持 Git + Webhook 自动部署，推送到 GitHub 后自动更新服务器。

详细配置见：[部署文档](deploy/README.md)

## 📚 功能模块

- ✅ 用户管理（管理员、教师、学生）
- ✅ 选题管理（提交、评价、审核）
- ✅ 团队管理（创建、申请、成员）
- ✅ 创新能力评价（12项指标）
- ✅ 项目管理（发布、报名、任务）
- ✅ 问答系统
- ✅ 优秀选题库
- ✅ 数据统计

## 🔐 安全性

⚠️ **重要提醒**：
- 请修改默认密码
- 建议启用密码加密
- 配置防火墙和HTTPS

## 📝 开发文档

- [本地测试和部署指南](本地测试和部署指南.md)
- [代码审查报告](代码审查报告.md)
- [远程调试配置](.idea-remote-debug.md)

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT License

## 👥 作者

Yiboscode

## 📧 联系方式

如有问题，请提交 Issue 或联系作者。

