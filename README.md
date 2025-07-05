# Nginx Proxy HTTPS

基于 [nginx-proxy](https://github.com/nginx-proxy/nginx-proxy) 和 [acme-companion](https://github.com/nginx-proxy/acme-companion) 的 Docker Compose 解决方案，支持自动申请和续签 Let's Encrypt SSL 证书。

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

## 🔧 HTTPS 管理脚本

```bash
./fix-https.sh             # 修复所有域名的证书软链接
./test-https.sh            # 测试所有域名的 HTTPS 功能
```

## 📁 项目结构

```
nginx-proxy-https/
├── manage.sh              # 统一管理脚本
├── fix-https.sh           # HTTPS 证书修复脚本
├── test-https.sh          # HTTPS 功能测试脚本
├── common.sh              # 公共函数库
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

### 单域名配置 (docker-compose.yml)
```yaml
your-service:
  environment:
    - VIRTUAL_HOST=your-domain.com    # 域名
    - VIRTUAL_PORT=80                 # 服务端口
    - LETSENCRYPT_HOST=your-domain.com # 证书域名
    - LETSENCRYPT_EMAIL=${LETSENCRYPT_EMAIL}
```

### 多域名配置 (docker-compose-multi-domain.yml)
```yaml
# 后端 API 服务
api-service:
  environment:
    - VIRTUAL_HOST=api.example.com
    - VIRTUAL_PORT=8080
    - LETSENCRYPT_HOST=api.example.com

# 前端应用服务
frontend-service:
  environment:
    - VIRTUAL_HOST=app.example.com
    - VIRTUAL_PORT=80
    - LETSENCRYPT_HOST=app.example.com

# 管理面板服务
admin-service:
  environment:
    - VIRTUAL_HOST=admin.example.com
    - VIRTUAL_PORT=3000
    - LETSENCRYPT_HOST=admin.example.com
```

## 🚀 多域名管理

### 自动检测和修复
脚本会自动检测 `docker-compose.yml` 中配置的所有域名：

```bash
# 修复所有域名的证书
./fix-https.sh

# 测试所有域名的 HTTPS 功能
./test-https.sh
```

### 智能健康检查
- **自动发现**：从配置文件自动提取 VIRTUAL_HOST 域名
- **智能策略**：优先检查 `/actuator/health`，fallback 到根路径 `/`
- **并行检查**：同时检查多个服务的健康状态
- **高效验证**：每5秒检查一次，最多等待120秒

### 公共函数库
- `common.sh` 包含可复用的通用函数
- `extract_domains()` 自动从 docker-compose.yml 提取域名
- 所有脚本通过 `source` 引用公共函数，便于维护

## 🌐 DNS 配置

### 方式一：通配符记录（推荐）
在您的 DNS 管理平台添加一条 A 记录：
```
*.your-domain.com    A    YOUR_SERVER_IP
```

### 方式二：单独记录
为每个子域名添加 A 记录：
```
api.your-domain.com    A    YOUR_SERVER_IP
app.your-domain.com    A    YOUR_SERVER_IP
admin.your-domain.com  A    YOUR_SERVER_IP
```

### 检查 DNS 配置
```bash
./manage.sh dns-check
```

## 🔧 技术架构

### 核心组件
- **nginx-proxy**: 自动发现 Docker 容器并配置反向代理
- **acme-companion**: 自动申请和续签 Let's Encrypt SSL 证书
- **Docker Compose**: 容器编排和管理

### 工作原理
1. nginx-proxy 监听 Docker 事件，自动发现带有 `VIRTUAL_HOST` 环境变量的容器
2. acme-companion 为每个 `LETSENCRYPT_HOST` 自动申请 SSL 证书
3. 证书自动续签，无需手动干预
4. 所有服务通过 HTTPS 访问，证书完全自动化管理

## 🌐 访问方式

- 所有服务通过 HTTPS 访问：`https://your-domain.com`
- 证书自动申请和续签
- 支持多服务、多域名

## 📞 支持

- 查看完整状态：`./manage.sh monitor`
- 检查DNS配置：`./manage.sh dns-check`
- 查看服务日志：`./manage.sh logs`
- 修复HTTPS证书：`./fix-https.sh`
- 测试HTTPS功能：`./test-https.sh`

## 🔗 相关项目

- [nginx-proxy](https://github.com/nginx-proxy/nginx-proxy) - 自动 Docker 反向代理
- [acme-companion](https://github.com/nginx-proxy/acme-companion) - Let's Encrypt 证书管理 