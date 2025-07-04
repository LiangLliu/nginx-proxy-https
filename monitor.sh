#!/bin/bash

# Nginx Proxy HTTPS 监控脚本
# 使用方法: ./monitor.sh

echo "🔍 Nginx Proxy HTTPS 监控报告"
echo "================================"
echo ""

# 检查服务状态
echo "📊 服务状态:"
docker compose ps
echo ""

# 检查证书状态
echo "🔐 证书状态:"
if [ -d "certs" ]; then
    for cert_dir in certs/*/; do
        if [ -d "$cert_dir" ]; then
            domain=$(basename "$cert_dir")
            cert_file="$cert_dir/cert.pem"
            if [ -f "$cert_file" ]; then
                echo "域名: $domain"
                echo "  有效期: $(openssl x509 -in "$cert_file" -text -noout | grep -A 2 "Validity" | tail -1 | sed 's/.*Not After : //')"
                echo "  状态: ✅ 正常"
            else
                echo "域名: $domain"
                echo "  状态: ❌ 证书文件不存在"
            fi
            echo ""
        fi
    done
else
    echo "❌ 证书目录不存在"
fi

# 检查最近日志
echo "📋 最近日志 (最后10行):"
docker compose logs --tail=10 letsencrypt
echo ""

# 检查网络连接
echo "🌐 网络连接测试:"
if command -v curl &> /dev/null; then
    for cert_dir in certs/*/; do
        if [ -d "$cert_dir" ]; then
            domain=$(basename "$cert_dir")
            echo "测试 $domain..."
            if curl -s -I "https://$domain" > /dev/null 2>&1; then
                echo "  ✅ HTTPS 正常"
            else
                echo "  ❌ HTTPS 失败"
            fi
        fi
    done
else
    echo "⚠️  curl 未安装，跳过网络测试"
fi
echo ""

# 检查磁盘空间
echo "💾 磁盘使用情况:"
df -h . | tail -1
echo ""

# 检查 Docker 资源使用
echo "🐳 Docker 资源使用:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
echo ""

echo "✅ 监控完成！"
echo ""
echo "💡 提示:"
echo "- 定期运行此脚本监控服务状态"
echo "- 设置定时任务: crontab -e"
echo "- 添加告警通知到监控脚本" 