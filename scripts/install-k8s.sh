#!/bin/bash
set -euo pipefail

# Параметры (передаются из Jenkins)
SERVER_IP="$1"
SSH_USER="$2"
SSH_PASSWORD="$3"

# Установка sshpass (если не установлен)
if ! command -v sshpass &> /dev/null; then
    echo "Installing sshpass..."
    sudo apt-get update && sudo apt-get install -y sshpass
fi

# Функция для выполнения команд на удаленном сервере
run_remote() {
    sshpass -p "$SSH_PASSWORD" ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR "${SSH_USER}@${SERVER_IP}" "$@"
}

# Основные этапы установки
echo "Starting Kubernetes installation on ${SERVER_IP}..."
run_remote '
# Шаг 1: Обновление системы и отключение swap
sudo apt-get update -qq && sudo apt-get upgrade -y -qq
sudo swapoff -a
sudo sed -i "/ swap / s/^\(.*\)$/#\1/g" /etc/fstab

# Шаг 2: Настройка ядра
sudo modprobe overlay
sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system -q

# Шаг 3: Установка containerd
sudo apt-get install -y -qq containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
sudo sed -i "s/SystemdCgroup = false/SystemdCgroup = true/g" /etc/containerd/config.toml
sudo systemctl restart containerd

# Шаг 4: Установка kubeadm, kubelet, kubectl
sudo apt-get install -y -qq apt-transport-https curl
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update -qq
sudo apt-get install -y -qq kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Шаг 5: Инициализация кластера
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=NumCPU

# Шаг 6: Настройка kubectl для пользователя
mkdir -p \$HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config
sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config

# Шаг 7: Установка Calico
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.4/manifests/calico.yaml
'

echo "Kubernetes installed successfully on ${SERVER_IP}!"