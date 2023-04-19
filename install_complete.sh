#!/bin/bash
# Setting a return status for a function



### This script is specially desgined for Ubuntu OS

#download_kubectl () {
#  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
#  chmod +x kubectl
#  mv ./kubectl /usr/bin/kubectl
#}

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


 get_rancher_version () {
  # Get list of available Rancher versions from GitHub API
  VERSIONS_URL="https://api.github.com/repos/rancher/rancher/releases"
  VERSIONS=$(curl -s $VERSIONS_URL | grep '"tag_name":' | cut -d '"' -f 4 | grep -v 'alpha\|beta' | sort -rV)

  # Display menu of available versions
  echo "Please select a Rancher version to install (or type 'latest' for the latest version):"
  select VERSION in $VERSIONS "latest"; do
    if [ -n "$VERSION" ]; then
      break
    fi
  done

  # Set RANCHER_VERSION variable
  if [ "$VERSION" = "latest" ]; then
    RANCHER_VERSION=$(curl -s $VERSIONS_URL | grep '"tag_name":' | cut -d '"' -f 4 | grep -v 'alpha\|beta' | head -n 1)
  else
    RANCHER_VERSION=$VERSION
  fi
}


install_rancher_apt_get () {
# Install required packages
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Add Rancher Helm repository
curl -fsSL https://helm.releases.rancher.com/$(lsb_release -cs)/stable.key | sudo apt-key add -
sudo echo "deb https://helm.releases.rancher.com/$(lsb_release -cs)/stable $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/rancher-stable.list > /dev/null

# Install Helm
sudo apt-get update
sudo apt-get install -y helm

# Get user's choice of Rancher version to install
get_rancher_version

# Install Rancher using Helm
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm repo update
helm install rancher rancher-stable/rancher --version $RANCHER_VERSION --namespace cattle-system --set hostname=rancher.example.com

# Verify Rancher installation
kubectl -n cattle-system rollout status deploy/rancher

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

get_rancher_version

read -p "Enter your hostname: " hostname_rancher

echo Your provided hostname is $hostname_rancher


#hostname_rancher=ec2-3-110-135-32.ap-south-1.compute.amazonaws.com

password_rancher=bootStrapAllTheThings

# helm install rancher
# helm upgrade -i rancher rancher-latest/rancher --create-namespace --namespace cattle-system --set hostname=${hostname_rancher} --set bootstrapPassword=${password_rancher} --set replicas=1

### To install specific version rancher
## Get rancher version first
# helm search repo rancher-latest --versions


helm upgrade -i rancher rancher-latest/rancher --version $RANCHER_VERSION  --create-namespace --namespace cattle-system --set hostname=${hostname_rancher} --set bootstrapPassword=${password_rancher} --set replicas=1

kubectl get pods -A


# Verify Rancher installation
kubectl -n cattle-system rollout status deploy/rancher

}


docker_rancher () {

curl -fsSL get.docker.com | bash
systemctl enable docker
docker run --privileged -d --restart=no -p 8080:80 -p 8443:443 -p 36443:6443 -v rancher:/var/lib/rancher  rancher/rancher


}



install_helm () {

curl -fsSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash


}


# Function to display menu and get user's choice
function get_rke_version {
  # Get list of available RKE versions from GitHub API
  VERSIONS_URL="https://api.github.com/repos/rancher/rke/releases"
  VERSIONS=$(curl -s $VERSIONS_URL | grep '"tag_name":' | cut -d '"' -f 4 | sort -rV)

  # Display menu of available versions
  echo "Please select an RKE version to install:"
  select VERSION in $VERSIONS; do
    if [ -n "$VERSION" ]; then
      break
    fi
  done

  # Set RKE_VERSION variable
  RKE_VERSION=$VERSION
}




install_rke () {
# Install required packages
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# Add Docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Add Docker repository
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Install Docker
sudo apt-get update
sudo apt-get install -y docker-ce

# Add current user to Docker group
sudo usermod -aG docker $USER

# Get user's choice of RKE version to install
get_rke_version

# Download and install RKE binary
RKE_DOWNLOAD_URL="https://github.com/rancher/rke/releases/download/$RKE_VERSION/rke_linux-amd64"
curl -LO $RKE_DOWNLOAD_URL
sudo install rke_linux-amd64 /usr/local/bin/rke

# Verify RKE installation
rke --version

}


# Function to display menu and get user's choice
function get_rke2_version {
  # Get list of available RKE2 versions from GitHub API
  VERSIONS_URL="https://api.github.com/repos/rancher/rke2/releases"
  VERSIONS=$(curl -s $VERSIONS_URL | grep '"tag_name":' | cut -d '"' -f 4 | sort -rV)

  # Display menu of available versions
  echo "Please select an RKE2 version to install:"
  select VERSION in $VERSIONS; do
    if [ -n "$VERSION" ]; then
      break
    fi
  done

  # Set RKE2_VERSION variable
  RKE2_VERSION=$VERSION
}


install_rke2_apt_get () {
# Install required packages
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# Add Rancher GPG key
curl -fsSL https://rancher-rke2-charts.s3.amazonaws.com/keys/545D8F0B.asc | sudo apt-key add -

# Add RKE2 repository
sudo add-apt-repository "deb [arch=amd64] https://rancher-rke2-charts.s3.amazonaws.com/$(lsb_release -cs)/stable amd64"

# Install RKE2
sudo apt-get update
sudo apt-get install -y rke2-server

# Get user's choice of RKE2 version to install
get_rke2_version

# Set RKE2 version in config file
sudo sed -i "s/VERSION=.*/VERSION=$RKE2_VERSION/g" /etc/rancher/rke2/config.yaml

# Restart RKE2 server
sudo systemctl restart rke2-server

# Verify RKE2 installation
sudo rke2 --version
}




# Function to display menu and get user's choice
function get_k3s_version {
  # Get list of available k3s versions from GitHub API
  VERSIONS_URL="https://api.github.com/repos/rancher/k3s/releases"
  VERSIONS=$(curl -s $VERSIONS_URL | grep '"name":' | cut -d '"' -f 4 | sort -rV)

  # Display menu of available versions
  echo "Please select a k3s version to install (or type 'latest' for the latest version):"
  select VERSION in $VERSIONS "latest"; do
    if [ -n "$VERSION" ]; then
      break
    fi
  done

  # Set K3S_VERSION variable
  if [ "$VERSION" = "latest" ]; then
    K3S_VERSION=$(curl -s $VERSIONS_URL | grep '"name":' | cut -d '"' -f 4 | head -n 1)
  else
    K3S_VERSION=$VERSION
  fi
}


install_k3s () {
# Install k3s using curl script
get_k3s_version
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=$K3S_VERSION sh -

# Verify k3s installation
sudo k3s kubectl get nodes
}



# Function to display menu and prompt user for input
show_menu ()  {
  echo "Please select an option for Installations:"
  echo "1. Install RKE2 Server"
  echo "2. Install Rancher Manager Using Helm"
  echo "3. Install Rancher Manager Using Docker"
  echo "4. Install RKE2 Sever using apt"
  echo "5. Install Helm"
  echo "6. Install RKE"
  echo "7. Install k3s"
 # echo "8. Download Kubectl"
  echo "9. Exit"
  read -p "Enter your choice [1-8]: " choice
}

invalid ()
{
  clear
  echo  "Invalid option. Please try again. \n"
  sleep 1

}



#make sure we're running as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi


# Loop through menu until user selects "4. Exit"

while true
do
  #sleep 1
  #clear
  show_menu
  case $choice in
    1) configure_ubuntu ;;
    2) install_rancher ;;
    3) docker_rancher ;;
    4) install_rke2_apt_get ;;
    5) install_helm ;;
    6) install_rke ;;
    7) install_k3s ;;
   # 8) download_kubectl ;;
    9) exit 0 ;;
    *) invalid ;;
   # *) echo "Invalid option. Please try again." ;;
  esac
done

## Some old functions 
#configure_ubuntu
#install_rancher
# Remove above old functions
