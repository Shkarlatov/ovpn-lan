FROM alpine:latest
RUN apk add --no-cache bash openvpn openvpn-openrc easy-rsa curl openrc
COPY ./init.sh /
COPY ./templates/ /root/templates
COPY ./generate.sh /root
COPY ./openvpn/ /etc/openvpn
ENTRYPOINT ["/init.sh"]