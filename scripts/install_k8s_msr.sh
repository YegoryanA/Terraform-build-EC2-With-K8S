#!/bin/bash

######### ** FOR MASTER NODE ** #########

hostname k8s-master
echo "k8s-master" > /etc/hostname

apt update
apt install apt-transport-https ca-certificates curl software-properties-common bash-completion -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"

#Installing Docker
tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

apt update
apt-cache policy docker-ce
apt install docker-ce -y
apt install awscli -y   

mkdir -p /etc/apt/keyrings/
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

#Turn off swap
swapoff -a
sudo sed -i '/swap/d' /etc/fstab
mount -a
ufw disable

#Installing Kubernetes tools
apt update
# apt install kubelet kubeadm kubectl -y
apt install -y kubeadm=1.28.1-1.1 kubelet=1.28.1-1.1 kubectl=1.28.1-1.1

#next line is getting EC2 instance IP, for kubeadm to initiate cluster
#we need to get EC2 internal IP address- default ENI is eth0
export ipaddr=`ip address|grep eth0|grep inet|awk -F ' ' '{print $2}' |awk -F '/' '{print $1}'`
export pubip=`dig +short myip.opendns.com @resolver1.opendns.com`

# the kubeadm init won't work entel remove the containerd config and restart it.
rm /etc/containerd/config.toml

systemctl restart containerd

tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system

#Kubernetes cluster init
kubeadm init --apiserver-advertise-address=$ipaddr --pod-network-cidr=192.168.0.0/16 --apiserver-cert-extra-sans=$pubip > /tmp/restult.out
cat /tmp/restult.out

#to get join command
tail -2 /tmp/restult.out > /tmp/join_command.sh;
aws s3 cp /tmp/join_command.sh s3://${s3buckit_name};
#this adds .kube/config for root account, run same for ubuntu user, if you need it
mkdir -p /root/.kube;
cp -i /etc/kubernetes/admin.conf /root/.kube/config;
cp -i /etc/kubernetes/admin.conf /tmp/admin.conf;
chmod 755 /tmp/admin.conf

#Add kube config to ubuntu user.
mkdir -p /home/ubuntu/.kube;
cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config;
chmod 755 /home/ubuntu/.kube/config


#to copy kube config file to s3
aws s3 cp /etc/kubernetes/admin.conf s3://${s3buckit_name}

export KUBECONFIG=/root/.kube/config

# install helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
bash get_helm.sh

# Setup flannel
kubectl create --kubeconfig /root/.kube/config ns kube-flannel
kubectl label --overwrite ns kube-flannel pod-security.kubernetes.io/enforce=privileged
helm repo add flannel https://flannel-io.github.io/flannel/
helm install flannel --set podCidr="192.168.0.0/16" --namespace kube-flannel flannel/flannel

# Apply kubectl Cheat Sheet Autocomplete
source <(kubectl completion bash) # set up autocomplete in bash into the current shell, bash-completion package should be installed first.
echo "source <(kubectl completion bash)" >> /home/ubuntu/.bashrc # add autocomplete permanently to your bash shell.
echo "source <(kubectl completion bash)" >> /root/.bashrc # add autocomplete permanently to your bash shell.
alias k=kubectl
complete -o default -F __start_kubectl k
echo "alias k=kubectl" >> /home/ubuntu/.bashrc
echo "alias k=kubectl" >> /root/.bashrc
echo "complete -o default -F __start_kubectl k" >> /home/ubuntu/.bashrc
echo "complete -o default -F __start_kubectl k" >> /root/.bashrc
