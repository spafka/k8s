cat > downloadmaven.sh << EOF
apt install -y wget
wget https://archive.apache.org/dist/maven/maven-3/3.8.2/binaries/apache-maven-3.8.2-bin.tar.gz
tar -zxvf apache-maven-3.8.2-bin.tar.gz -C /usr/local
ln -s /usr/local/apache-maven* /usr/local/maven
echo "\$PATH=\$PATH:/usr/local/maven/bin" >> /etc/profile
source /etc/profile
EOF