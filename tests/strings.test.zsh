# Tests for lib/strings.zsh

## trim family keeps backslashes literally (audit bug #17)
assert_eq "$(trim '  a\tb  ')" 'a\tb' "trim raw"
assert_eq "$(ltrim '  ab ')" 'ab ' "ltrim"
assert_eq "$(rtrim ' ab  ')" ' ab' "rtrim"

## case conversion
assert_eq "$(lowercase ABC)" abc "lowercase"
assert_eq "$(uppercase abc)" ABC "uppercase"
assert_eq "$(capitalize hello)" Hello "capitalize"
assert_eq "$(to_snake_case 'Hello World')" hello_world "snake"
assert_eq "$(to_kebab_case 'Hello World')" hello-world "kebab"
assert_eq "$(to_camel_case 'hello big world')" helloBigWorld "camel"
assert_eq "$(slugify 'Hello, World!')" hello-world "slugify"

## edge cases that used to hang or crash (audit bugs #5, #6, #7)
assert_rc 2 str_split abc "" out
assert_rc 2 str_count abc ""
assert_eq "$(str_count banana an)" 2 "str_count"
assert_eq "$(str_pad Hi 6 ab left)" "ababHi" "str_pad multi-char"
assert_eq "$(str_pad_left 7 3 0)" 007 "str_pad_left"

## search
assert_ok str_contains "hello world" "o w"
assert_fail str_contains "hello" "x"
assert_ok str_starts_with "hello" "he"
assert_ok str_ends_with "hello" "lo"
assert_eq "$(str_index_of hello l)" 3 "str_index_of (1-based)"

## misc
assert_eq "$(str_reverse abc)" cba "reverse"
assert_eq "$(str_repeat ab 3)" ababab "repeat"
assert_eq "$(substring 'hello world' 6 5)" world "substring"
assert_eq "$(str_replace_all a-b-c - +)" a+b+c "replace_all"
assert_eq "$(get_version 'zsh 5.9 (x86_64)')" 5.9 "get_version"
assert_eq "$(extract_url 'see https://example.com/x now')" https://example.com/x "extract_url"

## unicode escape uses surrogate pairs outside BMP (audit bug #18)
assert_eq "$(str_to_unicode 😀)" '\uD83D\uDE00' "surrogates"

## URL encoding
assert_eq "$(url_encode 'a b&ż')" 'a%20b%26%C5%BC' "url_encode"
assert_eq "$(url_decode 'a%20b%26%C5%BC+c')" 'a b&ż c' "url_decode"
assert_eq "$(url_decode '100%')" '100%' "url_decode lone percent"

## predicates
assert_ok is_numeric -1.5
assert_fail is_numeric abc
assert_ok is_integer 42
assert_fail is_integer 4.2
assert_ok is_empty ""
