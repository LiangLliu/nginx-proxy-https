# 使用说明

## 🚀 快速部署

1. **配置环境**
   ```bash
   ./setup-env.sh
   ```

2. **创建配置文件**
   ```bash
   cp docker-compose.example.yml docker-compose.yml
   ```

3. **启动服务**
   ```bash
   ./deploy.sh
   ```

4. **监控状态**
   ```bash
   ./monitor.sh
   ```

## 📋 常用命令

| 命令 | 说明 |
|------|------|
| `docker compose up -d` | 启动所有服务 |
| `docker compose down` | 停止所有服务 |
| `docker compose ps` | 查看服务状态 |
| `docker compose logs -f` | 查看实时日志 |
| `./monitor.sh` | 查看完整状态报告 |

## 🔧 添加新应用

1. **在 nginx-proxy 中添加端口映射**
   ```yaml
   nginx-proxy:
     ports:
       - "80:80"
       - "443:443"
       - "8060:8060"  # 添加新端口
   ```

2. **添加新服务**
   ```yaml
   your-app:
     image: your-app-image
     container_name: your-app
     restart: always
     expose:
       - "8060"
     environment:
       - VIRTUAL_HOST=${VIRTUAL_HOST}
       - VIRTUAL_PORT=8060
       - LETSENCRYPT_HOST=${LETSENCRYPT_HOST}
       - LETSENCRYPT_EMAIL=${LETSENCRYPT_EMAIL}
   ```

3. **重启服务**
   ```bash
   docker compose up -d
   ```

4. **访问方式**
   - `https://your-domain.com:8060/`

5. **确保端口开放**
   - 服务器防火墙开放 8060 端口
   - 云服务商安全组开放 8060 端口

## 🔍 故障排查

### 证书问题
- 检查域名解析：`nslookup your-domain.com`
- 查看证书日志：`docker compose logs letsencrypt`
- 检查证书文件：`ls -la certs/your-domain.com/`

### 网络问题
- 检查端口开放：`netstat -tlnp | grep :80`
- 检查防火墙：`sudo ufw status`
- 测试本地访问：`curl -I http://localhost`
- 多端口方案：确保额外端口已开放（如 8060）

### 服务问题
- 查看服务状态：`docker compose ps`
- 查看服务日志：`docker compose logs nginx-proxy`
- 重启服务：`docker compose restart`

## 📞 支持

- 查看完整文档：`README.md`
- 报告问题：创建 Issue
- 贡献代码：参考 `CONTRIBUTING.md` 