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
