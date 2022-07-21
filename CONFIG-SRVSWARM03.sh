#########################################################################################
############################# Install and Config SRVWARM02 ############################## 

echo "################## Editando arquivos de segurança ##################"
sleep 5s
echo "################## Ativndo ssh e negando root loguin ##################"

cp -rp /etc/ssh/sshd_config /etc/ssh/sshd_config-orige

sed -i 's/#PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config

systemctl ensable sshd
systemctl start sshd
systemctl reload sshd

echo "################## Edição de Arquivos de segurança Concluidos ##################"
sleep 5s

echo " ############### Instalando pacores basicos ###############"
yum install wget git vim curl net-tools nfs-utils traceroute tcpdump qemu-guest-agent rsyslog -y
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
	state BACKUP
	interface enp0s3
	virtual_router_id 51
	priority 100
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

" > /Scripts/inicializa.sh

echo " ############### criação do script de inicialização concluido ############### "
sleep 5s

echo " ############### permissão de Execução no diretório ############### "
chmod 577 -R /Scripts

echo " ############### permissão de Execução nos scrpts ############### "
chmod +x /Scripts/inicializa.sh

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

echo " ############### Baixando a Imagem do cAdvisor ############### "
docker pull google/cadvisor

echo " ############### Baixando as Imagens do Portainer ############### "
docker pull portainer/agent
docker pull portainer/portainer

echo " ############### SCRIPT CONCLUIDO COM SUCESSO ############### "
sleep 10s

echo " ############### Recarregando e Iniciando o Script ############### "
systemctl daemon-reload
systemctl enable inicializa.service && systemctl start inicializa.service

echo " ############### Reinicialização do sistema ############### "
init 6