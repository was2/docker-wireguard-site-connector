FROM ubuntu

RUN apt update && apt -y dist-upgrade
RUN apt install -y --no-install-recommends \ 
                less \
                iproute2 iptables wireguard-tools

COPY wg0.conf.template /etc/wireguard/templates/wg0.conf
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
