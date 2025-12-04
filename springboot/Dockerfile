FROM openjdk:21-jdk-slim

# 设置工作目录
WORKDIR /app

# 复制jar包
COPY target/springboot-0.0.1-SNAPSHOT.jar app.jar

# 创建files目录
RUN mkdir -p /app/files

# 暴露端口
EXPOSE 9090

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD curl -f http://localhost:9090/ || exit 1

# 启动应用
ENTRYPOINT ["java", "-Xms512m", "-Xmx2g", "-jar", "app.jar"]

