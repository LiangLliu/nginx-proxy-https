#!/bin/bash

# Nginx Proxy HTTPS 环境变量配置脚本
# 自动生成 .env 文件

set -e

echo "🚀 Nginx Proxy HTTPS 环境变量配置"
echo "=================================="

# 检查是否已存在 .env 文件
if [ -f .env ]; then
    echo "⚠️  发现已存在的 .env 文件"
    read -p "是否覆盖？(y/n): " overwrite
    if [[ ! $overwrite =~ ^[Yy]$ ]]; then
        echo "❌ 配置已取消"
        exit 1
    fi
fi

# 获取邮箱
read -p "请输入证书通知邮箱: " email
if [ -z "$email" ]; then
    echo "❌ 邮箱不能为空"
    exit 1
fi

# 获取续签配置
read -p "请输入证书续签阈值天数 (推荐: 30-60, 默认: 30): " renew_days
renew_days=${renew_days:-30}

read -p "请输入证书检查间隔秒数 (推荐: 3600, 默认: 3600): " check_interval
check_interval=${check_interval:-3600}

# 创建 .env 文件
echo "📁 创建 .env 文件..."
cat > .env << EOF
# Nginx Proxy HTTPS 环境变量配置
# 生成时间: $(date)

# 证书通知邮箱（必需）
DEFAULT_EMAIL=$email

# 证书续签配置
DEFAULT_RENEW=$renew_days
CERTS_UPDATE_INTERVAL=$check_interval
EOF

echo "✅ .env 文件创建成功！"
echo ""
echo "📋 配置摘要："
echo "  邮箱: $email"
echo "  续签阈值: ${renew_days}天"
echo "  检查间隔: ${check_interval}秒"
echo ""
echo "🚀 下一步操作："
echo "  1. 配置 docker-compose.yml 中的服务域名和端口"
echo "  2. 运行: docker compose up -d"
echo "  3. 查看日志: docker compose logs -f" 