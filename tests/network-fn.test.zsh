# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Tests for validation and public IP parsing in lib/network.zsh, and types in
# lib/fn.zsh

## IP / domain / URL predicates share _FN_TYPES patterns
assert_ok is_valid_ip 192.168.1.1
assert_fail is_valid_ip 192.168.1.256
assert_ok is_valid_ipv6 2001:db8::1
assert_fail is_valid_ipv6 2001:db8:::1
assert_ok is_valid_domain example.com
assert_ok is_domain_valid example.com
assert_fail is_valid_domain -bad.com
assert_ok is_valid_url "https://example.com:8080/path?q=1"
assert_fail is_valid_url example.com

## fn types: "url" accepts URLs with "s" after :// (audit bug #1)
assert_ok _fn_validate_type https://test.com url
assert_ok _fn_validate_type https://example.com/s url
assert_fail _fn_validate_type "http://a b" url
assert_ok _fn_validate_type https://x.org "url[https]"
assert_fail _fn_validate_type http://x.org "url[https]"

## fn types: integer and float accept signs, ".5" and exponents
assert_ok _fn_validate_type +5 integer
assert_ok _fn_validate_type .5 float
assert_ok _fn_validate_type -1.25e3 float
assert_fail _fn_validate_type 1.2.3 float
assert_ok _fn_validate_type 5 "integer[1;10]"
assert_fail _fn_validate_type 11 "integer[1;10]"

## ports and timeouts
assert_rc 2 is_port_open localhost 70000
assert_rc 2 is_port_open localhost

## Public IP: answers are parsed from DNS TXT and HTTP text formats
_public_ip_parse 4 '"89.77.161.22"'
assert_eq "$REPLY" 89.77.161.22 "public ip: quoted DNS TXT answer"
_public_ip_parse 4 "IP Address: 1.2.3.4"$'\r'
assert_eq "$REPLY" 1.2.3.4 "public ip: labelled HTTP answer"
assert_fail _public_ip_parse 4 "999.1.1.1"
assert_fail _public_ip_parse 4 ";; connection timed out; no servers could be reached"
assert_fail _public_ip_parse 4 ""
assert_ok _public_ip_filter6 "2001:db8::1"
assert_fail _public_ip_filter6 "89.77.161.22"
assert_rc 2 _public_ip_parse 4

## Public IP: invalid usage, and no tools to ask with
assert_rc 2 get_public_ip extra
assert_rc 2 get_public_ip -t 0
assert_rc 2 get_public_ip -t abc
assert_rc 127 eval 'path=(/nonexistent); get_public_ip'

## Local IP: invalid usage and unknown interfaces
assert_rc 2 get_local_ips a b
assert_rc 2 get_local_ips -x
assert_fail get_local_ips no_such_iface0
assert_fail get_local_ip no_such_iface0
assert_fail get_local_ip6 no_such_iface0
assert_eq "$REPLY" "" "get_local_ip6: empty REPLY when not found"

## myip: LAN-only and WAN-only options are rejected for the other part
fpath=($REPO_DIR/functions $fpath)
autoload -Uz myip
assert_rc 2 myip -w -i en0
assert_rc 2 myip -w -a
assert_rc 2 myip -l -t 5
assert_rc 2 myip -l -V
assert_rc 2 myip -t 0
assert_fail myip -l -i no_such_iface0
assert_eq "$(myip -l -i no_such_iface0 2>/dev/null)" "" "myip -l: no label, nothing on stdout"
