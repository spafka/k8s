mkdir -p 700{1..6}/data
export REDIS_IP=192.168.32.129

cat > redis.yaml << EOF
version: '3'

services:
  redis1:
    container_name: redis1
    image: publicisworldwide/redis-cluster
    network_mode: host
    restart: always
    volumes:
      - ./7001/data:/data
    environment:
      - REDIS_PORT=7001

  redis2:
    container_name: redis2
    image: publicisworldwide/redis-cluster
    network_mode: host
    restart: always
    volumes:
      - ./7002/data:/data
    environment:
      - REDIS_PORT=7002

  redis3:
    container_name: redis3
    image: publicisworldwide/redis-cluster
    network_mode: host
    restart: always
    volumes:
      - ./7003/data:/data
    environment:
      - REDIS_PORT=7003

  redis4:
    container_name: redis4
    image: publicisworldwide/redis-cluster
    network_mode: host
    restart: always
    volumes:
      - ./7004/data:/data
    environment:
      - REDIS_PORT=7004

  redis5:
    container_name: redis5
    image: publicisworldwide/redis-cluster
    network_mode: host
    restart: always
    volumes:
      - ./7005/data:/data
    environment:
      - REDIS_PORT=7005

  redis6:
    container_name: redis6
    image: publicisworldwide/redis-cluster
    network_mode: host
    restart: always
    volumes:
      - ./7006/data:/data
    environment:
      - REDIS_PORT=7006
EOF

docker-compose -f  redis.yaml up -d


sleep 30

docker exec -ti redis1 redis-cli --cluster create $REDIS_IP:7001 $REDIS_IP:7002 $REDIS_IP:7003 $REDIS_IP:7004 $REDIS_IP:7005 $REDIS_IP:7006 --cluster-replicas 1