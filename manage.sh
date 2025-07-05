#!/bin/bash

# Nginx Proxy HTTPS 统一管理脚本
# 使用方法: ./manage.sh [命令] [参数]

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 打印函数
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 显示帮助
show_help() {
    echo "Nginx Proxy HTTPS 统一管理脚本"
    echo ""
    echo "使用方法: ./manage.sh [命令]"
    echo ""
    echo "命令:"
    echo "  start              - 启动所有服务"
    echo "  stop               - 停止所有服务"
    echo "  restart            - 重启所有服务"
    echo "  status             - 查看服务状态"
    echo "  logs [service]     - 查看服务日志"
    echo "  monitor            - 完整监控报告"
    echo "  dns-check          - DNS配置检查"
    echo "  add-service        - 添加新服务"
    echo "  setup              - 初始配置"
    echo "  backup             - 备份配置"
    echo "  help               - 显示帮助"
    echo ""
    echo "示例:"
    echo "  ./manage.sh start"
    echo "  ./manage.sh logs nginx-proxy"
    echo "  ./manage.sh monitor"
}

# 检查依赖
check_deps() {
    if ! docker info >/dev/null 2>&1; then
        error "Docker未运行"
        exit 1
    fi
    if [ ! -f "docker-compose.yml" ]; then
        error "docker-compose.yml 不存在"
        exit 1
    fi
}

# 启动服务
start() {
    info "启动服务..."
    docker compose up -d
    success "服务已启动"
    status
}

# 停止服务
stop() {
    info "停止服务..."
    docker compose down
    success "服务已停止"
}

# 重启服务
restart() {
    info "重启服务..."
    docker compose restart
    success "服务已重启"
    status
}

# 查看状态
status() {
    info "服务状态:"
    docker compose ps
    echo ""
    
    # 显示域名信息
    info "域名访问:"
    grep -A 5 'environment:' docker-compose.yml | grep 'VIRTUAL_HOST' | awk -F '=' '{print $2}' | sed 's/\"//g' | while read domain; do
        if [ -n "$domain" ]; then
            echo "  https://$domain"
        fi
    done
    echo ""
}

# 查看日志
logs() {
    local service=$1
    if [ -z "$service" ]; then
        info "查看所有服务日志..."
        docker compose logs -f
    else
        info "查看 $service 日志..."
        docker compose logs -f "$service"
    fi
}

# 监控报告
monitor() {
    echo "🔍 监控报告"
    echo "============"
    echo ""
    
    # 服务状态
    info "服务状态:"
    docker compose ps
    echo ""
    
    # 证书状态
    info "证书状态:"
    if [ -d "certs" ]; then
        for cert_dir in certs/*/; do
            if [ -d "$cert_dir" ]; then
                domain=$(basename "$cert_dir")
                cert_file="$cert_dir/cert.pem"
                if [ -f "$cert_file" ]; then
                    expiry=$(openssl x509 -in "$cert_file" -text -noout | grep -A 2 "Validity" | tail -1 | sed 's/.*Not After : //')
                    echo "  $domain: ✅ 正常 (到期: $expiry)"
                else
                    echo "  $domain: ❌ 证书不存在"
                fi
            fi
        done
    else
        echo "  ❌ 证书目录不存在"
    fi
    echo ""
    
    # 网络测试
    info "网络测试:"
    grep -A 5 'environment:' docker-compose.yml | grep 'VIRTUAL_HOST' | awk -F '=' '{print $2}' | sed 's/\"//g' | while read domain; do
        if [ -n "$domain" ]; then
            if curl -s -I "https://$domain" > /dev/null 2>&1; then
                echo "  $domain: ✅ HTTPS正常"
            else
                echo "  $domain: ❌ HTTPS失败"
            fi
        fi
    done
    echo ""
    
    # 资源使用
    info "资源使用:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
    echo ""
}

# DNS检查
dns_check() {
    info "DNS配置检查..."
    
    # 获取服务器IP
    server_ip=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || echo "unknown")
    info "服务器IP: $server_ip"
    echo ""
    
    # 检查域名
    grep -A 5 'environment:' docker-compose.yml | grep 'VIRTUAL_HOST' | awk -F '=' '{print $2}' | sed 's/\"//g' | while read domain; do
        if [ -n "$domain" ]; then
            info "检查域名: $domain"
            
            # 解析检查
            resolved_ip=$(nslookup "$domain" 2>/dev/null | grep -A1 "Name:" | tail -1 | awk '{print $2}')
            if [ -n "$resolved_ip" ]; then
                if [ "$resolved_ip" = "$server_ip" ]; then
                    echo "  ✅ 解析正确: $resolved_ip"
                else
                    echo "  ⚠️  解析到: $resolved_ip (期望: $server_ip)"
                fi
            else
                echo "  ❌ 解析失败"
            fi
            
            # HTTPS检查
            if curl -s -I "https://$domain" > /dev/null 2>&1; then
                echo "  ✅ HTTPS正常"
            else
                echo "  ❌ HTTPS失败"
            fi
            echo ""
        fi
    done
}

# 添加服务
add_service() {
    info "添加新服务..."
    echo ""
    read -p "服务名称: " service_name
    read -p "容器名称: " container_name
    read -p "镜像名称: " image_name
    read -p "端口号: " port
    read -p "域名: " domain
    
    cat >> docker-compose.yml << EOF

  # $service_name
  $service_name:
    container_name: $container_name
    restart: always
    image: $image_name
    expose:
      - "$port"
    environment:
      - VIRTUAL_HOST=$domain
      - VIRTUAL_PORT=$port
      - LETSENCRYPT_HOST=$domain
      - LETSENCRYPT_EMAIL=\${LETSENCRYPT_EMAIL}
EOF
    
    success "服务已添加"
    info "运行 './manage.sh start' 启动新服务"
}

# 初始配置
setup() {
    info "初始配置..."
    
    # 检查.env
    if [ ! -f .env ]; then
        if [ -f setup-env.sh ]; then
            ./setup-env.sh
        else
            error ".env 文件不存在，请手动创建"
            exit 1
        fi
    fi
    
    # 检查docker-compose.yml
    if [ ! -f docker-compose.yml ]; then
        if [ -f docker-compose.example.yml ]; then
            cp docker-compose.example.yml docker-compose.yml
            info "已复制 docker-compose.example.yml"
        else
            error "docker-compose.yml 不存在"
            exit 1
        fi
    fi
    
    success "配置完成"
    info "运行 './manage.sh start' 启动服务"
}

# 备份配置
backup() {
    local backup_dir="backup/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    cp docker-compose.yml "$backup_dir/" 2>/dev/null || true
    cp .env "$backup_dir/" 2>/dev/null || true
    cp -r certs "$backup_dir/" 2>/dev/null || true
    
    success "配置已备份到 $backup_dir"
}

# 主函数
main() {
    case "$1" in
        start)
            check_deps
            start
            ;;
        stop)
            check_deps
            stop
            ;;
        restart)
            check_deps
            restart
            ;;
        status)
            check_deps
            status
            ;;
        logs)
            check_deps
            logs "$2"
            ;;
        monitor)
            check_deps
            monitor
            ;;
        dns-check)
            dns_check
            ;;
        add-service)
            add_service
            ;;
        setup)
            setup
            ;;
        backup)
            backup
            ;;
        help|--help|-h|"")
            show_help
            ;;
        *)
            error "未知命令: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

main "$@" 