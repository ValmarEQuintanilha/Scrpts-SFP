###############################################################################################################
######################################### Install and Config SRVNFS01 ######################################### 

echo "################## Editando arquivos ##################"
sleep 5s
echo "################## Ativndo ssh negando root loguin ##################"

cp -rp /etc/ssh/sshd_config /etc/ssh/sshd_config-orige

sed -i 's/#PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config

systemctl ensable sshd
systemctl start sshd
systemctl reload sshd

echo "################## Edição de Arquivos Concluidos ##################"
sleep 5s

echo " ############### Instalando pacores basicos ############### "

yum install wget git vim curl net-tools nfs-utils traceroute tcpdump qemu-guest-agent rsyslog -y
yum update -y

echo " ############### Instalando pacores basicos Concluidos ############### "
sleep 5s

echo " ############### Desabilitando Firewall ############### "
systemctl stop firewalld && systemctl disable firewalld

echo " ############### Desabilitando Firewall concluido ############### "
sleep 5s

echo " ############### Instalando NFS ############### "
yum install nfs-utils -y

echo " ############### renomeando arquivos de configurações ############### "
mv /etc/sysconfig/nfs /etc/sysconfig/nfs-orige

echo "Editando Configurações do serviço NFS"

echo "
#LOCKDARG=
# TCP port rpc.lockd should listen on.
#LOCKD_TCPPORT=32803
# UDP port rpc.lockd should listen on.
#LOCKD_UDPPORT=32769
RPCNFSDARGS="-N 2 -N 3 -U"
RPCNFSDCOUNT=256
#NFSD_V4_GRACE=90
#NFSD_V4_LEASE=90
RPCMOUNTDOPTS=""
#MOUNTD_PORT=892
STATDARG=""
#STATD_PORT=662
#STATD_OUTGOING_PORT=2020
#STATD_HA_CALLOUT="/usr/local/bin/foo"
SMNOTIFYARGS=""
RPCIDMAPDARGS=""
RPCGSSDARGS=""
GSS_USE_PROXY="yes"
BLKMAPDARGS=""

" > /etc/sysconfig/nfs

systemctl start nfs-server && systemctl enable nfs-server

echo " ############### Instalação do NFS Concluido ############### "
sleep 5s

echo " ############### Criando diretórios compartilhados do NFS ############### "
cd\

mkdir /STG
mkdir /STG/PORTAINER
mkdir /STG/PORTAINER/NGINX
mkdir /STG/PORTAINER/NGINX/html
mkdir /STG/PORTAINER/NGINX/error_log
mkdir /STG/PORTAINER/KAFKA
mkdir /STG/PORTAINER/KAFKA/id1
mkdir /STG/PORTAINER/KAFKA/id2
mkdir /STG/PORTAINER/KAFKA/id3
mkdir /STG/PORTAINER/ZOOKEEPER
mkdir /STG/PORTAINER/ZOOKEEPER/id1
mkdir /STG/PORTAINER/ZOOKEEPER/id2
mkdir /STG/PORTAINER/ZOOKEEPER/id3

echo " ############### Definindo permissões nos diretórios ############### "
chmod 777 -R /STG

echo " ############### Diretórios Concluidos ############### "
sleep 5s

echo " ############### Criando Arquivos de configuração do ambiente ############### "
sleep 2s
echo " ############### Criando Arquivos do NGINX para teste ############### "

echo "
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Teste NGINX OK</title>
</head>
<body>
 <h1> Teste NGINX OK </h1>
</body>
</html>

" > /STG/PORTAINER/NGINX/html/index.html

echo " ############### permissão de Execução nos Aquivos ############### "
chmod +x /STG/PORTAINER/NGINX/html/index.html

echo " ############### permissão de Execução no Diretório ############### "
chmod 577 -R /STG/PORTAINER/NGINX/html

echo " ############### Arquivos de Configuração Criados ############### "
sleep 5s

echo " ############### Adicionado Compartilhamentos ############### "
echo "
/STG/PORTAINER 192.168.181.0/24(rw,sync,no_root_squash,no_subtree_check)

" > /etc/exports

exportfs -a

echo " ############### Compartilhamentos Concluidos ############### "
sleep 5s

echo " ############### COMPARTILHAMENTOS ATIVOS ############### "
showmount -e 127.0.0.1
sleep 100s

echo " ############### Reinicialização do sistema ############### "
init 6
