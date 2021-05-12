#!/bin/bash

source ./conf/settings.env

filecount=`cat /etc/security/limits.d/appdynamics.conf | grep $USER | wc -l`
if [[ $filecount == 0  ]]
then
    echo $USER soft nofile 96000 > /etc/security/limits.d/appdynamics.conf
    echo $USER hard nofile 96000 >> /etc/security/limits.d/appdynamics.conf
    echo $USER soft nproc 8192 >> /etc/security/limits.d/appdynamics.conf
    echo $USER hard nproc 8192 >> /etc/security/limits.d/appdynamics.conf
    echo $USER soft memlock unlimited >> /etc/security/limits.d/appdynamics.conf
    echo $USER hard memlock unlimited >> /etc/security/limits.d/appdynamics.conf
fi

swapoff -a
filecount=`cat /etc/fstab | grep \#/dev/mapper/centos-swap | wc -l`
if [[ $filecount == 0  ]]
then
    sed -i "s|/dev/mapper/centos-swap swap|#/dev/mapper/centos-swap swap|g" /etc/fstab
fi

filecount=`cat /etc/sysctl.conf | grep vm.max_map_count | wc -l`
if [[ $filecount == 0  ]]
then
    echo vm.max_map_count=262144 >> /etc/sysctl.conf
fi

echo ""
echo "==> Installing requirements"
echo "yum updating"
# yum update -y -q
echo "yum installing packages"
# yum install -y -q libaio numactl tzdata ncurses-libs-5.* net-tools fontconfig glibc jq git unzip
