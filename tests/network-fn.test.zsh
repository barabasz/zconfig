# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Tests for validation in lib/network.zsh and types in lib/fn.zsh

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
