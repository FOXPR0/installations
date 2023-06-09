### Ubuntu:



### Rke2 Server Installation:



# Ubuntu instructions 
# stop the software firewall
systemctl disable --now ufw

# get updates, install nfs, and apply
apt update
apt install nfs-common -y  
apt upgrade -y

# clean up
apt autoremove -y


# On rancher1
curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE=server sh - 

# start and enable for restarts - 
systemctl enable --now rke2-server.service

systemctl status rke2-server

cp $(find /var/lib/rancher/rke2/data/ -name kubectl) /usr/local/bin/kubectl

mkdir ~/.kube/
cp /etc/rancher/rke2/rke2.yaml  ~/.kube/config


kubectl version --short

kubectl get node -o wide

kubectl get pods -A





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
password_rancher=bootStrapAllTheThings

# helm install rancher
helm upgrade -i rancher rancher-latest/rancher --create-namespace --namespace cattle-system --set hostname=${hostname_rancher} --set bootstrapPassword=${password_rancher} --set replicas=1

 kubectl get pods -A
