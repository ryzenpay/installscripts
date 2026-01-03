echo "Fetching URL"
if [ -z $1 ]; then
    echo "Usage: $0 <url>"
    exit 1
fi
url=$1

#install dependencies
echo "installing dependencies"
sudo apt install curl -y 

#kubectl server
echo "installing rancher"
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.34.2+k3s1" sh -s - server --cluster-init
sudo chmod +r /etc/rancher/k3s/k3s.yaml
mkdir ~/.kube
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config

#helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash 
#cert manager
helm install \
  cert-manager oci://quay.io/jetstack/charts/cert-manager \
  --version v1.19.2 \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true

#deploy rancher
kubectl create namespace cattle-system 
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest 
helm install rancher rancher-latest/rancher --namespace cattle-system --set hostname=$url 

#fetch and print the password
echo "initial login password: $(kubectl get secret --namespace cattle-system bootstrap-secret -o go-template='{{ .data.bootstrapPassword|base64decode}}{{ "\n" }}')"

echo "if you did not get 'initial login password: <PASSWORD>' at the end of the script, check logs for errors"
