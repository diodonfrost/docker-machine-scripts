#!/bin/bash

# Authentification credential
vsphere_hostname=192.168.1.1
vpshere_user=root
vsphere_password=secret
vpshere_datastore=datastore_1
vsphere_network=docker_network

# Set number of worker ans leader
number_leader=3
number_worker=2

### Deploy virtual machine leader

for i in `seq 1 $number_leader`;
do
  docker-machine create \
        --engine-env 'DOCKER_OPTS="-H unix:///var/run/docker.sock"' \
        --driver vmwarevsphere \
        --vmwarevsphere-vcenter $vsphere_hostname \
        --vmwarevsphere-username $vpshere_user \
        --vmwarevsphere-password $vsphere_password \
        --vmwarevsphere-memory-size 2048 \
        --vmwarevsphere-cpu-count 2 \
        --vmwarevsphere-disk-size 8024 \
        --vmwarevsphere-datastore $vpshere_datastore \
        --vmwarevsphere-network $vsphere_network \
        leader$i &
done

### Deploy virtual machine worker

for i in `seq 1 $number_worker`;
do
  docker-machine create \
        --engine-env 'DOCKER_OPTS="-H unix:///var/run/docker.sock"' \
        --driver vmwarevsphere \
        --vmwarevsphere-vcenter $vsphere_hostname \
        --vmwarevsphere-username $vpshere_user \
        --vmwarevsphere-password $vsphere_password \
        --vmwarevsphere-memory-size 2048 \
        --vmwarevsphere-cpu-count 2 \
        --vmwarevsphere-disk-size 8024 \
        --vmwarevsphere-datastore $vpshere_datastore \
        --vmwarevsphere-network $vsphere_network \
        worker$i &
done

### Wait virtual machine creation
wait -n

### Retrieve leader information
ip_leader1=$(docker-machine ip leader1)

### START MASTER NODE ###

# Start docker swarm node master
eval "$(docker-machine env leader1)"

docker swarm init \
      --listen-addr $ip_leader1 \
      --advertise-addr $ip_leader1

### START WORKER NODE ###

# Set worker environment
token=$(docker swarm join-token worker -q)

for i in `seq 2 $number_leader`;
do
  eval "$(docker-machine env leader$i)"

  docker swarm join \
      --token $token \
      $ip_leader1:2377
done

# Promote node to leader backup
for i in `seq 2 $number_leader`;
do
  eval "$(docker-machine env leader1)"
  docker node promote leader$i
done

# Join worker node to cluster
for i in `seq 1 $number_worker`;
do
  eval "$(docker-machine env worker$i)"
  docker swarm join \
      --token $token \
      $ip_leader1:2377
done
