# Nginx Proxy with HTTPS Auto-Certificates

一个基于 Docker Compose 的 Nginx 反向代理解决方案，支持自动申请和续签 Let's Encrypt SSL 证书。

## 🚀 项目特性

- ✅ **自动 HTTPS**：自动为域名申请和配置 Let's Encrypt SSL 证书
- ✅ **反向代理**：基于 Docker 容器自动发现和配置虚拟主机
- ✅ **证书管理**：自动续签证书（默认30天续签阈值）
- ✅ **高可用性**：容器自动重启，服务稳定运行
- ✅ **简单部署**：一键启动，零配置

## 📋 系统要求

- Docker 20.10+
- Docker Compose 2.0+
- 域名解析到服务器 IP
- 开放 80 和 443 端口

## 🛠️ 快速开始

### 1. 克隆项目
```bash
git clone <your-repo-url>
cd nginx-proxy-https
```

### 2. 配置环境变量
项目使用 `.env` 文件管理配置。

#### 方式一：交互式配置（推荐）
```bash
./setup-env.sh
```

#### 方式二：手动配置
```bash
# 复制环境变量模板
cp env.example .env

# 编辑配置文件
nano .env
```

主要配置项：
- `DEFAULT_EMAIL`: 证书通知邮箱
- `VIRTUAL_HOST`: 域名
- `LETSENCRYPT_HOST`: 申请证书的域名

### 3. 配置域名
确保你的域名正确解析到服务器 IP：
```bash
nslookup your-domain.com
```

### 4. 创建配置文件
```bash
# 复制示例配置文件
cp docker-compose.example.yml docker-compose.yml

# 根据需要修改 docker-compose.yml 中的服务配置
```

### 5. 启动服务
```bash
# 启动所有服务
./deploy.sh

# 或者直接使用 docker compose
docker compose up -d
```

### 6. 验证安装
```bash
# 检查服务状态
docker compose ps

# 测试 HTTPS
curl -I https://your-domain.com
```

### 7. 监控服务
```bash
# 查看服务状态和证书信息
./monitor.sh
```

## 📁 项目结构

```
nginx-proxy-https/
├── docker-compose.example.yml      # 多端口访问配置示例
├── README.md                       # 项目说明文档
├── USAGE.md                        # 使用说明
├── setup-env.sh                   # 环境变量配置脚本
├── deploy.sh                      # 部署脚本
├── monitor.sh                     # 监控脚本
├── env.example                    # 环境变量模板
├── .env                           # 环境变量文件（用户配置，不提交到Git）
├── docker-compose.yml             # 用户配置文件（不提交到Git）
├── certs/                         # SSL 证书目录（不提交到Git）
│   └── your-domain.com/           # 每个域名的证书
│       ├── cert.pem               # 域名证书
│       ├── key.pem                # 私钥
│       ├── chain.pem              # 中间证书
│       └── fullchain.pem          # 完整证书链
├── LICENSE                        # 许可证文件
└── .gitignore                     # Git 忽略文件
```

## 🔧 配置说明

### 核心服务

#### 1. nginx-proxy
- **镜像**：`jwilder/nginx-proxy`
- **端口**：80, 443
- **功能**：反向代理服务器，自动发现容器

#### 2. letsencrypt
- **镜像**：`nginxproxy/acme-companion`
- **功能**：自动申请和续签 SSL 证书
- **配置**：
  - `DEFAULT_EMAIL`：证书通知邮箱
  - `DEFAULT_RENEW`：续签阈值（天）
  - `CERTS_UPDATE_INTERVAL`：检查间隔（秒）

### 环境变量
| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `DEFAULT_EMAIL` | - | 证书通知邮箱（必需） |
| `DEFAULT_RENEW` | 30 | 证书续签阈值（天） |
| `CERTS_UPDATE_INTERVAL` | 3600 | 证书检查间隔（秒） |
| `VIRTUAL_HOST` | - | 域名（必需） |
| `VIRTUAL_PORT` | 80 | 应用服务端口（可选，默认80） |
| `LETSENCRYPT_HOST` | - | 申请证书的域名（必需） |
| `LETSENCRYPT_EMAIL` | - | 证书邮箱（可选） |

## 🚀 多服务支持

使用不同端口访问不同服务，在 nginx-proxy 中添加端口映射：

```yaml
services:
  nginx-proxy:
    image: nginxproxy/nginx-proxy
    ports:
      - "80:80"
      - "443:443"
      - "8060:8060"  # 添加 8060 端口
      - "9000:9000"  # 添加 9000 端口

  # 主服务 (端口80)
  main-app:
    image: nginx
    container_name: main-app
    restart: always
    expose:
      - "80"
    environment:
      - VIRTUAL_HOST=${VIRTUAL_HOST}
      - VIRTUAL_PORT=80
      - LETSENCRYPT_HOST=${LETSENCRYPT_HOST}
      - LETSENCRYPT_EMAIL=${LETSENCRYPT_EMAIL}

  # 新服务 (端口8060)
  new-service:
    image: your-new-service-image
    container_name: new-service
    restart: always
    expose:
      - "8060"
    environment:
      - VIRTUAL_HOST=${VIRTUAL_HOST}
      - VIRTUAL_PORT=8060
      - LETSENCRYPT_HOST=${LETSENCRYPT_HOST}
      - LETSENCRYPT_EMAIL=${LETSENCRYPT_EMAIL}
```

访问方式：
- 主服务：`https://your-domain.com/` (443端口)
- 新服务：`https://your-domain.com:8060/` (8060端口)

### 注意事项

1. **端口配置**需要确保：
   - 在 nginx-proxy 的 ports 中添加相应端口映射
   - 服务器防火墙开放相应端口
   - 云服务商安全组开放端口
   - Let's Encrypt 会为每个端口申请证书

2. **添加新服务步骤**：
   - 在 nginx-proxy 的 ports 中添加新端口
   - 添加新服务配置，使用 expose 和 VIRTUAL_PORT
   - 重启服务：`docker compose up -d` 