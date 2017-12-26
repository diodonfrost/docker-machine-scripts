# Set number of worker ans leader
number_leader=3
number_worker=2

### Deploy virtual machine leader

for i in `seq 1 $number_leader`;
do
  docker-machine create \
        --engine-env 'DOCKER_OPTS="-H unix:///var/run/docker.sock"' \
        --driver virtualbox \
        --virtualbox-memory 2048 \
        --virtualbox-cpu-count 2 \
        leader$i
done

### Deploy virtual machine worker

for i in `seq 1 $number_worker`;
do
  docker-machine create \
        --engine-env 'DOCKER_OPTS="-H unix:///var/run/docker.sock"' \
        --driver virtualbox \
        --virtualbox-memory 2048 \
        --virtualbox-cpu-count 2 \
        worker$i
done

### Retrieve leader information

ip_leader1=$(docker-machine ip leader1)

# Start docker swarm node master
eval "$(docker-machine env leader1)"

docker swarm init \
      --listen-addr $ip_leader1 \
      --advertise-addr $ip_leader1

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

