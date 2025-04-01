#!/bin/bash

if [[ ! -f /root/easyrsa ]]
then
    mkdir -pv /root/easyrsa
fi

if [[ ! -f /etc/openvpn/ ]]
then
    mkdir -pv /etc/openvpn/{keys,logs,ccd}
fi

/root/generate.sh && openvpn --config /etc/openvpn/server.conf