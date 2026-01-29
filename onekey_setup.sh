#!/bin/bash

#########################################
# VPS 一键配置脚本
# 功能：环境安装、VLESS-gRPC-REALITY、Shadowsocks、SSH端口、BBR优化、GOST
# 作者：xhd0926
# 项目地址：https://github.com/你的用户名/vps-onekey-setup
#########################################

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 脚本版本
VERSION="1.0.0"

#########################################
# 工具函数
#########################################

# 打印带颜色的消息
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}[STEP $1]${NC} $2"
    echo -e "${CYAN}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

# 检查命令是否成功执行
check_status() {
    if [ $? -eq 0 ]; then
        print_success "$1"
    else
        print_error "$1 失败"
        exit 1
    fi
}

# 检查是否为root用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "此脚本必须以root权限运行"
        echo "请使用: sudo $0"
        exit 1
    fi
}

# 检查系统类型
check_system() {
    if [ -f /etc/debian_version ]; then
        SYSTEM="debian"
        print_info "检测到Debian/Ubuntu系统"
    elif [ -f /etc/redhat-release ]; then
        SYSTEM="centos"
        print_error "暂不支持CentOS系统"
        exit 1
    else
        print_error "不支持的系统类型"
        exit 1
    fi
}

# 显示欢迎信息
show_welcome() {
    clear
    echo -e "${BLUE}"
    echo "=========================================="
    echo "       VPS 一键配置脚本 v${VERSION}"
    echo "=========================================="
    echo -e "${NC}"
    echo "本脚本将自动安装以下组件："
    echo ""
    echo "  1. 基础环境和依赖包"
    echo "  2. VLESS-gRPC-REALITY 节点"
    echo "  3. Shadowsocks-2022 节点"
    echo "  4. SSH端口修改为 12369"
    echo "  5. 网络性能优化 (BBR)"
    echo "  6. GOST 端口转发工具"
    echo ""
    echo -e "${YELLOW}注意事项：${NC}"
    echo "  • 脚本将自动安装Docker"
    echo "  • SSH端口将改为 12369"
    echo "  • 请确保防火墙允许相关端口"
    echo ""
    read -p "按Enter键继续，或Ctrl+C取消..."
    echo ""
}

#########################################
# 主要功能函数
#########################################

# 步骤1：安装基础环境和依赖
install_dependencies() {
    print_step "1/6" "安装基础环境和依赖包"
    
    print_info "更新软件源..."
    apt update -y
    check_status "软件源更新"
    
    print_info "安装依赖包..."
    apt install -y \
        socat \
        iperf3 \
        mtr \
        wget \
        curl \
        nano \
        sudo \
        net-tools \
        cron \
        ipset \
        unzip \
        p7zip-full \
        python3-pip \
        flex \
        bison \
        docker.io
    check_status "依赖包安装"
    
    print_info "启动Docker服务..."
    systemctl start docker
    systemctl enable docker
    check_status "Docker服务启动"
    
    print_success "步骤1完成：基础环境安装成功"
}

# 步骤2：安装VLESS-gRPC-REALITY
install_vless_reality() {
    print_step "2/6" "安装 VLESS-gRPC-REALITY 节点"
    
    print_info "下载配置文件..."
    wget -O config.zip https://raw.githubusercontent.com/xhd0926/Xray-examples/main/VLESS-gRPC-REALITY/config.zip
    check_status "配置文件下载"
    
    print_info "创建配置目录..."
    mkdir -p /etc/xrayR
    
    print_info "解压配置文件..."
    unzip -P "X.2023" -o config.zip -d /etc/xrayR
    check_status "配置文件解压"
    
    rm -f config.zip
    
    print_info "停止并删除旧容器..."
    docker rm -f xrayR 2>/dev/null || true
    
    print_info "拉取Xray镜像..."
    docker pull teddysun/xray
    check_status "Xray镜像拉取"
    
    print_info "启动VLESS-REALITY容器..."
    docker run -d \
        --name xrayR \
        --restart always \
        --net host \
        -v /etc/xrayR:/etc/xray \
        teddysun/xray
    check_status "VLESS-REALITY容器启动"
    
    print_success "步骤2完成：VLESS-gRPC-REALITY 安装成功"
}

# 步骤3：安装Shadowsocks-2022
install_shadowsocks() {
    print_step "3/6" "安装 Shadowsocks-2022 节点"
    
    print_info "下载配置文件..."
    wget -O config.zip https://raw.githubusercontent.com/xhd0926/Xray-examples/main/Shadowsocks-2022/config.zip
    check_status "配置文件下载"
    
    print_info "创建配置目录..."
    mkdir -p /etc/xrayS
    
    print_info "解压配置文件..."
    7z x -p"X.2023" -o/etc/xrayS config.zip -y
    check_status "配置文件解压"
    
    rm -f config.zip
    
    print_info "停止并删除旧容器..."
    docker rm -f xrayS 2>/dev/null || true
    
    print_info "拉取Xray镜像..."
    docker pull teddysun/xray
    
    print_info "启动Shadowsocks容器..."
    docker run -d \
        --name xrayS \
        --restart always \
        --net host \
        -v /etc/xrayS:/etc/xray \
        teddysun/xray
    check_status "Shadowsocks容器启动"
    
    print_success "步骤3完成：Shadowsocks-2022 安装成功"
}

# 步骤4：修改SSH端口
change_ssh_port() {
    print_step "4/6" "修改SSH端口为 12369"
    
    print_info "备份SSH配置..."
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%Y%m%d)
    
    print_info "修改SSH端口..."
    sed -i 's/^#*Port .*/Port 12369/' /etc/ssh/sshd_config
    check_status "SSH端口配置修改"
    
    print_info "重启SSH服务..."
    systemctl restart ssh || systemctl restart sshd
    check_status "SSH服务重启"
    
    print_success "步骤4完成：SSH端口已改为 12369"
    print_warning "⚠️  请保持当前SSH连接，新开窗口测试端口 12369"
    print_warning "⚠️  确认可连接后再关闭此窗口"
}

# 步骤5：网络性能优化
optimize_network() {
    print_step "5/6" "优化网络性能 (启用BBR)"
    
    print_info "备份原配置..."
    cp /etc/sysctl.conf /etc/sysctl.conf.bak.$(date +%Y%m%d) 2>/dev/null || true
    
    print_info "写入优化配置..."
    cat > /etc/sysctl.conf << 'EOF'
# 虚拟内存交换策略
vm.swappiness=1

# TCP性能优化
net.ipv4.tcp_no_metrics_save=1
net.ipv4.tcp_ecn=0
net.ipv4.tcp_frto=0
net.ipv4.tcp_mtu_probing=0
net.ipv4.tcp_rfc1337=0
net.ipv4.tcp_sack=1
net.ipv4.tcp_fack=1
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_adv_win_scale=1
net.ipv4.tcp_moderate_rcvbuf=1

# 网络缓冲区大小
net.core.rmem_max=33554432
net.core.wmem_max=33554432
net.ipv4.tcp_wmem=4096 16384 11750000
net.ipv4.tcp_rmem=4096 87380 11750000
net.ipv4.udp_rmem_min=8192
net.ipv4.udp_wmem_min=8192

# BBR拥塞控制算法
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr

# IPv6转发
net.ipv6.conf.all.forwarding=1
net.ipv6.conf.default.forwarding=1
EOF
    check_status "网络配置写入"
    
    print_info "应用配置..."
    sysctl -p
    sysctl --system
    check_status "网络配置应用"
    
    # 验证BBR
    if lsmod | grep -q bbr; then
        print_success "步骤5完成：BBR已成功启用"
    else
        print_warning "BBR可能未成功启用，请检查内核版本"
    fi
}

# 步骤6：安装GOST
install_gost() {
    print_step "6/6" "安装 GOST 端口转发工具"
    
    print_info "下载GOST安装脚本..."
    wget --no-check-certificate -O gost.sh https://raw.githubusercontent.com/KANIKIG/Multi-EasyGost/master/gost.sh
    check_status "GOST脚本下载"
    
    print_info "设置执行权限..."
    chmod +x gost.sh
    
    print_success "步骤6完成：GOST脚本已下载"
    print_info "GOST脚本位置: $(pwd)/gost.sh"
    print_info "需要配置GOST时，请运行: ./gost.sh"
}

# 显示安装总结
show_summary() {
    echo ""
    echo -e "${GREEN}=========================================="
    echo "          安装完成！"
    echo "==========================================${NC}"
    echo ""
    echo -e "${CYAN}已安装的组件：${NC}"
    echo ""
    echo "  ✓ 基础环境和Docker"
    echo "  ✓ VLESS-gRPC-REALITY (容器: xrayR)"
    echo "  ✓ Shadowsocks-2022 (容器: xrayS)"
    echo "  ✓ SSH端口: 12369"
    echo "  ✓ BBR 加速已启用"
    echo "  ✓ GOST 脚本已下载"
    echo ""
    echo -e "${YELLOW}重要信息：${NC}"
    echo ""
    echo "  🔹 SSH端口已改为: ${GREEN}12369${NC}"
    echo "  🔹 请保持当前连接，测试新端口后再断开"
    echo ""
    echo -e "${YELLOW}Docker容器状态：${NC}"
    echo ""
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" --filter "name=xray"
    echo ""
    echo -e "${YELLOW}配置文件位置：${NC}"
    echo ""
    echo "  • VLESS-REALITY: /etc/xrayR/"
    echo "  • Shadowsocks:   /etc/xrayS/"
    echo "  • GOST脚本:      $(pwd)/gost.sh"
    echo ""
    echo -e "${YELLOW}常用命令：${NC}"
    echo ""
    echo "  • 查看VLESS日志:  docker logs xrayR"
    echo "  • 查看SS日志:     docker logs xrayS"
    echo "  • 重启VLESS:      docker restart xrayR"
    echo "  • 重启SS:         docker restart xrayS"
    echo "  • 配置GOST:       ./gost.sh"
    echo ""
    echo -e "${GREEN}=========================================="
    echo "    感谢使用！如有问题请提交Issue"
    echo "==========================================${NC}"
    echo ""
}

# 询问是否继续下一步
ask_continue() {
    if [ "$AUTO_MODE" != "true" ]; then
        echo ""
        read -p "按Enter键继续下一步，或Ctrl+C取消..."
    fi
}

#########################################
# 主程序
#########################################

main() {
    # 检查root权限
    check_root
    
    # 检查系统类型
    check_system
    
    # 显示欢迎信息
    show_welcome
    
    # 执行安装步骤
    install_dependencies
    ask_continue
    
    install_vless_reality
    ask_continue
    
    install_shadowsocks
    ask_continue
    
    change_ssh_port
    ask_continue
    
    optimize_network
    ask_continue
    
    install_gost
    
    # 显示总结
    show_summary
}

#########################################
# 脚本入口
#########################################

# 处理命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --auto|-a)
            AUTO_MODE="true"
            shift
            ;;
        --help|-h)
            echo "用法: $0 [选项]"
            echo ""
            echo "选项:"
            echo "  -a, --auto    自动模式，无需手动确认"
            echo "  -h, --help    显示帮助信息"
            echo "  -v, --version 显示版本信息"
            echo ""
            exit 0
            ;;
        --version|-v)
            echo "VPS一键配置脚本 v${VERSION}"
            exit 0
            ;;
        *)
            print_error "未知参数: $1"
            echo "使用 --help 查看帮助"
            exit 1
            ;;
    esac
done

# 执行主程序
main
