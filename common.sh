# common.sh
# 通用 shell 函数库

extract_domains() {
    # 只输出域名列表，不 echo 其他内容
    grep -E "VIRTUAL_HOST=" docker-compose.yml | sed 's/.*VIRTUAL_HOST=//' | tr -d '[:space:]' | grep -v '^$' | sort -u
} 