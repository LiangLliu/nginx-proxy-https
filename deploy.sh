#!/bin/bash

# 简化部署脚本
# 使用方法: ./deploy.sh

set -e

echo "🚀 Nginx Proxy HTTPS 部署"
echo "========================"

# 检查 .env 文件是否存在
if [ ! -f .env ]; then
    echo "❌ 未找到 .env 文件"
    echo "请先运行 ./setup-env.sh 进行配置"
    exit 1
fi

# 检查 docker-compose.yml 是否存在
if [ ! -f docker-compose.yml ]; then
    echo "❌ 未找到 docker-compose.yml 文件"
    exit 1
fi

echo "📋 当前配置："
echo "  邮箱: $(grep '^DEFAULT_EMAIL=' .env | cut -d'=' -f2)"
echo "  域名: $(grep '^VIRTUAL_HOST=' .env | cut -d'=' -f2)"

echo ""
read -p "是否继续部署？(y/n): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "❌ 部署已取消"
    exit 1
fi

echo ""
echo "🔧 停止现有服务..."
docker compose down

echo "🔧 启动服务..."
docker compose up -d

echo ""
echo "✅ 部署完成！"
echo ""
echo "📊 服务状态："
docker compose ps

echo ""
echo "🔍 查看日志："
echo "  docker compose logs -f"
echo ""
echo "🌐 访问地址："
echo "  https://$(grep '^VIRTUAL_HOST=' .env | cut -d'=' -f2)" 