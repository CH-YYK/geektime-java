# Java Application


# jdk setup
mkdir /usr/local/hero
tar -zxvf /root/jdk-8u261-linux-x64.tar.gz -C /usr/local/hero
echo 'export JAVA_HOME=/usr/local/hero/jdk1.8.0_261' >> /etc/profile
echo 'export PATH=$PATH:$JAVA_HOME/bin' >> /etc/profile
source /etc/profile

## Install Application: path <ip_addr:9001>/spu/goods/10000023827800
chmod +x ./startup.sh
./startup.sh

## docker setup
sudo yum install -y yum-utils
sudo yum-config-manager \
     --add-repo \
     https://download.docker.com/linux/centos/docker-ce.repo

sudo yum install docker-ce docker-ce-cli containerd.io docker-compose-plugin
systemctl start docker

## MySQL setup
docker pull mysql:5.7
docker run -di --name=cmysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=admin mysql:5.7
# docker update --restart=always <container_id>
# connect to mysql and create a new schema, write in data by executing SQL

## FluxDB
docker pull influxdb:1.8
docker run -d --name influxdb -p 8086:8086 -p 8083:8083 influxdb:1.8
# -i: interactive, -t: pseudo-tty
docker exec -it influxdb /bin/bash
# fluxQL
#   $influx
#   > create database jmeter
#   > show databases
#   > use jmeter
# docker update --restart=always <container_id>

## Grafana
docker pull grafana/grafana
docker run -d --name grafana -p 3000:3000 grafana/grafana
# http://<public ip addr>:3000/login

## node exporter <:9100> (part of prometheus)
wget -c https://github.com/prometheus/node_exporter/releases/download/v0.18.1/node_exporter-0.18.1.linux-amd64.tar.gz

mkdir /usr/local/hero/
tar zxvf node_exporter-0.18.1.linux-amd64.tar.gz -C /usr/local/hero/
cd /usr/local/hero/node_exporter-0.18.1.linux-amd64

nohup ./node_exporter > node.log 2>&1 &

## prometheus <:9090>
wget -c https://github.com/prometheus/prometheus/releases/download/v2.15.1/prometheus-2.15.1.linux-amd64.tar.gz

mkdir /usr/local/hero/
tar zxvf prometheus-2.15.1.linux-amd64.tar.gz -C /usr/local/hero/
cd /usr/local/hero/prometheus-2.15.1.linux-amd64

echo \
"
  - job_name: 'hero-Linux'
    static_configs:
    - targets: ['192.168.0.1:9100','192.168.0.2:9100','192.168.0.3:9100']" \
         >> prometheus.yml

nohup ./prometheus > prometheus.log 2>&1 &

## JMeter
wget -c https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-5.4.1.tgz

tar -zxvf apache-jmeter-5.4.1.tgz -C /usr/local/hero
cd /usr/local/hero/apache-jmeter-5.4.1
echo \
'export JMETER_HOME=/usr/local/hero/apache-jmeter-5.4.1
export PATH=$JMETER_HOME/bin:$PATH' >> /etc/profile
source /etc/profile

### install plugins: CMDRunner, PluginManager
cd lib/
curl -O https://repo1.maven.org/maven2/kg/apc/cmdrunner/2.2.1/cmdrunner-2.2.1.jar
cd ext/
curl -O https://repo1.maven.org/maven2/kg/apc/jmeter-plugins-manager/1.6/jmeter-plugins-manager-1.6.jar
cd ../
java -jar cmdrunner-2.2.1.jar --tool org.jmeterplugins.repository.PluginManagerCMD install jpgc-graphs-basic,jpgc-graphs-additional,jpgc-perfmon
### running jmeter without GUI
cd

# jmeter -n -t 01-stress-testing-example.jmx -l 01-stress-testing-example.jtl -e -o ./01-stress-testing-example-html
# jmeter -n -t <path/to/jmx/file> -l <path/to/jtl> -e -o <path/to/html>
jmeter -n -t sample-stress-testing.jmx -l sample-stress-testing.jtl -e -o ./sample-stress-testing-html


