#!/bin/bash

trap cleanup TERM EXIT KILL

IF_DEFAULT="$(ip route | grep default | awk '{print $5}')"
OLD_IP_FORWARD="$(sysctl net.ipv4.ip_forward -b)"
OLD_PROXY_ARP="$(sysctl net.ipv4.conf.all.proxy_arp -b)"

# shutdown function - clean up on docker stop
cleanup () {
    wg-quick down wg0
    iptables -D FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS  --clamp-mss-to-pmtu
    iptables -D FORWARD -i $IF_DEFAULT -o wg0 -j ACCEPT
    iptables -D FORWARD -o $IF_DEFAULT -i wg0 -j ACCEPT

    sysctl -w net.ipv4.ip_forward=${OLD_IP_FORWARD}
    sysctl -w net.ipv4.conf.all.proxy_arp=${OLD_PROXY_ARP}
}

postup () {
    sysctl -w net.ipv4.ip_forward=1
    sysctl -w net.ipv4.conf.all.proxy_arp=1

    iptables -I FORWARD 1 -p tcp --tcp-flags SYN,RST SYN -j TCPMSS  --clamp-mss-to-pmtu
    iptables -I FORWARD 2 -i $IF_DEFAULT -o wg0 -j ACCEPT
    iptables -I FORWARD 3 -o $IF_DEFAULT -i wg0 -j ACCEPT
}

# generate private key if necessary
cd /etc/wireguard-secrets
if [ ! -f private.key ]; then 
    echo "no private key found; generating..."
    umask 077
    wg genkey > private.key
    umask 022
fi
cp private.key /etc/wireguard

# gen and note pubkey
cd /etc/wireguard
cat private.key | wg pubkey > public.key
echo "*****************"
echo -n "Public key: " && cat public.key
echo "*****************"
echo; echo; echo;

# build the conf file
cat templates/wg0.conf | \
    sed -e "s#<wg_private_key>#$(cat /etc/wireguard/private.key)#" | \
    sed -e "s#<wg_peer_public_key>#$WG_PEER_PUBLIC_KEY#" | \
    sed -e "s#<wg_if_address>#$WG_IF_ADDRESS#" | \
    sed -e "s#<wg_peer_public_key>#$WG_PEER_PUBLIC_KEY#" | \
    sed -e "s#<wg_peer_endpoint_address>#$WG_PEER_ENDPOINT_ADDRESS#" | \
    sed -e "s#<wg_peer_allowed_ips>#$WG_PEER_ALLOWED_IPS#" | \
    cat > wg0.conf

wg-quick up wg0
postup

tail -f /dev/null &
wait
