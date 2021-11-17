#!/bin/bash
default_version="6.2.6"
default_port=6379
default_password="supOS"
default_maxmemory="1GB"

## analysis option
## version
## redisNode port
## redisNode password

version=$default_version
port=$default_port
password=$default_password
maxmemory=$default_maxmemory

echo "------option info------"
while getopts "v:p:a:m:" opt; do
    case $opt in
        v)
        echo "option version=$OPTARG"
        version=$OPTARG
        ;;
        p)
        echo "option port=$OPTARG"
        port=$OPTARG
        ;;
        a)
        echo "option password=$OPTARG"
        password=$OPTARG
        ;;
        m)
        echo "option maxmemory=$OPTARG"
        maxmemory=$OPTARG
        ;;
    esac
done

echo "------redis info------"
echo "redis‘s version=${version}"
echo "node‘s port=${port}"
echo "node‘s password=${password}"
echo "node‘s maxmemory=${maxmemory}"

install_package_path="$(pwd)"
echo "install package path ${install_package_path}"
# redis_path="/usr/local/redis/"
redis_path=${install_package_path}
redis_folder="redis-${version}"
redis_full_folder=${redis_path}/${redis_folder}
redis_filename="redis-${version}.tar.gz"
redis_local_file=${redis_path}/${redis_filename}
redis_server_file=${redis_full_folder}/src/redis-server
redis_download_url="https://download.redis.io/releases/${redis_filename}"
## redis conf file
redis_etc_path="${redis_path}/etc/${port}"
redis_logs_path="${redis_path}/logs/${port}"
redis_data_path="${redis_path}/data/${port}"
redis_conf_filename="redis-cluster-${port}.conf"
redis_conf_file="${redis_etc_path}/${redis_conf_filename}"
if [ ! -d ${redis_etc_path} ]
then
    echo "folder ${redis_etc_path} is not exist."
    echo "folder ${redis_etc_path} is not exist."
    mkdir -p ${redis_etc_path}
    echo "create folder ${redis_etc_path} success."
fi
if [ ! -d ${redis_logs_path} ]
then
    echo "folder ${redis_logs_path} is not exist."
    echo "folder ${redis_logs_path} is not exist."
    mkdir -p ${redis_logs_path}
    echo "create folder ${redis_logs_path} success."
fi
if [ ! -d ${redis_data_path} ]
then
    echo "folder ${redis_data_path} is not exist."
    echo "folder ${redis_data_path} is not exist."
    mkdir -p ${redis_data_path}
    echo "create folder ${redis_data_path} success."
fi
## copy redis cluster conf
if [ ! -f ${redis_conf_file} ]
then
    echo "cp redis.conf to ${redis_conf_file}"
    cp ${install_package_path}/redis-cluster-param.conf ${redis_conf_file}
    echo "sed -i s#{port}#${port}# ${redis_conf_file}"
    sed -i "s#{port}#${port}#" ${redis_conf_file}
    echo  "sed -i s#{redis_path}#${redis_path}# ${redis_conf_file}"
    sed -i "s#{redis_path}#${redis_path}#" ${redis_conf_file}
    echo  "sed -i s#{password}#${password}# ${redis_conf_file}"
    sed -i "s#{password}#${password}#" ${redis_conf_file}
    echo  "sed -i s#{maxmemory}#${maxmemory}# ${redis_conf_file}"
    sed -i "s#{maxmemory}#${maxmemory}#" ${redis_conf_file}
fi
## install redis tool
# echo "install gcc & tcl & make begin.."
apt-get -y install gcc tcl make wget curl
# echo "install gcc & tcl & make end."
## prepare redis image
if [ ! -d ${redis_path} ]
then
    # prepare redis path.
    # if not exist, to create folder.
    echo "folder ${redis_path} is not exist."
    echo "create folder ${redis_path} begin.."
    mkdir -p ${redis_path}
    echo "create folder ${redis_path} success."
fi
if [ ! -f ${redis_local_file} ]
then
    if [ ! -f ${install_package_path}/${redis_filename} ]
        echo "local disk has not redis image [${redis_local_file}] ."
        echo "download redis image from remote [${redis_download_url}] begin.."
        curl -o ${redis_local_file} ${redis_download_url}
        echo "download redis image from remote [${redis_download_url}] success."
    then
        cp ${install_package_path}/${redis_filename} ${redis_local_file}
    fi
else
    echo "local disk has redis image [${redis_local_file}] ."
fi
## unzip redis image
if [ ! -d ${redis_full_folder} ]
then
    cd ${redis_path}
    tar -zxvf ${redis_filename}
fi
## make redis
if [ ! -f ${redis_server_file} ]
then
    echo "compiler redis image."
    cd ${redis_full_folder}
    make -j4 && make install
fi
## redis server start
echo "start redis[${port}]"
echo "${redis_server_file} ${redis_conf_file}"
${redis_server_file} ${redis_conf_file}
echo "start redis[${port}] success."
