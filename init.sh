#!/bin/bash

if [[ ! -f /root/easyrsa ]]
then
    mkdir -pv /root/easyrsa
fi

if [[ ! -f /etc/openvpn/ ]]
then
    mkdir -pv /etc/openvpn/{keys,logs,ccd}
fi

/root/generate.sh

CRON_SCRIPT=/etc/periodic/daily/update-crl
if [[ ! -f "$CRON_SCRIPT" ]]; then
    cat << 'EOF' > "$CRON_SCRIPT"
#!/bin/sh
set -e

/root/generate.sh update-crl
EOF

    chmod +x "$CRON_SCRIPT"
fi
run-parts /etc/periodic/daily

crond -b
exec openvpn --config /etc/openvpn/server.conf
