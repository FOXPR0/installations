
#!/bin/bash
# Setting a return status for a function



### Ubuntu:

configure_ubuntu () {

### Rke2 Server Installation:

# Ubuntu instructions 
# stop the software firewall
systemctl disable --now ufw

# get updates, install nfs, and apply

apt-mark hold linux-image-*
apt update
apt install nfs-common curl -y  
apt upgrade -y 
apt-mark unhold linux-image-*
# clean up
apt autoremove -y

# To install kernel, you can use below command
# apt install -y linux-image-*



# On rancher1
curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE=server sh - 

# start and enable for restarts - 
systemctl enable --now rke2-server.service

systemctl status rke2-server --no-pager

cp $(find /var/lib/rancher/rke2/data/ -name kubectl) /usr/local/bin/kubectl

mkdir ~/.kube/
cp /etc/rancher/rke2/rke2.yaml  ~/.kube/config


kubectl version --short

kubectl get node -o wide

kubectl get pods -A


}


install_rancher () {

### Rancher Server


# Adding Helm-3

curl -#L https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# add needed helm charts
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo add jetstack https://charts.jetstack.io



# still on  rancher1
# add the cert-manager CRD
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.6.1/cert-manager.crds.yaml

# helm install jetstack
helm upgrade -i cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace


### Installing Rancher Server

read -p "Enter your hostname: " hostname_rancher

echo Your provided hostname is $hostname_rancher


#hostname_rancher=ec2-3-110-135-32.ap-south-1.compute.amazonaws.com

password_rancher=bootStrapAllTheThings

# helm install rancher
helm upgrade -i rancher rancher-latest/rancher --create-namespace --namespace cattle-system --set hostname=${hostname_rancher} --set bootstrapPassword=${password_rancher} --set replicas=1

 kubectl get pods -A


}


#make sure we're running as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

configure_ubuntu
install_rancher 
