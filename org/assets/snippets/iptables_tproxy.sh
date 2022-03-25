iptables -t mangle -N CLASH_EXTERNAL
iptables -t mangle -A CLASH_EXTERNAL -d 0.0.0.0/8 -j RETURN
iptables -t mangle -A CLASH_EXTERNAL -d 127.0.0.0/8 -j RETURN
iptables -t mangle -A CLASH_EXTERNAL -d 224.0.0.0/4 -j RETURN
iptables -t mangle -A CLASH_EXTERNAL -d 172.16.0.0/12 -j RETURN
iptables -t mangle -A CLASH_EXTERNAL -d 169.254.0.0/16 -j RETURN
iptables -t mangle -A CLASH_EXTERNAL -d 240.0.0.0/4 -j RETURN
iptables -t mangle -A CLASH_EXTERNAL -d 192.168.0.0/16 -j RETURN
iptables -t mangle -A CLASH_EXTERNAL -d 10.0.0.0/8 -j RETURN
iptables -t mangle -A CLASH_EXTERNAL -d 100.64.0.0/10 -j RETURN
iptables -t mangle -A CLASH_EXTERNAL -d 255.255.255.255 -j RETURN
iptables -t mangle -A CLASH_EXTERNAL -p tcp -j TPROXY --on-port "$CLASH_TPROXY_PORT" --on-ip 127.0.0.1 --tproxy-mark "$CLASH_MARK"
iptables -t mangle -I PREROUTING -p tcp -j CLASH_EXTERNAL
if [[ -z "$(ip rule list fwmark "$CLASH_MARK" table "$CLASH_TABLE")" ]]; then
    ip rule add fwmark "$CLASH_MARK" table "$CLASH_TABLE"
fi
ip route replace local 0.0.0.0/0 dev lo table "$CLASH_TABLE"
