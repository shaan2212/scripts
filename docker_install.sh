#!/bin/bash
tempfile=/tmp/docker.temp
#Verify if the user is running as ROOT
echo -e "############ Verifying User ############"
if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi
echo -e "############ ROOT Account Verified ############"
#Enabling Proxy
echo -e "############Setting Environment...############"
export http_proxy=http://168.162.240.81:8080
export https_proxy=https://168.162.240.81:8080
echo -e "############ Creating YUM Repositories... ############"
if [ ! -f /etc/yum.repos.d/centos.repo ]; then
touch /etc/yum.repos.d/centos.repo
chmod 644 /etc/yum.repos.d/centos.repo
#Creating centos repo
cat <<EOF >> /etc/yum.repos.d/centos.repo
[centos]
name=centos repo
baseurl=http://vault.centos.org/centos/7.4.1708/extras/x86_64/
gpgcheck=0
enabled=1
proxy=http://168.162.240.81:8080
EOF
echo -e "Centos Repo Created"
fi

if [ ! -f /etc/yum.repos.d/centos_extra.repo ]; then
touch /etc/yum.repos.d/centos_extra.repo
chmod 644 /etc/yum.repos.d/centos_extra.repo
#Creating centos_extra repo
cat <<EOF >> /etc/yum.repos.d/centos_extra.repo
[centos_exta]
name=Extra Packages for Centos 7
baseurl=http://mirror.centos.org/centos/7/extras/x86_64/
gpgcheck=0
enabled=1
proxy=http://168.162.240.81:8080
EOF
echo -e "Centos Extended Repo Created"
fi

echo -e "############ Installing Extended Repositories ############"
wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum -y install epel-release-latest-7.noarch.rpm
#Listing Repositories
echo -e "############ Listing enabled Repos ############"
yum clean all
yum repolist
echo -e "############ Installing Required packages ###########"
pkg1=$(rpm -q container-selinux)
[[ ! -z "$pkg1" ]] && echo "$pkg1 already installed!" || yum -y install container-selinux.noarch
pkg2=$(rpm -q yum-utils)
[[ ! -z "$pkg2" ]] && echo "$pkg2 already installed!" || yum -y install yum-utils
pkg3=$(rpm -q device-mapper-persistent-data)
[[ ! -z "$pkg3" ]] && echo "$pkg3 already installed!" || yum -y install device-mapper-persistent-data
pkg4=$(rpm -q lvm2)
[[ ! -z "$pkg4" ]] && echo "$pkg4 already installed!" || yum -y install lvm2
echo -e "############ Adding Docker Repo ############"
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
echo -e "############ Installing Docker Community Edition ############"
yum -y install docker-ce docker-ce-cli containerd.io
echo -e "############ Installing Docker Compose ############"
curl -L https://github.com/docker/compose/releases/download/1.25.4/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
unset https_proxy
echo -e "############ Congratulations! docker-ce and docker-compose installed Successfully ############"
echo -e "############ Starting Docker services ############"
systemctl daemon-reload
service docker restart
systemctl enable docker
echo -e "############ Testing Docker service ############"
docker version
#Get mail ID
echo -e "Please enter your FIS email ID to get Installation status"
read mail
echo -e "########## Collecting Application Status ##########"
echo -e "########## Status of docker on `uname -n` ##########" >> $tempfile
echo -e "########## Application Installation status ##########" >> $tempfile
echo -e "`rpm -qi docker-ce`" >> $tempfile
echo -e "`docker info`" >> $tempfile
echo -e "########## Application Run status ##########" >> $tempfile
echo -e "`systemctl status docker.service`" >> $tempfile
echo -e "########## Sending Mail ##########"
cat $tempfile | mail -S smtp=168.162.246.230 -s "Docker Status from `uname -n`" -v $mail
rm -f $tempfile