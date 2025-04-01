#!/bin/bash
set -e
HERE="$(dirname "$(readlink -f "${0}")")"
cd "$HERE/easyrsa"
export PATH="/usr/share/easy-rsa:$PATH"
export EASYRSA_CERT_EXPIRE=3650
set +e

if [ -z "${SERVER_HOST}" ]; then
    echo "SERVER_HOST is unset or empty"
    SERVER_HOST=""
    for i in 1 2 3 4 5;
    do
        SERVER_HOST="$(wget -qO - icanhazip.com)"
        [[ "$?" == "0" ]] && break
        sleep 2
    done
    [[ ! "$SERVER_HOST" ]] && echo "Can't determine global IP address!" && exit 8
fi

if [ -z "${SERVER_PORT}" ]; then
    SERVER_PORT="1194"
fi


set -e


render() {
    local IFS=''
    local File="$1"
    while read -r line ; do
        while [[ "$line" =~ (\$\{[a-zA-Z_][a-zA-Z_0-9]*\}) ]] ; do
        local LHS=${BASH_REMATCH[1]}
        local RHS="$(eval echo "\"$LHS\"")"
        line=${line//$LHS/$RHS}
        done
        echo "$line"
    done < $File
}

build_pki() {
    easyrsa init-pki
    easyrsa gen-dh
    EASYRSA_BATCH=1 EASYRSA_REQ_CN="ovpn-lan CA" easyrsa build-ca nopass
    EASYRSA_BATCH=1 easyrsa build-server-full "server" nopass
    easyrsa gen-crl
    openvpn --genkey secret ./pki/tls-crypt.key
}

copy_keys() {
    cp ./pki/ca.crt /etc/openvpn/keys/ca.crt
    cp ./pki/dh.pem /etc/openvpn/keys/dh.pem
    cp ./pki/issued/server.crt /etc/openvpn/keys/server.crt
    cp ./pki/private/server.key /etc/openvpn/keys/server.key
    cp ./pki/crl.pem /etc/openvpn/keys/crl.pem
    cp ./pki/tls-crypt.key /etc/openvpn/keys/tls-crypt.key
}

if [ -z "$( ls -A './pki/' )" ]; then
    echo "./pki/ is empty. Re-create"
    build_pki
fi

if [[ ! -f "/etc/openvpn/keys/ca.crt" ]] && \
   [[ ! -f "/etc/openvpn/keys/dh.pem" ]] && \
   [[ ! -f "/etc/openvpn/keys/crl.pem" ]] && \
   [[ ! -f "/etc/openvpn/keys/tls-crypt.key" ]] && \
   [[ ! -f "/etc/openvpn/keys/server.crt" ]] && \
   [[ ! -f "/etc/openvpn/keys/server.key" ]]
then
    copy_keys
fi


create_client() {
    EASYRSA_BATCH=1 easyrsa build-client-full "$1" nopass
    CA_CERT=$(grep -A 999 'BEGIN CERTIFICATE' -- "pki/ca.crt")
    CLIENT_CERT=$(grep -A 999 'BEGIN CERTIFICATE' -- "pki/issued/$1.crt")
    CLIENT_KEY=$(cat -- "pki/private/$1.key")
    CLIENT_TLS_CRYPT=$(grep -v '^#' -- "pki/tls-crypt.key")
    if [ ! "$CA_CERT" ] || [ ! "$CLIENT_CERT" ] || [ ! "$CLIENT_KEY" ]
    then
            echo "Can't load client keys!"
            exit 7
    fi
    render "/etc/openvpn/client.conf" > "$1.ovpn"
}
revoke_client(){
   EASYRSA_BATCH=1 easyrsa revoke $1
   easyrsa gen-crl
   copy_keys
   killall -SIGHUP openvpn
}
list-client(){
    ls -1 ./pki/issued/
}
status_client(){
    cat /etc/openvpn/logs/status.log
}

cmd="$1"
[ -n "$1" ] && shift # scrape off command
case "$cmd" in
	adduser)
		create_client "$@"
		;;
    deluser)
		revoke_client "$@"
		;;
    list-client)
		list-client
		;;
    status)
		status_client
		;;
	*)
		;;
esac