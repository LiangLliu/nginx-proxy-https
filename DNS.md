# DNS 配置指南

## 🌐 配置方式

### 方式一：通配符记录（推荐）

在您的 DNS 管理平台添加一条 A 记录：

```
*.your-domain.com    A    YOUR_SERVER_IP
```

**优点：**
- 一条记录覆盖所有子域名
- 新增子域名无需额外配置
- 管理简单

**适用场景：**
- 使用子域名访问不同服务
- 例如：`api.your-domain.com`、`app.your-domain.com`

### 方式二：单独记录

为每个子域名添加 A 记录：

```
api.your-domain.com    A    YOUR_SERVER_IP
app.your-domain.com    A    YOUR_SERVER_IP
admin.your-domain.com  A    YOUR_SERVER_IP
```

**适用场景：**
- 域名数量较少
- 需要精确控制每个域名

## 🔍 验证配置

### 1. 命令行检查
```bash
# 检查域名解析
nslookup api.your-domain.com
nslookup app.your-domain.com

# 检查 HTTPS 访问
curl -I https://api.your-domain.com
curl -I https://app.your-domain.com
```

### 2. 使用管理脚本
```bash
# 自动检查所有配置的域名
./manage.sh dns-check
```

## ⚠️ 注意事项

1. **DNS 传播时间**：新配置可能需要几分钟到几小时生效
2. **服务器 IP**：确保使用正确的服务器公网 IP
3. **防火墙**：确保服务器开放 80 和 443 端口
4. **云服务商**：在安全组中开放相应端口

## 🛠️ 常见问题

### Q: 域名解析失败
A: 检查 DNS 记录是否正确，等待传播时间

### Q: HTTPS 访问失败
A: 检查服务器防火墙和云服务商安全组配置

### Q: 证书申请失败
A: 确保域名正确解析到服务器 IP，且 80 端口可访问 