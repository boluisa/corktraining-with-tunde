
sudo -i


swapoff -a

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat << EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
sudo add-apt-repository    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
 $(lsb_release -cs) \
 stable"

sudo apt-get update
sudo apt-get install -y docker-ce=18.06.1~ce~3-0~ubuntu kubelet=1.14.0-00 kubeadm=1.14.0-00 kubectl=1.14.0-00
sudo apt-mark hold docker-ce kubelet kubeadm kubectl

cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
systemctl restart  docker


cat > /etc/sysctl.d/99-kubernetes-cri.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#set up LB node  using HAproxy
# Install HAProxy. Version 1.8+ is required.

# On Ubuntu 16.04, you need to install a PPA to get 1.8:

sudo -i

apt-get install software-properties-common
add-apt-repository ppa:vbernat/haproxy-1.8
apt-get update
apt-get install haproxy -y
mv  /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.old

cat << EOF > /etc/haproxy/haproxy.cfg
global
   log /dev/log local0
   log /dev/log local1 notice
   chroot /var/lib/haproxy
   stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
   stats timeout 30s
   user haproxy
   group haproxy
   daemon

   # Default SSL material locations
   ca-base /etc/ssl/certs
   crt-base /etc/ssl/private

   # Default ciphers to use on SSL-enabled listening sockets.
   # For more information, see ciphers(1SSL). This list is from:
   #  https://hynek.me/articles/hardening-your-web-servers-ssl-ciphers/
   # An alternative list with additional directives can be obtained from
   #  https://mozilla.github.io/server-side-tls/ssl-config-generator/?server=haproxy
   ssl-default-bind-ciphers ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:RSA+AESGCM:RSA+AES:!aNULL:!MD5:!DSS
   ssl-default-bind-options no-sslv3

defaults
   log  global
   mode http
   option   httplog
   option   dontlognull
       timeout connect 5000
       timeout client  50000
       timeout server  50000
   errorfile 400 /etc/haproxy/errors/400.http
   errorfile 403 /etc/haproxy/errors/403.http
   errorfile 408 /etc/haproxy/errors/408.http
   errorfile 500 /etc/haproxy/errors/500.http
   errorfile 502 /etc/haproxy/errors/502.http
   errorfile 503 /etc/haproxy/errors/503.http
   errorfile 504 /etc/haproxy/errors/504.http

frontend k8s-api
   bind 0.0.0.0:6443
   mode tcp
   option tcplog
   default_backend k8s-api

backend k8s-api
   mode tcp
   option tcplog
   option tcp-check
   balance roundrobin
   default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100

       server <apiserver1_hostname> <apiserver1_ip>:6443 check
       server <apiserver2_hostname> <apiserver2_ip>:6443 check
       server <apiserver3_hostname> <apiserver3_ip>:6443 check
EOF

 systemctl daemon-reload
 systemctl restart haproxy

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
##ETCD setup




cat << EOF > /etc/systemd/system/kubelet.service.d/20-etcd-service-manager.conf
[Service]
ExecStart=
ExecStart=/usr/bin/kubelet --address=127.0.0.1  --pod-manifest-path=/etc/kubernetes/manifests --allow-privileged=true  
Restart=always
EOF

systemctl daemon-reload
systemctl restart kubelet




export HOST0=<etcd host0 IP>
export HOST1=<etcd host1 IP>
export HOST2=<etcd host2 IP>


# Create temp directories to store files that will end up on other hosts.
mkdir -p /tmp/${HOST0}/ /tmp/${HOST1}/ /tmp/${HOST2}/

ETCDHOSTS=(${HOST0} ${HOST1} ${HOST2})
NAMES=("infra0" "infra1" "infra2")

for i in "${!ETCDHOSTS[@]}"; do
HOST=${ETCDHOSTS[$i]}
NAME=${NAMES[$i]}
cat << EOF > /tmp/${HOST}/kubeadmcfg.yaml
apiVersion: "kubeadm.k8s.io/v1beta1"
kind: ClusterConfiguration
etcd:
    local:
        serverCertSANs:
        - "${HOST}"
        peerCertSANs:
        - "${HOST}"
        extraArgs:
            initial-cluster: infra0=https://${ETCDHOSTS[0]}:2380,infra1=https://${ETCDHOSTS[1]}:2380,infra2=https://${ETCDHOSTS[2]}:2380
            initial-cluster-state: new
            name: ${NAME}
            listen-peer-urls: https://${HOST}:2380
            listen-client-urls: https://${HOST}:2379
            advertise-client-urls: https://${HOST}:2379
            initial-advertise-peer-urls: https://${HOST}:2380
EOF
done

cat <<  EOF > etcdconfig.txt
/tmp/${HOST1}/kubeadmcfg.yaml
/tmp/${HOST2}/kubeadmcfg.yaml
EOF

tar -czf  etcdcfg.tar.gz -T etcdconfig.txt
USER=ubuntu
ETCD_HOSTS="<ETCDIP1> <ETCDIP2>" 
for host in $ETCD_HOSTS; do
    scp etcdcfg.tar.gz "${USER}"@$host:
done


tar -xzf etcdcfg.tar.gz 

kubeadm init phase certs etcd-ca

##This creates two files
 ##    /etc/kubernetes/pki/etcd/ca.crt
  ##   /etc/kubernetes/pki/etcd/ca.key


Copy both files to the corresponding directories on the other etcd nodes (you may have to manually create the directory).

# Make a list of required  CA files
cat << EOF > ca-files.txt
/etc/kubernetes/pki/etcd/ca.crt
/etc/kubernetes/pki/etcd/ca.key
EOF

# create the archive

tar -czf  ca.tar.gz -T ca-files.txt

# copy the archive to the subsequent ETCD nodes
USER=ubuntu
ETCD_HOSTS="<ETCDIP1> <ETCDIP2>"  
for host in $ETCD_HOSTS; do
    scp ca.tar.gz "${USER}"@$host:
done

#on each host run the following commands

mkdir  -p /etc/kubernetes/pki/etcd
tar -xzf ca.tar.gz -C /etc/kubernetes/pki/etcd --strip-components=3
chown -R root:root /etc/kubernetes/pki


#Create certificates
#On each node run the following commands to create the necessary certificates
kubeadm init phase certs etcd-server --config=kubeadmcfg.yaml
kubeadm init phase certs etcd-peer --config=kubeadmcfg.yaml
kubeadm init phase certs etcd-healthcheck-client --config=kubeadmcfg.yaml
kubeadm init phase certs apiserver-etcd-client  --config=kubeadmcfg.yaml



#Make sure certificates and configs are present on all hosts

#The following files should be present on each etcd node:


#Run kubeadm for etcd
#On each host run the following command. --config is the config file that you created for this host in Create kubeadm etcd config files.

kubeadm init phase etcd local --config=kubeadmcfg.yaml

#Check cluster health. The etcd image version should match the version you installed.

docker run --rm -it --net host -v /etc/kubernetes:/etc/kubernetes quay.io/coreos/etcd:v3.3.10 etcdctl --cert-file /etc/kubernetes/pki/etcd/peer.crt --key-file /etc/kubernetes/pki/etcd/peer.key --ca-file /etc/kubernetes/pki/etcd/ca.crt --endpoints https://${HOST0}:2379 cluster-health


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Setup Control Plane


#Copy required files from an etcd0 node to all control plane nodes

# Make a list of required etcd certificate files
cat << EOF > etcd-pki-files.txt
/etc/kubernetes/pki/etcd/ca.crt
/etc/kubernetes/pki/apiserver-etcd-client.crt
/etc/kubernetes/pki/apiserver-etcd-client.key
EOF


# create the archive
tar -czf etcd-pki.tar.gz -T etcd-pki-files.txt
# copy the archive to the control plane nodes


USER=ubuntu
CONTROL_PLANE_HOSTS="<controlplane0-IP> <controlplane1-IP> <controlplane2-IP>"
for host in $CONTROL_PLANE_HOSTS; do
  scp  etcd-pki.tar.gz "${USER}"@$host:
done

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Set up the first control plane node

mkdir -p /etc/kubernetes/pki
tar -xzf etcd-pki.tar.gz -C /etc/kubernetes/pki --strip-components=3


cat << EOF > v4.yaml
apiVersion: "kubeadm.k8s.io/v1beta1"
kind: InitConfiguration
nodeRegistration:
  name: "$(hostname)"   
  criSocket: "/var/run/dockershim.sock"
  taints:
  - key: "kubeadmNode"
    value: "master"
    effect: "NoSchedule"
  kubeletExtraArgs:
    cgroup-driver: "systemd"
---
apiVersion: kubeadm.k8s.io/v1beta1
kind: ClusterConfiguration
kubernetesVersion: v1.14.1
apiServer:
  certSANs:
  - "ip-172-31-18-106"
controlPlaneEndpoint: "ip-172-31-18-106:6443"
etcd:
    external:
        endpoints:
        - https://172.31.26.1:2379
        - https://172.31.21.93:2379
        - https://172.31.28.104:2379
        caFile: /etc/kubernetes/pki/etcd/ca.crt
        certFile: /etc/kubernetes/pki/apiserver-etcd-client.crt
        keyFile: /etc/kubernetes/pki/apiserver-etcd-client.key
networking:
    # This CIDR is a calico default. Substitute or remove for your CNI provider.
    podSubnet: "192.168.0.0/16"
EOF
#Run kubeadm init to set up the first control plane node. The config file in the command below is the one that you created for this control plane node with Control plane configs.

kubeadm init --config  v4.yaml --ignore-preflight-errors=ImagePull

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Copy required files to the the other control plane nodes

#Run the following script, or something similar, to copy the files created in the previous step to the other control plan nodes. Update the script to export the appropriate values for $USER and $CONTROL_PLANE_IPS.

# make a list of required kubernetes certificate files
cat << EOF > certificate_files.txt
/etc/kubernetes/pki/ca.crt
/etc/kubernetes/pki/ca.key
/etc/kubernetes/pki/sa.key
/etc/kubernetes/pki/sa.pub
/etc/kubernetes/pki/front-proxy-ca.crt
/etc/kubernetes/pki/front-proxy-ca.key
EOF


# create the archive
tar -czf control-plane-certificates.tar.gz -T certificate_files.txt
USER=ubuntu 
CONTROL_PLANE_IPS="<controlplane1-IP> <controlplane2-IP>" 
for host in ${CONTROL_PLANE_IPS}; do
    scp control-plane-certificates.tar.gz "${USER}"@$host:
done

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#Install a pod network
kubectl apply -f https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/rbac-kdd.yaml
kubectl apply -f https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml