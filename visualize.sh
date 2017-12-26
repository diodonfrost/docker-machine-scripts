# Deploy docker service for visualize nodes and services
docker service create \
  --name=viz \
  --replicas=1 \
  --publish=8080:8080/tcp \
  --constraint=node.role==manager \
  --mount=type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
  dockersamples/visualizer
