#!/bin/bash

source ../conf/settings.env

if [[ `cat /etc/security/limits.conf | grep $USER_NAME | wc -l` == 0  ]];
then
    echo $USER_NAME soft nofile 96000 >> /etc/security/limits.conf
    echo $USER_NAME hard nofile 96000 >> /etc/security/limits.conf
    echo $USER_NAME soft nproc 8192 >> /etc/security/limits.conf
    echo $USER_NAME hard nproc 8192 >> /etc/security/limits.conf
    echo $USER_NAME soft memlock unlimited >> /etc/security/limits.conf
    echo $USER_NAME hard memlock unlimited >> /etc/security/limits.conf
fi

swapoff -a
if [[ `cat /etc/fstab | grep \#/dev/mapper/centos-swap | wc -l` == 0  ]];
then
    sed -i "s|/dev/mapper/centos-swap swap|#/dev/mapper/centos-swap swap|g" /etc/fstab
fi

if [[ `cat /etc/sysctl.conf | grep vm.max_map_count | wc -l` == 0  ]];
then
    echo vm.max_map_count=262144 >> /etc/sysctl.conf
fi

if [[ ! -f  "/etc/profile.d/my-custom.lang.sh" ]];
then
    echo export LANG=en_US.UTF-8 > /etc/profile.d/my-custom.lang.sh
    echo export LANGUAGE=en_US.UTF-8 >> /etc/profile.d/my-custom.lang.sh
    echo export LC_COLLATE=C >> /etc/profile.d/my-custom.lang.sh
    echo export LC_CTYPE=en_US.UTF-8 >> /etc/profile.d/my-custom.lang.sh
fi
source /etc/profile.d/my-custom.lang.sh

if [ $1 == false ];
then
    echo ""
    echo "==> Installing requirements"
    echo "yum updating"
    yum update -y -q
    echo "yum complete transaction"
    yum-complete-transaction --cleanup-only -q
    echo "yum installing packages"
    yum -y -q install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    yum install -y -q libaio numactl tzdata ncurses-libs-5.* net-tools fontconfig jq git unzip
fi