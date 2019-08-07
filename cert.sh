
openssl x509 -in  <cert> -noout  -text

grep 'client-certificate-data: ' ${HOME}/.kube/config | \
   sed 's/.*client-certificate-data: //' | \
   base64 -d | \
   openssl x509 --in - --text
   
   openssl x509 -in  server.crt -noout  -text -subject
      openssl x509 -in  server.crt -noout  -text -issuer
   
   openssl verify <cert>

   #commands applicable to 1.15 Kubeadm and kubernetes version

   kubeadm alpha certs check-expiration

   kubeadm alpha certs renew


#configure go

https://golang.org/dl/

export GOROOT="/usr/local/Cellar/go/1.12.5/libexec"
export GOPATH="$HOME/go"
export PATH="$GOROOT/bin:$PATH"
export PATH=$PATH:$GOPATH/bin

   #install KinD
Installation and usage

You can install kind with GO111MODULE="on" go get sigs.k8s.io/kind@v0.4.0.

or 

curl -Lo ./kind-darwin-amd64 https://github.com/kubernetes-sigs/kind/releases/download/v0.4.0/kind-darwin-amd64
chmod +x ./kind-darwin-amd64
mv ./kind-darwin-amd64 /some-dir-in-your-PATH/kind


#configure certs to expire after 6 minutes
git clone kubernetes repo

cd kubernetes
git tag
git checkout <tag>

cd /kubernetes/cmd/kubeadm/app/constants

#change certificate validity to desired expiry time.

kind build node-image --kube-root /Users/tunde/go/src/k8s.io/cork-cert-training/kubernetes --image kindest/node:corkcert

&& kind create cluster --image kindest/node:corkcert



crictl ps
critctl  pod 
crictl logs <container ID>
kubeadm init phase kubeconfig admin --config /kind/kubeadm.config


#get rid of all expired certificates
 rm apiserver* front-proxy-client.* etcd/healthcheck-client.* etcd/peer.* etcd/server.*

 kubeadm init phase certs all --config /kind/kubeadm.conf
 kubeadm init phase kubeconfig scheduler --config /kind/kubeadm.conf
 kubeadm init phase kubeconfig controller-manager --config /kind/kubeadm.conf

 docker  cp  kubeadm.conf <controlplane container ID>:/kind/

 kubeadm token create --print-join-command