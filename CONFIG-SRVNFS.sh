###############################################################################################################
######################################### Install and Config SRVNFS01 ######################################### 

echo " ############### Instalando pacores basicos ############### "

yum install wget git vim curl net-tools nfs-utils traceroute tcpdump qemu-guest-agent rsyslog -y
yum update -y

echo " ############### Instalando pacores basicos Concluidos ############### "
sleep 5s

echo " ############### Desabilitando Firewall ############### "
systemctl stop firewalld && systemctl disable firewalld

echo " ############### Desabilitando Firewall concluido ############### "
sleep 3s

echo " ############### Instalando NFS ############### "
yum install nfs-utils -y

echo " ############### renomeando arquivos de configurações ############### "
mv /etc/sysconfig/nfs /etc/sysconfig/nfs-orige

echo "Configuração básica do serviço NFS"

echo "
#LOCKDARG=
# TCP port rpc.lockd should listen on.
#LOCKD_TCPPORT=32803
# UDP port rpc.lockd should listen on.
#LOCKD_UDPPORT=32769
RPCNFSDARGS="-N 2 -N 3 -U" //Limita apenas a versão 4
RPCNFSDCOUNT=64 //N° max de processos
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
mkdir /STG/SRVSWARM
mkdir /STG/PORTAINER

echo " ############### Definindo permissões nos diretórios ############### "
chmod 777 -R /STG

echo " ############### Diretórios Concluidos ############### "
sleep 5s

echo " ############### Adicionado Compartilhamentos ############### "
echo "
/STG/SRVSWARM 192.168.181.0/24(rw,sync,no_root_squash,no_subtree_check)
/STG/PORTAINER 192.168.181.0/24(rw,sync,no_root_squash,no_subtree_check)
" > /etc/exports

exportfs -a

echo " ############### Compartilhamentos Concluidos ############### "
sleep 5s

echo " ############### COMPARTILHAMENTOS ATIVOS ############### "
showmount -e 127.0.0.1

