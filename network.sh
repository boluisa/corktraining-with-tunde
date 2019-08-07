netstat -tupln

calicoctl
__________________________
sudo -i
curl -O -L  https://github.com/projectcalico/calicoctl/releases/download/v3.5.7/calicoctl
chmod +x calicoctl
mv calicoctl /usr/bin/calicoctl

export DATASTORE_TYPE=kubernetes
export KUBECONFIG=home/ubuntu/.kube/config
DATASTORE_TYPE=kubernetes KUBECONFIG=/home/ubuntu/.kube/config calicoctl get nodes
calicoctl node status
calicoctl get nodes
calicoctl node checksystem
DATASTORE_TYPE=kubernetes KUBECONFIG=/home/ubuntu/.kube/config calicoctl get nodes -o  wide
DATASTORE_TYPE=kubernetes KUBECONFIG=/home/ubuntu/.kube/config calicoctl get nodes <node-name> -o yaml > test.yaml
DATASTORE_TYPE=kubernetes KUBECONFIG=/home/ubuntu/.kube/config calicoctl apply -f test.yaml
DATASTORE_TYPE=kubernetes KUBECONFIG=/home/ubuntu/.kube/config calicoctl get workloadEndpoint --all-namespaces

iptables -L -n 
iptable-save

ip ro


https://pracucci.com/kubernetes-dns-resolution-ndots-options-and-why-it-may-affect-application-performances.html