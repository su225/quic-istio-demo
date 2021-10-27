#!/usr/bin/env bash

openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:4096 -subj "/C=IN/ST=KA/O=QuicCorp" \
    -keyout quiccorp-ca.key -out quiccorp-ca.crt

openssl req -out httpbin.csr -newkey rsa:2048 -nodes -keyout httpbin.key -config httpbin.cnf
openssl x509 -req -days 365 -CA quiccorp-ca.crt -CAkey quiccorp-ca.key \
    -set_serial 0 -in httpbin.csr -out httpbin.crt -extfile httpbin.cnf -extensions san_reqext

rm -rf httpbin.csr
rm -rf quiccorp-ca.key

