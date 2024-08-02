#!/bin/sh

trap "rm $0" EXIT
clear
show() {
    echo "--------------------------------欢迎使用 xray 一键部署脚本 -------------------------------------"
    echo "---   xray 一键部署脚本由chatgpt编写   ---"
    echo "------------------------------------------------------------------------------------------------"
}

host='serv00.net'
devil port add tcp random &>/dev/null
cd "$HOME/domains/$USER.$host" || exit 1
mkdir -p xray/log
devil port add tcp random &>/dev/null
cd xray || exit 1
log="$HOME/domains/$USER.$host/xray/log/"
show
if [ ! -f "./xray" ]; then
    if [ ! -f "xray.zip" ]; then
        fetch -o 'xray.zip' 'https://raw.githubusercontent.com/bin862324915/serv00-app/main/xray/xray.zip'
        if [ $? -ne 0 ]; then
            echo "下载文件时出错，请检查网络或链接是否可用！"
            exit 1
        fi
    fi
    if ! unzip xray.zip; then
        echo "解压文件时出错，请检查！"
        exit 1
    fi
fi

if [ ! -f "./config.json" ]; then
    echo "自动安装失败，请手动解压操作"
    exit 1
fi

clear
echo "xray 应用已经自动安装完成"
echo "正在设置配置信息..."

uuid=$(fetch -qo - https://api.zzzwb.com/v1?get=uuid)
if [ -z "$uuid" ] || [ "$uuid" = "null" ]; then
    echo "获取 UUID 失败，请检查！"
    exit 1
fi

echo "生成随机uuid..."
echo "$uuid"
echo "正在设置端口..."
output=$(devil port list)
vport=$(echo "$output" | grep -E '^[0-9]+' | head -n 1 | cut -d" " -f1)
sport=$(echo "$output" | grep -E '^[0-9]+' | sed -n '2p' | cut -d" " -f1)
echo "vless端口号为：$vport"
echo "socks端口号为：$sport"
if ! sed -i "" "s|\"port\": 55555|\"port\": $vport|" config.json; then
    echo "设置vless端口失败！"
    exit 1
fi

if ! sed -i "" "s|\"port\": 44444|\"port\": $sport|" config.json; then
    echo "设置socks端口失败！"
    exit 1
fi

if ! sed -i "" "s|access.log|${log}access.log|" config.json; then
    echo "设置日志输出文件 access.log 失败！"
fi

if ! sed -i "" "s|error.log|${log}error.log|" config.json; then
    echo "设置错误日志文件 error.log 失败！"
fi

echo "正在设置uuid..."
if ! sed -i "" "s|f91c2710-b50c-4ccd-83cf-dd5e1b13eabf|$uuid|" config.json; then
    echo "设置 UUID 失败！"
    exit 1
fi

echo "正在启动 xray..."
chmod +x xray
rm xray.zip
nohup ./xray run > /dev/null 2>&1 &
if [ $? -ne 0 ]; then
    echo "启动 xray 失败！"
    exit 1
fi
cd
sleep 2s
rm xray-run.sh
echo "xray启动成功"
echo "正在生成节点信息..."
echo
echo "复制以下节点信息到 v2ray 粘贴即可使用"
echo "↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓"
echo
echo "vless://$uuid@$USER.$host:$vport?encryption=none&security=none&type=ws&path=/#serv00&vless"
echo
echo
echo "socks://dXNlcjphZG1pbg==@$USER.$host:$sport#serv00&socks"
show
exit