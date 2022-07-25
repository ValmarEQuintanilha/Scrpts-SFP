#########################################################################################
############################# Install and Config SRVWARM01 ############################## 

echo "################## Editando arquivos de segurança ##################"
sleep 5s
echo "################## Ativndo ssh e negando root loguin ##################"

cp -rp /etc/ssh/sshd_config /etc/ssh/sshd_config-orige

sed -i 's/#PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config

systemctl ensable sshd
systemctl start sshd
systemctl reload sshd

echo "################## Edição de Arquivos Concluidos ##################"
sleep 5s

echo "################## Adicionando repositórios ##################"

rpm -Uvh http://repo.zabbix.com/zabbix/3.0/rhel/7/x86_64/zabbix-release-3.0-1.el7.noarch.rpm

echo " ############### Instalando pacores basicos ############### "
sleep 5s

yum install wget git vim htop curl net-tools nfs-utils traceroute tcpdump qemu-guest-agent rsyslog zabbix-agent -y
yum update -y

echo " ############### Instalando pacores basicos concluido ############### "
sleep 5s

echo " ############### Desabilitando Firewall ############### "
systemctl stop firewalld && systemctl disable firewalld

echo " ############### Desabilitando Firewall concluido ############### "
sleep 5s

echo " ############### instalando KeepAlived ############### "
yum install keepalived -y

echo " ############### fazendo BKP dos  arquivos de configurações ############### "
mv /etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf-orige

echo " ############### criando arquivo com as configurações do keepalivd ############### "
echo "
## CONFIG DO KEEPALIVD
! Configuration File for keepalived

vrrp_instance VIP_181.10 {
	state MASTER
	interface enp0s3
	virtual_router_id 51
	priority 255
	advert_int 1
	authentication {
		auth_type PASS
		auth_pass 123456
	}
	virtual_ipaddress {
		192.168.181.10/24
	}
}

" > /etc/keepalived/keepalived.conf

echo " ############### Ativando serviço do keepalived ############### "
systemctl enable keepalived && systemctl start keepalived

echo " ############### instalação do KeepAlived concluido ############### "
sleep 5s

echo " ############### Instalando Docker ############### "
sudo yum check-update
curl -fsSL https://get.docker.com/ | sh
systemctl enable docker && systemctl restart docker

echo " ############### Instalação do Docker concluido ############### "
sleep 5s

echo " ############### Instalando Docker Compose ############### "
yum install epel-release -y && yum update -y && yum install python-pip -y
pip install docker-compose
yum install docker-compose -y && yum upgrade python*
yum update -y

echo " ############### Instalação do Docker-Compose concluido ############### "
sleep 5s

echo " ############### Criando diretórios de scripts ############### "
mkdir /Scripts
chmod 577 -R /Scripts

echo " ############### Criação do diretório de scripts concluido ############### "
sleep 5s

echo " ############### criando scripta de inicialização ############### "
echo "
#!/bin/bash
##Script-Inicialização
## Remove os contaniser docker cAdvicor e recra eles
docker rm -f cadvisor
## Ativa Container cAdvicer
docker run --volume=/:/rootfs:ro --volume=/var/run:/var/run:ro --volume=/sys:/sys:ro --volume=/var/lib/docker/:/var/lib/docker:ro --volume=/dev/disk/:/dev/disk:ro --publish=8080:8080 --detach=true --name=cadvisor --privileged gcr.io/google-containers/cadvisor:latest
## Obs adicionar apenas no principal
## Ativa Portainer
docker stack deploy --compose-file=/Scripts/portainer.yml portainer

" > /Scripts/inicializa.sh

echo " ############### criação do script de inicialização concluido ############### "
sleep 5s

echo " ############### Criar script Porteiner.yml no servidor principal pra inicialização automatica ############### "

echo "
version: '3.3'
services:
  agent:
    image: portainer/agent
    environment:
      # Obs: Deve ser igual ao nome do serviço prefixado por "tasks". quando
      # implantado dentro de uma rede de sobreposição "overlay network"
      AGENT_CLUSTER_ADDR: tasks.agent
      # AGENT_PORT: 9001
      # LOG_LEVEL: debug
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /var/lib/docker/volumes:/var/lib/docker/volumes
    networks:
      - agent_network
    deploy:
      mode: global
      placement:
        constraints: [node.platform.os == linux]
  
  portainer:
    image: portainer/portainer
    command: -H tcp://tasks.agent:9001 --tlsskipverify
    ports:
      - "9000:9000"
    volumes:
      - portainer_data:/data
    networks:
      - ingress
    deploy:
      mode: replicated
      replicas: 2
      placement:
        constraints: [node.role == manager]
#        constraints:
#        - node.role == manager
#        - node.hostname == SRVSWARM01
#        - node.hostname == SRVSWARM02
      restart_policy:
        condition: on-failure
#	  resources:
#	    limits:
#		  cpus: "0.25"
#		  memory: 64M
#       reservations:
#         cpus: '0.1'
#         memory: 32M
 
#Configurações Gerais
volumes:
  portainer_data:
    driver: local
    driver_opts:
      type: nfs
      o: nfsvers=4,addr=192.168.181.21,rw
      device: ":/STG/PORTAINER"

networks:
  agent_network:
    driver: overlay
    attachable: true
  network-zabbix:
    driver: bridge
    attachable: true
  ingress:
    driver: overlay
    ipam:
      config:
      - subnet: 10.255.0.0/16


" > /Scripts/portainer.yml

echo " ############### Criar script Porteiner.yml concluido ############### "
sleep 5s

echo " ############### permissão de Execução no diretório ############### "
chmod 577 -R /Scripts

echo " ############### permissão de Execução nos scrpts ############### "
chmod +x /Scripts/inicializa.sh
chmod +x /Scripts/portainer.yml

echo " ############### permissões de Execução concluido ############### "
sleep 5s

echo " ############### Criando Serviço de Inicialização e ativa ele no boot ############### "

echo "
[Unit]
Description=Script de inicialização personalizado
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash /Scripts/inicializa.sh
TimeoutStartSec=10

[Install]
WantedBy=default.target

" > /etc/systemd/system/inicializa.service

chmod +x /etc/systemd/system/inicializa.service

echo " ############### Criação do Serviço de Inicialização concluido ############### "
sleep 5s

echo " ############### Ativando o SWARM ############### "
docker swarm init --advertise-addr 192.168.181.10

echo " ############### Criação da rede INGRESS-OVERLAY ############### "
docker network create -d overlay --opt encrypted --subnet 10.255.0.0/16 INGRESS-OVERLAY

echo " ############### Baixando a Imagem do cAdvisor ############### "
docker pull google/cadvisor

echo " ############### Baixando as Imagens do Portainer ############### "
docker pull portainer/agent
docker pull portainer/portainer

echo " ############### Configurando Agente Zabbix ############### "
sleep 3s
mv /etc/zabbix/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf-orige

echo "
PidFile=/var/run/zabbix/zabbix_agentd.pid
LogFile=/var/log/zabbix/zabbix_agentd.log
LogFileSize=0
Server=192.168.181.10
ServerActive=192.168.181.10
Hostname=$(hostname)
Include=/etc/zabbix/zabbix_agentd.d/
# DebugLevel=3
### Option: DebugLevel
#	Specifies debug level:
#	0 - basic information about starting and stopping of Zabbix processes
#	1 - critical information
#	2 - error information
#	3 - warnings
#	4 - for debugging (produces lots of information)
#	5 - extended debugging (produces even more information)


" > /etc/zabbix/zabbix_agentd.conf

systemctl enable zabbix-agent && systemctl start zabbix-agent

echo " ############### Configuração do Agente do Zabbix Concluido ############### "

echo " ############### SCRIPT CONCLUIDO COM SUCESSO ############### "
sleep 10s

echo " ############### Recarregando e Iniciando o Script ############### "
systemctl daemon-reload
systemctl enable inicializa.service && systemctl start inicializa.service

echo " ############### Listando toquem worker ############### "
docker swarm join-token worker

echo " ############### Listando toquem Manager ############### "
docker swarm join-token manager

echo " ############### Copie o comando para add os servidores ao CLUTSER ############### "
sleep 100s

echo " ############### Reinicialização do sistema ############### "
init 6