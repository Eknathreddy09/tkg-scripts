#!/bin/bash
echo "######### Ensure you have downloaded Tanzu CLI, kubectl from VMware customer connect page and copied to home directory #########"
echo "######### Installing Docker ############"
sudo apt-get update
sudo apt-get install  ca-certificates curl  gnupg  lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io -y
sudo usermod -aG docker $USER
mkdir $HOME/tanzu
cd $HOME/tanzu
cp $HOME/tanzu-cli-bundle-linux-amd64.tar $HOME/tanzu
cp $HOME/kubectl-linux-v1.21.2+vmware.1.gz $HOME/tanzu
echo "################# Extracting the files ###################"
tar -xvf tanzu-cli-bundle-linux-amd64.tar
gunzip kubectl-linux-v1.21.2+vmware.1.gz
cd $HOME/tanzu/cli
echo "################# Installing tanzu CLI 1.4.1 ###################"
sudo install core/v1.4.1/tanzu-core-linux_amd64 /usr/local/bin/tanzu
cd $HOME/tanzu/
tanzu plugin install --local cli all
tanzu plugin list
cd $HOME/tanzu
echo "################# Installing Kubectl ###################"
sudo install kubectl-linux-v1.21.2+vmware.1 /usr/local/bin/kubectl
cd $HOME/tanzu/cli
echo "################# Installing Carvel tools ###################"
gunzip imgpkg-linux-amd64-v0.10.0+vmware.1.gz
gunzip kapp-linux-amd64-v0.37.0+vmware.1.gz
gunzip kbld-linux-amd64-v0.30.0+vmware.1.gz
gunzip ytt-linux-amd64-v0.34.0+vmware.1.gz
chmod ugo+x imgpkg-linux-amd64-v0.10.0+vmware.1
chmod ugo+x kapp-linux-amd64-v0.37.0+vmware.1
chmod ugo+x kbld-linux-amd64-v0.30.0+vmware.1
chmod ugo+x ytt-linux-amd64-v0.34.0+vmware.1
sudo mv ./imgpkg-linux-amd64-v0.10.0+vmware.1 /usr/local/bin/imgpkg
sudo mv ./kapp-linux-amd64-v0.37.0+vmware.1 /usr/local/bin/kapp
sudo mv ./kbld-linux-amd64-v0.30.0+vmware.1 /usr/local/bin/kbld
sudo mv ./ytt-linux-amd64-v0.34.0+vmware.1 /usr/local/bin/ytt
echo "################# Verify imgpkg version ###################"
imgpkg --version
echo "################# Verify kapp version ###################"
kapp --version
echo "################# Verify kbld version  ###################"
kbld --version
echo "################# Verify ytt version  ###################"
ytt --version
