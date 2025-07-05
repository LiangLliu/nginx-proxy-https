#!/bin/bash

# HTTPS 测试脚本 - 多域名版本
# 自动从 docker-compose.yml 提取 VIRTUAL_HOST 并测试 HTTPS 功能
# 支持智能健康检查策略：优先 /actuator/health，fallback 到 /

set -e

source "$(dirname "$0")/common.sh"

echo "🔍 开始多域名 HTTPS 功能测试..."

# 函数：智能健康检查（优先 /actuator/health，fallback 到 /）
check_service_health() {
    local domain=$1
    local timeout=${2:-120}
    local interval=${3:-5}
    
    echo "   🔍 检查域名 $domain 的健康状态..."
    echo "   - 每${interval}秒检查一次，最多等待${timeout}秒"
    
    local elapsed=0
    
    while [ $elapsed -lt $timeout ]; do
        echo "   - 检查健康状态... (已等待 ${elapsed}s)"
        
        # 优先检查 /actuator/health 端点
        local health_response=$(curl -k -s -m 10 "https://$domain/ledger/actuator/health" 2>/dev/null)
        if [ $? -eq 0 ] && echo "$health_response" | grep -q '"status":"UP"'; then
            echo "   ✅ 域名 $domain 健康状态正常 (/actuator/health)"
            return 0
        fi
        
        # 如果 /actuator/health 不可用，fallback 到根路径 /
        local root_response=$(curl -k -s -m 10 -I "https://$domain/" 2>/dev/null)
        if [ $? -eq 0 ] && echo "$root_response" | grep -q -E '200|302|401|403'; then
            echo "   ✅ 域名 $domain 服务可达 (/)"
            return 0
        fi
        
        # 如果还没到超时时间，继续等待
        if [ $elapsed -lt $timeout ]; then
            sleep $interval
            elapsed=$((elapsed + interval))
        fi
    done
    
    echo "   ❌ 域名 $domain 在${timeout}秒内未达到健康状态"
    return 1
}

# 函数：测试单个域名的 HTTPS 功能
test_domain_https() {
    local domain=$1
    local failed=false
    
    echo "   🌐 测试域名: $domain"
    
    # 测试基础 HTTPS 访问
    echo "   - 测试基础 HTTPS 访问..."
    if curl -k -s -m 10 -I "https://$domain" > /dev/null 2>&1; then
        echo "   ✅ 基础 HTTPS 访问正常"
    else
        echo "   ❌ 基础 HTTPS 访问失败"
        failed=true
    fi
    
    # 测试健康检查端点
    echo "   - 测试健康检查端点..."
    local health_response=$(curl -k -s -m 10 "https://$domain/ledger/actuator/health" 2>/dev/null)
    if [ $? -eq 0 ] && echo "$health_response" | grep -q '"status":"UP"'; then
        echo "   ✅ 健康检查端点正常"
    else
        echo "   ⚠️  健康检查端点不可用（可能不是 Spring Boot 服务）"
    fi
    
    # 检查证书软链接
    echo "   - 检查证书软链接..."
    if [ -L "certs/$domain.crt" ] && [ -f "certs/$domain.crt" ]; then
        echo "   ✅ 证书软链接正常"
    else
        echo "   ❌ 证书软链接异常"
        failed=true
    fi
    
    if [ -L "certs/$domain.key" ] && [ -f "certs/$domain.key" ]; then
        echo "   ✅ 私钥软链接正常"
    else
        echo "   ❌ 私钥软链接异常"
        failed=true
    fi
    
    if [ "$failed" = true ]; then
        return 1
    else
        return 0
    fi
}

# 检查服务状态
echo "2. 检查服务状态..."
if ! docker ps | grep -q nginx-proxy; then
    echo "❌ nginx-proxy 服务未运行"
    exit 1
fi

echo "✅ nginx-proxy 服务运行正常"

# 提取所有域名
domains=$(extract_domains)
echo "1. 检测配置的域名: $domains"

# 并行检查所有服务的健康状态
echo "3. 并行检查所有服务的健康状态..."
failed_health_checks=""
success_health_checks=""

for domain in $domains; do
    # 并行检查健康状态（后台运行）
    check_service_health "$domain" 120 5 &
    health_pid=$!
    
    # 等待健康检查完成
    wait $health_pid
    if [ $? -eq 0 ]; then
        success_health_checks="$success_health_checks $domain"
    else
        failed_health_checks="$failed_health_checks $domain"
    fi
done

# 检查健康检查结果
if [ -n "$failed_health_checks" ]; then
    echo "⚠️  部分服务健康检查失败: $failed_health_checks"
    echo "💡 请检查服务日志: docker logs <service_name>"
fi

if [ -z "$success_health_checks" ]; then
    echo "❌ 所有服务健康检查失败"
    exit 1
fi

echo "✅ 健康检查完成，成功: $success_health_checks"

# 测试 HTTPS 功能
echo "4. 测试 HTTPS 功能..."
failed_https_tests=""
success_https_tests=""

for domain in $domains; do
    if test_domain_https "$domain"; then
        success_https_tests="$success_https_tests $domain"
    else
        failed_https_tests="$failed_https_tests $domain"
    fi
done

# 检查证书配置
echo "5. 检查证书配置..."
if docker exec nginx-proxy nginx -t > /dev/null 2>&1; then
    echo "✅ nginx 配置正确"
else
    echo "❌ nginx 配置错误"
    failed_https_tests="$failed_https_tests (nginx配置错误)"
fi

# 输出测试结果
echo ""
echo "📊 测试结果汇总:"
echo "=================="

if [ -n "$failed_health_checks" ]; then
    echo "⚠️  健康检查失败: $failed_health_checks"
fi

if [ -n "$failed_https_tests" ]; then
    echo "❌ HTTPS 测试失败: $failed_https_tests"
    echo "💡 建议运行 ./fix-https.sh 进行修复"
    exit 1
else
    echo "✅ 所有 HTTPS 功能测试通过"
    echo "🎉 所有域名 HTTPS 功能正常"
fi

echo ""
echo "📋 访问地址:"
for domain in $domains; do
    echo "   - https://$domain"
    echo "     健康检查: https://$domain/ledger/actuator/health"
done 