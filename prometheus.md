cd prometheus-setup/prometheus
kubectl create -f namespaces.yaml

#open prometheus-config-map.yml to set the endpoints prometheus will be scraping 

kubeadm apply -f prometheus-config-map.yml
kubectl apply -f prometheus-deployment.yml

#run kubectl get pods -n monitoring

kubectl apply -f prometheus-service.yml

#run kubectl get svc -n monitoring


kubectl apply -f clusterRole.yml

kubectl apply -f kube-state-metrics.yml


cd grafana

kubectl apply -f grafana-deployment.yml
kubectl apply -f grafana-service.yml


#once grafana is installed, we need to configure promettheus as a data source

#Repeat these following steps on both your master and worker nodes.
useradd prometheus

cd /home/prometheus
curl -LO "https://github.com/prometheus/node_exporter/releases/download/v0.16.0/node_exporter-0.16.0.linux-amd64.tar.gz"
tar -xvzf node_exporter-0.16.0.linux-amd64.tar.gz
mv node_exporter-0.16.0.linux-amd64 node_exporter
cd node_exporter
chown prometheus:prometheus node_exporter


cat > /etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Node Exporter

[Service]
User=prometheus
ExecStart=/home/prometheus/node_exporter/node_exporter

[Install]
WantedBy=default.target
EOF


#Reload systemd:

systemctl daemon-reload
#Enable the node_exporter service:
systemctl enable node_exporter.service
#Start the node_exporter service:
systemctl start node_exporter.service


Container CPU load average:
container_cpu_load_average_10s
Memory usage query:
((sum(node_memory_MemTotal_bytes) - sum(node_memory_MemFree_bytes) - sum(node_memory_Buffers_bytes) - sum(node_memory_Cached_bytes)) / sum(node_memory_MemTotal_bytes)) * 100
