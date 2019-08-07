#ETCD Troubleshooting Techniques

docker exec -it <etcd container id>  /bin/sh

export ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.crt
export ETCDCTL_CERT=/etc/kubernetes/pki/etcd/peer.crt
export ETCDCTL_KEY=/etc/kubernetes/pki/etcd/peer.key
export ETCDCTL_ENDPOINTS=<endpoints>
export ETCDCTL_API=3

---------------
export ETCDCTL_CA_FILE=/etc/kubernetes/pki/etcd/ca.crt
export ETCDCTL_CERT_FILE=/etc/kubernetes/pki/etcd/peer.crt
export ETCDCTL_KEY_FILE=/etc/kubernetes/pki/etcd/peer.key
export ETCDCTL_API=2
----------------------------------------------------------
etcdctl  --endpoints https://host:2379 cluster-health
etcdctl --cert-file /etc/kubernetes/pki/etcd/peer.crt --key-file /etc/kubernetes/pki/etcd/peer.key --ca-file /etc/kubernetes/pki/etcd/ca.crt --endpoints https://host:2379 cluster-health
docker run --rm -it --net host -v /etc/kubernetes:/etc/kubernetes quay.io/coreos/etcd:v3.3.10 etcdctl --cert-file /etc/kubernetes/pki/etcd/peer.crt --key-file /etc/kubernetes/pki/etcd/peer.key --ca-file /etc/kubernetes/pki/etcd/ca.crt --endpoints https://host:2379 cluster-health


#Cluster status
etcdctl --write-out=table --endpoints=$ENDPOINTS endpoint status


etcdctl --debug —endpoints https://host:2379 --cert-file=/etc/kubernetes/pki/etcd/server.crt --key-file=/
etc/kubernetes/pki/etcd/server.key --ca-file=/etc/kubernetes/pki/etcd/ca.crt cluster-health



#list etcd directory
ETCDCTL_API=3 etcdctl --endpoints https://host:2379 get "/" --prefix --keys-only

ETCDCTL_API=3 etcdctl --endpoints https://host:2379 get "/registry/secrets/default" --prefix
ETCDCTL_API=3 etcdctl --endpoints https://host:2379 get "/registry/secrets/default" --from-key
ETCDCTL_API=3 etcdctl --endpoints https://host:2379 get "/registry/secrets/default" --from-key -w fields

#check performance
etcdctl --endpoints https://host:2379 check perf

#how to check member  using etcdctl_API=3
ETCDCTL_API=3 etcdctl --endpoints=https://host:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt --key=/etc/kubernetes/pki/etcd/healthcheck-clie
nt.key member list


#check etcd leader 
etcdctl -w table --endpoints https://host:2379 endpoint status

#Snapshot
etcdctl --endpoints=$ENDPOINTS snapshot save my.db

etcdctl --write-out=table --endpoints=$ENDPOINTS snapshot status my.db

ETCDCTL_API=3 etcdctl snapshot restore snapshot.db \
  --name m1 \
  --initial-cluster m1=http://host1:2380,m2=http://host2:2380,m3=http://host3:2380 \
  --initial-cluster-token etcd-cluster-1 \
  --initial-advertise-peer-urls http://host1:2380

#reset ETCD

rm -rf /var/lib/etcd/*   #on all etc nodes and run 

systemctl restart kubelet && systemctl restart docker

#To clear the etcd database, type the following:
etcd -f

https://etcd.io/docs/v3.3.12/demo/