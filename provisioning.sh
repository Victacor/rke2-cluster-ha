#!/bin/bash
set -eEo pipefail

if [ "${DEBUG}" = 1 ]; then
    set -x
fi

#colors
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[0;33m"
ENDCOLOR="\e[0m"

info(){ 
    echo -e "${GREEN}[INFO]${ENDCOLOR} $*"
}

warn(){
    echo -e "${YELLOW}[WARN]${ENDCOLOR} $*"
}

error(){ 
    local line="$1"
    local command="$2"
    local code="$3"

    if [[ "${FUNCNAME[1]}" == "cleanup" ]]; then
        return
    fi

    echo -e "${RED}[ERROR]${ENDCOLOR} Line: $line Failed command: $command Exit code: $code"
}

ensure_exists(){
    local patron="$1"
    local file="$2"
    local patron_if_not_exists="$3"

    if ! grep -q "$patron" "$file"; then
        echo "$patron_if_not_exists" >> "$file"
        info "setted $patron in $file"
    else
        warn "The patron $patron already exists in $file, skipping..."
    fi
}

ensure_systemd_exists(){
    local service="$1"
    systemctl daemon-reload >/dev/null 2>&1

    if systemctl list-unit-files --type=service | grep -q "$service"; then 
        info "Systemd service $service found"
        return 0
    else
        info "No se encuentra el servicio"
        return 1
    fi
}

generate_tls_san() {
    if [[ -z "$HOSTS_ENTRIES" ]]; then
        warn "No hosts entries found, skipping TLS SAN generation"
        return
    fi

    while read -r line; do
        hostname=$(echo "$line" | awk '{print $2}')
        echo "  - $hostname"
    done <<< "$HOSTS_ENTRIES"
}

cleanup(){   
    set +e

    dnf clean all > /dev/null 2>&1   
    subscription-manager unregister > /dev/null 2>&1
    subscription-manager clean > /dev/null 2>&1

    info "Host metadates cleaned"
}

install_rke2(){
    role="${ROLE:=server}"
    root_home="/root/.bashrc"

    declare -A rke2_dirs
    
    rke2_dirs[rke2_path]="/root/cluster"
    rke2_dirs[rke2_binaries]="${rke2_dirs[rke2_path]}/bin"
    rke2_dirs[rke2_cfg]="/etc/rancher/rke2/"

    #Generating paths
    for dir in "${rke2_dirs[@]}"; do
        if [[ ! -d $dir ]]; then
            mkdir -p "$dir" > /dev/null 2>&1
        fi
    done
    
    #Generating config based on node role
    if [[ "$role" == "agent" ]]; then
        cat << EOF > "${rke2_dirs[rke2_cfg]}/config.yaml"
server: https://Node1:9345 
token: dG9rZW5fZGVfcHJ1ZWJhX3BhcmFfbGFib3JhdG9yaW9fcmtlMl9naXRodWJfdmljdGFjb3IK
node-ip: $(hostname -I | awk '{print $3}')
EOF
        info "Generated RKE2 config for Worker Node"

        #Installing rke2 worker
        if ! ensure_systemd_exists "rke2-agent.service"; then
            curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE="agent" INSTALL_RKE2_TAR_PREFIX="${rke2_dirs[rke2_path]}" sh - > /dev/null 2>&1
            info "RKE2 installed correctly as Worker Node"
        fi
    else
        cat << EOF > "${rke2_dirs[rke2_cfg]}/config.yaml"
data-dir: /root/cluster
tls-san:
$(generate_tls_san)
cluster-cidr: 10.42.0.0/16
node-ip: $(hostname -I | awk '{print $3}')
advertise-address: $(hostname -I | awk '{print $3}')
service-cidr: 10.43.0.0/16
cni: calico
token: dG9rZW5fZGVfcHJ1ZWJhX3BhcmFfbGFib3JhdG9yaW9fcmtlMl9naXRodWJfdmljdGFjb3IK
EOF
        if [[ "$HOSTNAME" != "Node1" ]]; then
            echo 'server: https://Node1:9345' >> "${rke2_dirs[rke2_cfg]}/config.yaml"
        fi
        info "Generated RKE2 config for Server Node"
  
        #Installing rke2
        if ! ensure_systemd_exists "rke2-server.service"; then
            curl -sfL https://get.rke2.io | INSTALL_RKE2_TAR_PREFIX="${rke2_dirs[rke2_path]}" sh - > /dev/null 2>&1
            info "RKE2 installed correctly as Server Node"
        fi
        
        ensure_exists "KUBECONFIG" "$root_home" 'export KUBECONFIG=/etc/rancher/rke2/rke2.yaml'
        ensure_exists "/root/cluster/bin/" "$root_home" 'export PATH=$PATH:/root/cluster/bin/'
    fi
}

preparing_host(){
    path_selinux="/etc/selinux/config"
    systemd_firewall="firewalld"
    
    #Registering host on redhat
    subscription-manager register --username="$rh_user" --password="$rh_passwd" --auto-attach --force  > /dev/null 2>&1
    info "Host attached to redhat subscription"

    #Generating dynamic /etc/hosts entries
    info "Configuring dinamic /etc/hosts entries"
    while read -r line; do
        if ! grep -qE "[[:space:]]${line##* }$" /etc/hosts; then
            echo "$line" >> /etc/hosts
        fi
    done <<< "$HOSTS_ENTRIES"

    #disabling firewalld
    systemctl disable --now "$systemd_firewall" > /dev/null 2>&1
    
    #replacing enforcing with permissive
    setenforce 0 > /dev/null 2>&1
    sed -i 's/SELINUX=enforcing/SELINUX=permissive/' $path_selinux > /dev/null 2>&1 

    info "Selinux setted on permisive mode and disabled firewalld"
}

#traps
trap 'error "$LINENO" "$BASH_COMMAND" "$?"' ERR
trap 'cleanup' EXIT

main(){
    preparing_host
    install_rke2
}

main "$@"