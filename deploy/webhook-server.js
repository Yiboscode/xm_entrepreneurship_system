#!/usr/bin/env node
/**
 * GitHub Webhook 自动部署服务器
 * 监听GitHub的push事件，自动拉取代码并重新部署
 */

const http = require('http');
const crypto = require('crypto');
const { execSync } = require('child_process');
const fs = require('fs');

// 配置
const CONFIG = {
    port: 9999,
    secret: 'your_webhook_secret_123456',  // 与GitHub配置的Secret一致
    projectPath: '/home/ubuntu/xm_entrepreneurship_system',
    logFile: '/home/ubuntu/xm_entrepreneurship_system/deploy/webhook.log'
};

// 日志函数
function log(message) {
    const timestamp = new Date().toISOString();
    const logMessage = `[${timestamp}] ${message}\n`;
    console.log(logMessage);
    fs.appendFileSync(CONFIG.logFile, logMessage);
}

// 验证GitHub签名
function verifySignature(payload, signature) {
    if (!signature) {
        return false;
    }
    const hmac = crypto.createHmac('sha256', CONFIG.secret);
    const digest = 'sha256=' + hmac.update(payload).digest('hex');
    return crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(digest));
}

// 执行命令
function execCommand(command) {
    log(`执行命令: ${command}`);
    try {
        const output = execSync(command, { 
            cwd: CONFIG.projectPath,
            encoding: 'utf8',
            maxBuffer: 10 * 1024 * 1024 // 10MB
        });
        log(`命令输出: ${output}`);
        return { success: true, output };
    } catch (error) {
        log(`命令错误: ${error.message}`);
        return { success: false, error: error.message };
    }
}

// 部署流程
function deploy() {
    log('========== 开始自动部署 ==========');
    
    // 1. 拉取最新代码
    log('步骤1: 拉取最新代码...');
    const gitPull = execCommand('git pull origin main');
    if (!gitPull.success) {
        log('Git拉取失败，停止部署');
        return { success: false, message: 'Git拉取失败' };
    }
    
    // 2. 打包后端
    log('步骤2: 打包后端...');
    const mvnPackage = execCommand('cd springboot && mvn clean package -DskipTests');
    if (!mvnPackage.success) {
        log('后端打包失败');
        return { success: false, message: '后端打包失败' };
    }
    
    // 3. 打包前端
    log('步骤3: 打包前端...');
    const npmBuild = execCommand('cd vue && npm run build');
    if (!npmBuild.success) {
        log('前端打包失败');
        return { success: false, message: '前端打包失败' };
    }
    
    // 4. 重启Docker容器
    log('步骤4: 重启Docker容器...');
    
    // 停止旧容器
    execCommand('docker stop entrepreneurship_backend entrepreneurship_frontend');
    execCommand('docker rm entrepreneurship_backend entrepreneurship_frontend');
    
    // 构建新镜像
    const buildBackend = execCommand('docker build -t entrepreneurship-backend ./springboot');
    const buildFrontend = execCommand('docker build -t entrepreneurship-frontend ./vue');
    
    if (!buildBackend.success || !buildFrontend.success) {
        log('镜像构建失败');
        return { success: false, message: '镜像构建失败' };
    }
    
    // 启动新容器
    const startBackend = execCommand(`docker run -d \
        --name entrepreneurship_backend \
        --restart always \
        -p 9090:9090 \
        -p 5005:5005 \
        -v ${CONFIG.projectPath}/files:/app/files \
        --link entrepreneurship_mysql:mysql \
        -e SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/entrepreneurship_system?useUnicode=true&characterEncoding=utf-8&allowMultiQueries=true&useSSL=false&serverTimezone=GMT%2b8&allowPublicKeyRetrieval=true \
        -e SPRING_DATASOURCE_PASSWORD=root123456 \
        entrepreneurship-backend`);
    
    const startFrontend = execCommand(`docker run -d \
        --name entrepreneurship_frontend \
        --restart always \
        -p 80:80 \
        --link entrepreneurship_backend:backend \
        entrepreneurship-frontend`);
    
    if (!startBackend.success || !startFrontend.success) {
        log('容器启动失败');
        return { success: false, message: '容器启动失败' };
    }
    
    log('========== 部署成功完成 ==========');
    return { success: true, message: '部署成功' };
}

// HTTP服务器
const server = http.createServer((req, res) => {
    if (req.method === 'POST' && req.url === '/webhook') {
        let body = '';
        
        req.on('data', chunk => {
            body += chunk.toString();
        });
        
        req.on('end', () => {
            const signature = req.headers['x-hub-signature-256'];
            
            // 验证签名
            if (!verifySignature(body, signature)) {
                log('签名验证失败');
                res.writeHead(401);
                res.end('Unauthorized');
                return;
            }
            
            const payload = JSON.parse(body);
            const event = req.headers['x-github-event'];
            
            log(`收到GitHub事件: ${event}`);
            log(`提交信息: ${payload.head_commit?.message || 'N/A'}`);
            log(`提交者: ${payload.pusher?.name || 'N/A'}`);
            
            // 只处理push事件
            if (event === 'push') {
                // 异步执行部署，立即返回响应
                res.writeHead(200);
                res.end('Webhook received, deploying...');
                
                // 延迟2秒后开始部署
                setTimeout(() => {
                    const result = deploy();
                    if (result.success) {
                        log('自动部署完成');
                    } else {
                        log(`自动部署失败: ${result.message}`);
                    }
                }, 2000);
            } else {
                log(`忽略事件: ${event}`);
                res.writeHead(200);
                res.end('Event ignored');
            }
        });
    } else {
        res.writeHead(404);
        res.end('Not Found');
    }
});

server.listen(CONFIG.port, () => {
    log(`Webhook服务器启动，监听端口 ${CONFIG.port}`);
    log(`项目路径: ${CONFIG.projectPath}`);
});

// 错误处理
process.on('uncaughtException', (error) => {
    log(`未捕获的异常: ${error.message}`);
});

process.on('unhandledRejection', (error) => {
    log(`未处理的Promise拒绝: ${error.message}`);
});

