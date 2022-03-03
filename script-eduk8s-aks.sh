#!/bin/bash
echo "######################## Type: AKS for Azure, EKS for Amazon, GKE for Google ########################"
read -p "Enter the destination K8s cluster: " cloud
echo "#####################################################################################################"
read -p "Enter the domain name for Eduk8s workshop training portal: " domainname
read -p "Enter the Pivnet token: " pivnettoken
read -p "Enter the Tanzu network username: " tanzunetusername
read -p "Enter the Tanzu network password: " tanzunetpassword
if [ "$cloud" == "AKS" ];
 then
	 echo "#################  Installing AZ cli #####################"
	 curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
         echo "#########################################"
         echo "################ AZ CLI version #####################"
         az --version
         echo "############### Creating AKS Cluster #####################"
         echo "#####################################################################################################"
         echo "#############  Authenticate to AZ cli by following the screen Instructions below #################"
         echo "#####################################################################################################"
	 az login
         echo "#########################################"
         read -p "Enter the Subscription ID: " subscription
         read -p "Enter the region: " region
         echo "#########################################"
         echo "Resource group created with name tap-cluster-RG in region and subscription mentioned above"
         echo "#########################################"
	 az group create --name tap-cluster-RG --location $region --subscription $subscription
         echo "#########################################"
	 echo "Creating AKS cluster with 1 node and sku as Standard_D8S_v3, can be changed if required"
         echo "#########################################"
         az aks create --resource-group tap-cluster-RG --name tap-cluster-1 --subscription $subscription --node-count 1 --enable-addons monitoring --generate-ssh-keys --node-vm-size Standard_D8S_v3 -z 1 --enable-cluster-autoscaler --min-count 1 --max-count 1
         echo "############### Created AKS Cluster ###############"
	 echo "############### Install kubectl ##############"
	 sudo az aks install-cli
	 echo "############### Set the context ###############"
	 az account set --subscription $subscription
	 az aks get-credentials --resource-group tap-cluster-RG --name tap-cluster-1
	 echo "############## Verify the nodes #################"
         echo "#####################################################################################################"
	 kubectl get nodes
         echo "#####################################################################################################"
fi
### Common for any cloud
     echo "############# Installing Pivnet ###########"
     wget https://github.com/pivotal-cf/pivnet-cli/releases/download/v3.0.1/pivnet-linux-amd64-3.0.1
     chmod +x pivnet-linux-amd64-3.0.1
     sudo mv pivnet-linux-amd64-3.0.1 /usr/local/bin/pivnet

     echo "########## Installing Tanzu CLI  #############"
     pivnet login --api-token=${pivnettoken}
     pivnet download-product-files --product-slug='tanzu-cluster-essentials' --release-version='1.0.0' --product-file-id=1105818
     mkdir $HOME/tanzu-cluster-essentials
     tar -xvf tanzu-cluster-essentials-linux-amd64-1.0.0.tgz -C $HOME/tanzu-cluster-essentials
     export INSTALL_BUNDLE=registry.tanzu.vmware.com/tanzu-cluster-essentials/cluster-essentials-bundle@sha256:82dfaf70656b54dcba0d4def85ccae1578ff27054e7533d08320244af7fb0343
     export INSTALL_REGISTRY_HOSTNAME=registry.tanzu.vmware.com
     export INSTALL_REGISTRY_USERNAME=$tanzunetusername
     export INSTALL_REGISTRY_PASSWORD=$tanzunetpassword
     cd $HOME/tanzu-cluster-essentials
     ./install.sh
     echo "######## Installing Kapp ###########"
     sudo cp $HOME/tanzu-cluster-essentials/kapp /usr/local/bin/kapp
     kapp version
     echo "#################################"
     pivnet download-product-files --product-slug='tanzu-application-platform' --release-version='1.0.1' --product-file-id=1156163
     mkdir $HOME/tanzu
     tar -xvf tanzu-framework-linux-amd64.tar -C $HOME/tanzu
     export TANZU_CLI_NO_INIT=true
     cd $HOME/tanzu
     sudo install cli/core/v0.11.1/tanzu-core-linux_amd64 /usr/local/bin/tanzu
     tanzu version
     tanzu plugin install --local cli all
     tanzu plugin list
     echo "######### Installing Docker ############"
     sudo apt-get update
     sudo apt-get install  ca-certificates curl  gnupg  lsb-release
     curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
     echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
     sudo apt-get update
     sudo apt-get install docker-ce docker-ce-cli containerd.io -y
     sudo usermod -aG docker $USER
     echo "####### Verify Docker Version  ###########"
     sudo apt-get install jq -y
     echo "#####################################################################################################"
     kubectl create ns tap-install
     export INSTALL_REGISTRY_USERNAME=$tanzunetusername
     export INSTALL_REGISTRY_PASSWORD=$tanzunetpassword
     export INSTALL_REGISTRY_HOSTNAME=registry.tanzu.vmware.com
     tanzu secret registry add tap-registry --username ${INSTALL_REGISTRY_USERNAME} --password ${INSTALL_REGISTRY_PASSWORD} --server ${INSTALL_REGISTRY_HOSTNAME} --export-to-all-namespaces --yes --namespace tap-install
     tanzu package repository add tanzu-tap-repository --url registry.tanzu.vmware.com/tanzu-application-platform/tap-packages:1.0.1 --namespace tap-install
     tanzu package available list contour.tanzu.vmware.com -n tap-install
     tanzu package available list cert-manager.tanzu.vmware.com -n tap-install
     cat <<EOF > cert-manager-rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cert-manager-tap-install-cluster-admin-role
rules:
- apiGroups:
  - '*'
  resources:
  - '*'
  verbs:
  - '*'
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cert-manager-tap-install-cluster-admin-role-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cert-manager-tap-install-cluster-admin-role
subjects:
- kind: ServiceAccount
  name: cert-manager-tap-install-sa
  namespace: tap-install
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cert-manager-tap-install-sa
  namespace: tap-install
EOF
kubectl apply -f cert-manager-rbac.yaml
cat <<EOF > cert-manager-install.yaml
apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageInstall
metadata:
  name: cert-manager
  namespace: tap-install
spec:
  serviceAccountName: cert-manager-tap-install-sa
  packageRef:
    refName: cert-manager.tanzu.vmware.com
    versionSelection:
      constraints: "1.5.3+tap.1"
      prereleases: {}
EOF
kubectl apply -f cert-manager-install.yaml
tanzu package installed get cert-manager -n tap-install
kubectl get deployment cert-manager -n cert-manager
cat <<EOF > contour-rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: contour-tap-install-cluster-admin-role
rules:
- apiGroups:
  - '*'
  resources:
  - '*'
  verbs:
  - '*'
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: contour-tap-install-cluster-admin-role-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: contour-tap-install-cluster-admin-role
subjects:
- kind: ServiceAccount
  name: contour-tap-install-sa
  namespace: tap-install
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: contour-tap-install-sa
  namespace: tap-install
EOF
kubectl apply -f contour-rbac.yaml
cat <<EOF > contour-install.yaml
apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageInstall
metadata:
  name: contour
  namespace: tap-install
spec:
  serviceAccountName: tap-install-sa
  packageRef:
    refName: contour.tanzu.vmware.com
    versionSelection:
      constraints: "1.18.2+tap.1"
      prereleases: {}
EOF
kubectl apply -f contour-install.yaml
tanzu package available get contour.tanzu.vmware.com/1.18.2+tap.1 --values-schema -n tap-install
cat <<EOF > contour-install.yaml
apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageInstall
metadata:
  name: contour
  namespace: tap-install
spec:
  serviceAccountName: contour-tap-install-sa
  packageRef:
    refName: contour.tanzu.vmware.com
    versionSelection:
      constraints: 1.18.2+tap.1
      prereleases: {}
  values:
  - secretRef:
      name: contour-values
---
apiVersion: v1
kind: Secret
metadata:
  name: contour-values
  namespace: tap-install
stringData:
  values.yaml: |
    envoy:
      service:
        type: LoadBalancer
EOF
kubectl apply -f contour-install.yaml
tanzu package installed get contour -n tap-install
kubectl get po -n tanzu-system-ingress
#!/bin/bash
kubectl apply -k "github.com/eduk8s/eduk8s?ref=master"
kubectl set env deployment/eduk8s-operator -n eduk8s INGRESS_DOMAIN=$domainname
kubectl apply -f https://raw.githubusercontent.com/Eknathreddy09/lab-lc-helloworld/main/resources/workshop.yaml
kubectl apply -f https://raw.githubusercontent.com/Eknathreddy09/lab-lc-helloworld/main/resources/training-portal.yaml
sleep 30s
kubectl get trainingportal
