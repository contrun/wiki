iptables -t nat -N CLASH_LOCAL
iptables -t nat -A CLASH_LOCAL -m owner --uid-owner "$CLASH_USER" -j RETURN
iptables -t nat -A CLASH_LOCAL -m owner --gid-owner "$NOPROXY_GROUP" --suppl-groups -j RETURN || true
iptables -t nat -A CLASH_LOCAL -d 0.0.0.0/8 -j RETURN
iptables -t nat -A CLASH_LOCAL -d 127.0.0.0/8 -j RETURN
iptables -t nat -A CLASH_LOCAL -d 224.0.0.0/4 -j RETURN
iptables -t nat -A CLASH_LOCAL -d 172.16.0.0/12 -j RETURN
iptables -t nat -A CLASH_LOCAL -d 169.254.0.0/16 -j RETURN
iptables -t nat -A CLASH_LOCAL -d 240.0.0.0/4 -j RETURN
iptables -t nat -A CLASH_LOCAL -d 192.168.0.0/16 -j RETURN
iptables -t nat -A CLASH_LOCAL -d 10.0.0.0/8 -j RETURN
iptables -t nat -A CLASH_LOCAL -d 100.64.0.0/10 -j RETURN
iptables -t nat -A CLASH_LOCAL -d 255.255.255.255 -j RETURN
iptables -t nat -A CLASH_LOCAL -p tcp -j REDIRECT --to-ports "$CLASH_REDIRECT_PORT"
iptables -t nat -I OUTPUT -p tcp -j CLASH_LOCAL

iptables -t nat -N CLASH_EXTERNAL
iptables -t nat -A CLASH_EXTERNAL -d 0.0.0.0/8 -j RETURN
iptables -t nat -A CLASH_EXTERNAL -d 127.0.0.0/8 -j RETURN
iptables -t nat -A CLASH_EXTERNAL -d 224.0.0.0/4 -j RETURN
iptables -t nat -A CLASH_EXTERNAL -d 172.16.0.0/12 -j RETURN
iptables -t nat -A CLASH_EXTERNAL -d 169.254.0.0/16 -j RETURN
iptables -t nat -A CLASH_EXTERNAL -d 240.0.0.0/4 -j RETURN
iptables -t nat -A CLASH_EXTERNAL -d 192.168.0.0/16 -j RETURN
iptables -t nat -A CLASH_EXTERNAL -d 10.0.0.0/8 -j RETURN
iptables -t nat -A CLASH_EXTERNAL -d 100.64.0.0/10 -j RETURN
iptables -t nat -A CLASH_EXTERNAL -d 255.255.255.255 -j RETURN
iptables -t nat -A CLASH_EXTERNAL -p tcp -j REDIRECT --to-ports "$CLASH_REDIRECT_PORT"
iptables -t nat -I PREROUTING -p tcp -j CLASH_EXTERNAL
