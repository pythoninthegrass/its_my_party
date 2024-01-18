#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC2002

# $PWD
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

# $USER
[[ -n $(logname >/dev/null 2>&1) ]] && logged_in_user=$(logname) || logged_in_user=$(whoami)

# $HOME
logged_in_home=$(eval echo "~${logged_in_user}")

# set permissions
[[ $(command -v microk8s >/dev/null 2>&1; echo $?) -ne 0 ]] && sudo snap install microk8s --classic
sudo usermod -a -G microk8s "$logged_in_user"
[[ ! -d "${logged_in_home}/.kube" ]] && mkdir -p "${logged_in_home}/.kube"

# check if script has run once
relaunch() {
	if [[ ! -f /tmp/install_microk8s.pid ]]; then
		# get pid of shell script session
		shell_pid=$($$)

		# export to temporary file in /tmp
		echo "$shell_pid" > /tmp/install_microk8s.pid

		echo "Refreshing shell to load microk8s. Please re-run the script to complete the installation:"
		echo -e "./$0"

		# relaunch shell
		newgrp microk8s
	else
		# delete existing pid file
		rm /tmp/install_microk8s.pid
	fi
}

# allow pod-to-pod and pod-to-internet communication
whitelist() {
	distro=$(grep -E "^ID=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
	if [[ "$distro" = "debian" || "$distro" = "ubuntu" ]]; then
		sudo ufw allow in on cni0 && sudo ufw allow out on cni0
		sudo ufw default allow routed
	elif [[ "$distro" == "fedora" ]]; then
		SUBNET=$(cat /var/snap/microk8s/current/args/cni-network/cni.yaml | grep CALICO_IPV4POOL_CIDR -a1 | tail -n1 | grep -oP '[\d\./]+')
		sudo firewall-cmd --reload
		sudo firewall-cmd --permanent --new-zone=microk8s-cluster
		sudo firewall-cmd --permanent --zone=microk8s-cluster --set-target=ACCEPT
		sudo firewall-cmd --permanent --zone=microk8s-cluster --add-source=$SUBNET
		sudo firewall-cmd --reload
	fi
}

# enable addons
enable_addons() {
	# fill out metallb ip range via expect
	IP_RANGE="192.168.64.100-192.168.64.200"
	if [[ $(command -v expect >/dev/null 2>&1; echo $?) -ne 0 ]]; then
		sudo apt update && sudo apt install -y expect
	fi

    /usr/bin/expect <<-EOF
	spawn microk8s enable metallb
	expect "Enter each IP address range delimited by comma (e.g. '10.64.140.43-10.64.140.49,192.168.0.105-192.168.0.111'):"
	send "$IP_RANGE\r"
	expect eof
	EOF

	# microk8s enable cis-hardening     # Apply CIS K8s hardening
	# microk8s enable community         # The community addons repository
	# microk8s enable host-access       # Allow Pods connecting to Host services smoothly

	addons=(
		"dashboard"
		"dns"
		"ingress"
		"cert-manager"
		"storage"
		"registry --size=20Gi"
		"minio"
		"gpu"
		"observability"
	)

	for addon in "${addons[@]}"; do
		microk8s enable "$addon"
	done

	# check status
	microk8s status
}

# export kubeconfig
export_config() {
	if [[ -f "${logged_in_home}/.kube/config" ]]; then
		cp "${logged_in_home}/.kube/config" "${logged_in_home}/.kube/config_$(date +%Y%m%d_%H%M%S)"
	fi
	microk8s.kubectl config view --raw > "${logged_in_home}/.kube/config"
	[[ -f ""${logged_in_home}/.kube"" ]] && sudo chown -R "$logged_in_user" "${logged_in_home}/.kube"
}

# get microk8s address
server_info() {
	srv_addr=$(grep -E "server: https://.*:16443" "${logged_in_home}/.kube/config" | awk '{print $2}')
	echo -e "[localhost]\t${srv_addr}"
	echo -e "[LAN]\t\thttps://$(hostname -I | awk '{print $1}'):16443"
}


# install k9s
install_k9s() {
	if [[ $(command -v k9s >/dev/null 2>&1; echo $?) -ne 0 ]]; then
		USER_NAME="derailed"
		REPO_NAME="k9s"
		if [[ $(arch) = "aarch64" ]]; then
			PKG_NAME="k9s_linux_arm64.deb"
		elif [[ $(arch) = "x86_64" ]]; then
			PKG_NAME="k9s_linux_amd64.deb"
		fi
		VERSION=$(curl -s "https://api.github.com/repos/${USER_NAME}/${REPO_NAME}/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
		(
			cd /tmp
			curl -Lo "$PKG_NAME" "https://github.com/${USER_NAME}/${REPO_NAME}/releases/download/v${VERSION}/${PKG_NAME}"
			sudo dpkg -i "$PKG_NAME"
		)
	else
		echo "Uncaught error. Please try installing go then k9s manually."
		echo "https://golang.org/doc/install"
		echo "https://github.com/derailed/k9s#installation"
		exit 1
	fi
}

main() {
	relaunch
	whitelist
	enable_addons
	export_config
	server_info
	install_k9s
}
main

exit 0
