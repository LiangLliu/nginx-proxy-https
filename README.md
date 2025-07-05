# Nginx Proxy HTTPS

基于 Docker Compose 的 Nginx 反向代理解决方案，支持自动申请和续签 Let's Encrypt SSL 证书。

## 🚀 快速开始

```bash
# 1. 初始配置
./manage.sh setup

# 2. 启动服务
./manage.sh start

# 3. 查看状态
./manage.sh status
```

## 📋 管理命令

```bash
./manage.sh start          # 启动服务
./manage.sh stop           # 停止服务
./manage.sh restart        # 重启服务
./manage.sh status         # 查看状态
./manage.sh logs [service] # 查看日志
./manage.sh monitor        # 监控报告
./manage.sh dns-check      # DNS检查
./manage.sh add-service    # 添加服务
./manage.sh backup         # 备份配置
./manage.sh help           # 显示帮助
```

## 📁 项目结构

```
nginx-proxy-https/
├── manage.sh              # 统一管理脚本
├── docker-compose.yml     # 服务配置（用户配置）
├── docker-compose.example.yml # 配置示例
├── env.example            # 环境变量模板
├── setup-env.sh          # 环境配置脚本
├── .env                   # 环境变量（用户配置）
├── certs/                 # SSL证书目录
└── .gitignore            # Git忽略文件
```

## 🔧 配置说明

### 环境变量 (.env)
```bash
DEFAULT_EMAIL=your-email@example.com  # 证书通知邮箱
DEFAULT_RENEW=30                      # 证书续签阈值（天）
CERTS_UPDATE_INTERVAL=3600            # 证书检查间隔（秒）
```

### 服务配置 (docker-compose.yml)
每个服务需要配置：
```yaml
your-service:
  environment:
    - VIRTUAL_HOST=your-domain.com    # 域名
    - VIRTUAL_PORT=80                 # 服务端口
    - LETSENCRYPT_HOST=your-domain.com # 证书域名
    - LETSENCRYPT_EMAIL=${LETSENCRYPT_EMAIL}
```

## 🌐 访问方式

- 所有服务通过 HTTPS 访问：`https://your-domain.com`
- 证书自动申请和续签
- 支持多服务、多域名

## 📞 支持

- 查看完整状态：`./manage.sh monitor`
- 检查DNS配置：`./manage.sh dns-check`
- 查看服务日志：`./manage.sh logs` 