#!/bin/bash

WG_IF_ADDRESS=""
WG_PEER_ENDPOINT_ADDRESS=""
WG_PEER_PUBLIC_KEY=""
WG_PEER_ALLOWED_IPS=""

SECRET_STORAGE=""

docker stop wireguard-site-connector
docker rm wireguard-site-connector

docker build -t wireguard-site-connector .

docker run -d --name wireguard-site-connector \
    --restart unless-stopped \
    --network host \
    --cap-add=NET_ADMIN --cap-add=SYS_ADMIN --privileged \
    -v ${SECRET_STORAGE}:/etc/wireguard-secrets \
    -e WG_IF_ADDRESS="$WG_IF_ADDRESS" \
    -e WG_PEER_ENDPOINT_ADDRESS="$WG_PEER_ENDPOINT_ADDRESS" \
    -e WG_PEER_PUBLIC_KEY="$WG_PEER_PUBLIC_KEY" \
    -e WG_PEER_ALLOWED_IPS="$WG_PEER_ALLOWED_IPS" \
    wireguard-site-connector
