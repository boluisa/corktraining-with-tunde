Return all time series with the metric node_cpu_seconds_total:
node_cpu_seconds_total
Return all time series with the metric node_cpu_seconds_total and the given job and mode labels:
node_cpu_seconds_total{job="node-exporter", mode="idle"}
Return a whole range of time (in this case 5 minutes) for the same vector, making it a range vector:
node_cpu_seconds_total{job="node-exporter", mode="idle"}[5m]
Query job that end with -exporter:
node_cpu_seconds_total{job=~".*-exporter"}
Query job that begins with kube:
container_cpu_load_average_10s{job=~"^kube.*"}