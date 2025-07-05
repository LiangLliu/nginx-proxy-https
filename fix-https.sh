#!/bin/bash

# HTTPS 修复脚本 - 多域名版本
# 自动从 docker-compose.yml 提取 VIRTUAL_HOST 并修复证书软链接问题
# 使用 sudo 处理权限，提高效率

set -e

source "$(dirname "$0")/common.sh"

echo "🔧 开始多域名 HTTPS 修复流程..."

# 函数：修复单个域名的证书
fix_domain_cert() {
    local domain=$1
    echo "   🔧 修复域名: $domain"
    
    # 检查证书文件是否存在
    if [ ! -f "certs/$domain/cert.pem" ]; then
        echo "   ❌ 证书文件不存在: certs/$domain/cert.pem"
        return 1
    fi
    
    if [ ! -f "certs/$domain/key.pem" ]; then
        echo "   ❌ 私钥文件不存在: certs/$domain/key.pem"
        return 1
    fi
    
    # 删除可能存在的错误软链接（使用 sudo）
    sudo rm -f "certs/$domain.crt"
    sudo rm -f "certs/$domain.key"
    
    # 创建正确的证书链接（使用 sudo）
    sudo ln -sf "$domain/cert.pem" "certs/$domain.crt"
    sudo ln -sf "$domain/key.pem" "certs/$domain.key"
    
    # 修改软链接权限，让 devops 用户可以访问
    sudo chown devops:devops "certs/$domain.crt"
    sudo chown devops:devops "certs/$domain.key"
    
    # 验证软链接是否正确
    if [ ! -L "certs/$domain.crt" ] || [ ! -f "certs/$domain.crt" ]; then
        echo "   ❌ 证书软链接创建失败"
        return 1
    fi
    
    if [ ! -L "certs/$domain.key" ] || [ ! -f "certs/$domain.key" ]; then
        echo "   ❌ 私钥软链接创建失败"
        return 1
    fi
    
    echo "   ✅ 域名 $domain 证书修复成功"
    return 0
}

# 检查 nginx-proxy 容器是否运行
echo "2. 检查服务状态..."
if ! docker ps | grep -q nginx-proxy; then
    echo "❌ nginx-proxy 容器未运行"
    exit 1
fi

echo "✅ nginx-proxy 容器运行正常"

# 提取所有域名
domains=$(extract_domains)
echo "1. 检测配置的域名: $domains"

# 修复所有域名的证书
echo "3. 修复所有域名的证书..."
failed_domains=""
success_count=0

for domain in $domains; do
    if fix_domain_cert "$domain"; then
        success_count=$((success_count + 1))
    else
        failed_domains="$failed_domains $domain"
    fi
done

# 检查修复结果
if [ -n "$failed_domains" ]; then
    echo "⚠️  部分域名修复失败: $failed_domains"
    echo "💡 请检查证书文件是否存在"
fi

if [ $success_count -eq 0 ]; then
    echo "❌ 所有域名修复失败"
    exit 1
fi

echo "✅ 成功修复 $success_count 个域名的证书"

# 重新加载 nginx-proxy
echo "4. 重新加载 nginx-proxy..."
docker exec nginx-proxy nginx -s reload

# 等待配置生效
echo "5. 等待配置生效..."
sleep 5

# 验证 nginx 配置是否正确
echo "6. 检查 nginx 配置..."
if docker exec nginx-proxy nginx -t > /dev/null 2>&1; then
    echo "✅ nginx 配置正确"
else
    echo "❌ nginx 配置错误"
    docker exec nginx-proxy nginx -t
    exit 1
fi

# 重启 nginx-proxy 以确保配置生效
echo "7. 重启 nginx-proxy 以确保配置生效..."
docker restart nginx-proxy

# 等待 nginx-proxy 启动
echo "8. 等待 nginx-proxy 启动..."
sleep 10

echo ""
echo "🎉 多域名 HTTPS 修复完成！"
echo "📝 已修复 $success_count 个域名的证书软链接"
if [ -n "$failed_domains" ]; then
    echo "⚠️  失败的域名: $failed_domains"
fi
echo "💡 请运行 ./test-https.sh 进行验证" 