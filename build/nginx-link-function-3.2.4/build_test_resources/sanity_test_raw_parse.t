# Test Suite to parse the relevant variable the sanity.t once built

use lib 'inc';
use lib 'lib';
use Test::Nginx::Socket 'no_plan';

our $main_conf = <<'_EOC_';
    thread_pool my_thread_pool threads=8 max_queue=8;
_EOC_

no_long_string();

run_tests();

#no_diff();

__DATA__

=== TEST 1: Set LINK_FUNC_TEST_1
--- config
ngx_link_func_lib "NGINX_HTTP_LINK_FUNC_TEST_LIB_PATH";
location = /testLinkFunGreeting {
    ngx_link_func_call "my_app_simple_get_greeting";
}
--- request
GET /testLinkFunGreeting
--- error_code: 200
--- response_headers
Content-Type: text/plain
--- response_body_like eval
qr/greeting from ngx_link_func testing$/


=== TEST 2: Set LINK_FUNC_TEST_ARGS
--- config
ngx_link_func_lib "NGINX_HTTP_LINK_FUNC_TEST_LIB_PATH";
location = /testLinkFunARGS {
    ngx_link_func_call "my_app_simple_get_args";
}
--- request
GET /testLinkFunARGS?greeting=hello_nginx?id=129310923
--- error_code: 200
--- response_headers
Content-Type: text/plain
--- response_body_like eval
qr/greeting=hello_nginx\?id=129310923$/


=== TEST 3: Set LINK_FUNC_TEST_POST_NONE
--- config
ngx_link_func_lib "NGINX_HTTP_LINK_FUNC_TEST_LIB_PATH";
location = /testLinkFunPOSTBody {
    ngx_link_func_call "my_app_simple_post";
}
--- request
POST /testLinkFunPOSTBody
" "
--- error_code: 202
--- response_headers
Content-Type: text/plain
--- response_body_like eval
qr/\s/


=== TEST 4: Set LINK_FUNC_TEST_GET_TOKEN
--- config
ngx_link_func_lib "NGINX_HTTP_LINK_FUNC_TEST_LIB_PATH";
location = /testLinkFunCVerifyToken {
    ngx_link_func_call "my_app_simple_get_token_args";
}
--- request
GET /testLinkFunCVerifyToken?token=QVNKS0pDQVNLTEpDS0xBU0pXbGtlandrbGplIGpka2FqbGthc2tsZGtqbHNrICBrZGpha2xzZGphc2Rhcw==
--- error_code: 401
--- response_headers
Content-Type: text/plain
--- response_body_like eval
qr/QVNKS0pDQVNLTEpDS0xBU0pXbGtlandrbGplIGpka2FqbGthc2tsZGtqbHNrICBrZGpha2xzZGphc2Rhcw==$/


=== TEST 5: Set LINK_FUNC_TEST_GET_ERROR_RESP
--- config
ngx_link_func_lib "NGINX_HTTP_LINK_FUNC_TEST_LIB_PATH";
location = /testLinkFuncERRORRESP {
    error_log /dev/null;
    ngx_link_func_call "my_app_simple_get_no_resp";
}
--- request
GET /testLinkFuncERRORRESP?token=QVNKS0pDQVNLTEpDS0xBU0pXbGtlandrbGplIGpka2FqbGthc2tsZGtqbHNrICBrZGpha2xzZGphc2Rhcw==
--- error_code: 404
--- response_headers
Content-Type: text/html


=== TEST 6: Set LINK_FUNC_TEST_GET_CALLOC_FROM_POOL
--- config
ngx_link_func_lib "NGINX_HTTP_LINK_FUNC_TEST_LIB_PATH";
location = /testLinkFuncCallocFromPool {
    ngx_link_func_call "my_app_simple_get_calloc_from_pool";
}
--- request
GET /testLinkFuncCallocFromPool
--- error_code: 200
--- response_headers
Content-Type: text/plain
--- response_body_like eval
qr/This is the message calloc from pool$/


=== TEST 7: Set LINK_FUNC_TEST_POST_BODY
--- config
ngx_link_func_lib "NGINX_HTTP_LINK_FUNC_TEST_LIB_PATH";
location = /testLinkFunPOSTBody {
    ngx_link_func_call "my_app_simple_post";
}
--- request
POST /testLinkFunPOSTBody
greeting=enjoy-http-link-function-testing
--- error_code: 202
--- response_headers
Content-Type: text/plain
--- response_body_like eval
qr/greeting=enjoy-http-link-function-testing$/


=== TEST 8: Set LINK_FUNC_TEST_CACHE
--- config
ngx_link_func_lib "NGINX_HTTP_LINK_FUNC_TEST_LIB_PATH";
location = /testLinkFunGetCache {
    ngx_link_func_call "my_app_simple_get_cache";
}
location = /testLinkFunSetCache {
    ngx_link_func_call "my_app_simple_set_cache";
}
--- pipelined_requests eval
["POST /testLinkFunSetCache", "GET /testLinkFunGetCache"]
--- response_body eval
["OK", "This is cache value"]


=== TEST 9: Test output headers
--- config
ngx_link_func_lib "NGINX_HTTP_LINK_FUNC_TEST_LIB_PATH";
location = /ext_header_foo {
    ngx_link_func_call "my_simple_extra_foo_header_output";
}
--- request
GET /ext_header_foo
--- error_code: 200
--- response_headers
foo: foovalue


=== TEST 10: Get Uri correct
--- config
ngx_link_func_lib "NGINX_HTTP_LINK_FUNC_TEST_LIB_PATH";
location = /testLinkFunUri {
    ngx_link_func_call "my_app_simple_get_uri";
}
--- request
GET /testLinkFunUri
--- error_code: 200
--- response_headers
Content-Type: text/plain
--- response_body_like eval
qr/testLinkFunUri$/

