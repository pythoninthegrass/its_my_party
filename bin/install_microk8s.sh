#!/usr/bin/env bash

# $USER
[[ -n $(logname >/dev/null 2>&1) ]] && logged_in_user=$(logname) || logged_in_user=$(whoami)

# $HOME
logged_in_home=$(eval echo "~${logged_in_user}")

# set permissions
sudo snap install microk8s --classic
sudo usermod -a -G microk8s "$logged_in_user"
sudo chown -R "$logged_in_user" "${logged_in_home}/.kube"
newgrp microk8s

# allow pod-to-pod and pod-to-internet communication
distro=$(grep -E "^ID=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
if [[ "$distro" = "debian" || "$distro" = "ubuntu" ]]; then
    sudo ufw allow in on cni0 && sudo ufw allow out on cni0
    sudo ufw default allow routed
elif [[ "$distro" == "fedora" ]]; then
    sudo firewall-cmd --permanent --zone=trusted --change-interface=cni0
    sudo firewall-cmd --permanent --zone=trusted --add-masquerade
fi

# enable addons
microk8s enable dashboard
microk8s enable dns
microk8s enable ingress
microk8s enable metallb
microk8s enable cert-manager
microk8s enable storage
microk8s enable registry
microk8s enable minio
microk8s enable gpu
microk8s enable observability       # skip prometheus (deprecated)
# microk8s enable cis-hardening       # Apply CIS K8s hardening
# microk8s enable community           # The community addons repository
# microk8s enable host-access         # Allow Pods connecting to Host services smoothly

# check status
microk8s status

# export kubeconfig
if [[ -f "${logged_in_home}/.kube/config" ]]; then
	cp "${logged_in_home}/.kube/config" "${logged_in_home}/.kube/config_$(date +%Y%m%d_%H%M%S)"
fi
microk8s.kubectl config view --raw > "${logged_in_home}/.kube/config"

# get server address
srv_addr=$(grep -E "server: https://.*:16443" "${logged_in_home}/.kube/config" | awk '{print $2}')
echo -e "[localhost]\t\t${srv_addr}"
echo -e "[LAN]\t\thttps://$(hostname -I | awk '{print $1}'):16443"

# install k9s
if [[ ! -n $(command -v go 2&> /dev/null) ]]; then
	go install github.com/derailed/k9s@latest
elif [[ ! -n $(command -v snap 2&> /dev/null) ]]; then
	sudo snap install go --classic
else
	echo "Please install go or snap first."
	exit 1
fi

exit 0
