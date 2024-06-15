#!/bin/bash

if [[ ! -f /root/easyrsa3 ]]
then
    mkdir -p /etc/openvpn/server/{keys,logs,ccd}
    mkdir -p /root/easyrsa3 
    cp -r /usr/share/easy-rsa/* /root/easyrsa3
fi

if [[ ! -f /etc/openvpn/server ]]
then
    mkdir -p /etc/openvpn/server/{keys,logs,ccd}
    for proto in tcp udp;
    do
        ln -sf /etc/init.d/openvpn /etc/init.d/openvpn.${proto}
        echo "cfgdir=/etc/openvpn/server/" >> /etc/conf.d/openvpn.${proto}
        echo "cfgfile=/etc/openvpn/server/server-${proto}.conf" >> /etc/conf.d/openvpn.${proto}
        rc-update add openvpn.${proto} default
    done
fi

/root/generate.sh  \
&& exec /sbin/init