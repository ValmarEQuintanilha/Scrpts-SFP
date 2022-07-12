#########################################################################################
############################# Install and Config SRVWARM01 ############################## 
echo "################## Editando arquivos ##################"
sleep 5
echo "################## Ativndo ssh negando root loguin ##################"

cp -rp /etc/ssh/sshd_config /etc/ssh/sshd_config-orige

sed -i 's/#PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config

systemctl ensable sshd
systemctl start sshd
systemctl reload sshd

echo "################## Edição de Arquivos Concluidos ##################"
sleep 5

echo " ############### Instalando pacores basicos ###############"
yum install wget git vim htop curl net-tools nfs-utils traceroute tcpdump qemu-guest-agent rsyslog -y
yum update -y

echo " ############### Instalando pacores basicos concluido ############### "
sleep 2s

echo " ############### Desabilitando Firewall ############### "
systemctl stop firewalld && systemctl disable firewalld

echo " ############### Desabilitando Firewall concluido ############### "
sleep 3s

echo " ############### instalando KeepAlived ############### "
yum install keepalived -y

echo " ############### renomeando arquivos de configurações ############### "
mv /etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf-orige

echo " ############### criando arquivo com as configurações do keepalivd ############### "
echo "
## CONFIG DO KEEPALIVD
! Configuration File for keepalived

vrrp_instance VIP_181.10 {
	state BACKUP
	interface enp0s3
	virtual_router_id 51
	priority 110
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
sleep 3s

echo " ############### Instalando Docker ############### "
sudo yum check-update
curl -fsSL https://get.docker.com/ | sh
systemctl enable docker && systemctl restart docker

echo " ############### Instalando Docker concluido ############### "
sleep 3s

echo " ############### Instalando Docker Compose ############### "
yum install epel-release -y && yum update -y && yum install python-pip -y
pip install docker-compose
yum install docker-compose -y && yum upgrade python*
yum update -y

echo " ############### Instalando Docker-Compose concluido ############### "
sleep 3s

echo " ############### Criando diretórios de scripts ############### "
mkdir /Scripts
chmod 577 -R /Scripts

echo " ############### Criando diretórios de scripts concluido ############### "
sleep 3s

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

echo " ############### criando scripta de inicialização concluido ############### "
sleep 3s

echo " ############### Criar script Porteiner.yml no servidor principal pra inicialização automatica ############### "
#### Conteudo do script portainer.yml
## Conteudo

echo "
version: '3.2'
services:
  agent:
    image: portainer/agent
    environment:
      # REQUIRED: Should be equal to the service name prefixed by "tasks." when
      # deployed inside an overlay network
      AGENT_CLUSTER_ADDR: tasks.agent
      # AGENT_PORT: 9001
      # LOG_LEVEL: debug
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /var/lib/docker/volumes:/var/lib/docker/volumes
#    networks:
#      - agent_network
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
#    networks:
#      - agent_network
    deploy:
      mode: replicated
      replicas: 2
      placement:
#        constraints: [node.role == manager]
        constraints:
          - node.hostname == SRVSWARM01
          - node.hostname == SRVSWARM02
 

volumes:
  portainer_data:
    driver: local
    driver_opts:
      type: nfs
      o: nfsvers=4,addr=192.168.181.21,rw
      device: ":/STG/PORTAINER"

#networks:
#  agent_network:
#    driver: overlay
#    attachable: true

" > /Scripts/portainer.yml

echo " ############### Criar script Porteiner.yml concluido ############### "
sleep 3s

echo " ############### permissão de Execução no diretório ############### "
chmod 577 -R /Scripts

echo " ############### permissão de Execução nos scrpts ############### "
chmod +x /Scripts/inicializa.sh
chmod +x /Scripts/portainer.yml

echo " ############### permissão de Execução no diretório concluido ############### "
sleep 3s

echo " ############### Criando Serviço de Inicialização e ativa ele no boot ############### "
## Conteudo

echo "
[Unit]
Description=Script de inicialização personalizado

[Service]
ExecStart=/Scripts/inicializa.sh

[Install]
WantedBy=default.target
	
" > /etc/systemd/system/inicializa.service

chmod +x /etc/systemd/system/inicializa.service


echo " ############### Criando Serviço de Inicialização concluido ############### "
sleep 3s

echo " ############### Ativando o SWARM ############### "
docker swarm init --advertise-addr 192.168.181.10

echo " ############### Criação da rede INGRESS-OVERLAY ############### "
docker network create -d overlay --opt encrypted --subnet 10.255.0.0/16 INGRESS-OVERLAY

echo " ############### Baixando a Imagem do cAdvisor ############### "
docker pull google/cadvisor

echo " ############### SCRIPT CONCLUIDO COM SUCESSO ############### "
sleep 10s

echo " ############### Recarregando e Iniciando o Script ############### "
systemctl daemon-reload
systemctl enable inicializa.service && systemctl start inicializa.service

echo " ############### Listando toquem Manager ############### "
docker swarm join-token manager

echo " ############### Copie o comando para add os servidores ao CLUTSER ############### "
sleep 100

## Reiniciando as VMs
#init 6