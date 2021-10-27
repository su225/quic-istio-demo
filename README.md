# Using HTTP/3 over QUIC at Istio gateway

Here, we demonstrate how to use HTTP/3 support at the gateway

## Prerequisites
* Kubernetes 1.20 or above with `MixedProtocolLBService` feature gate turned on
* Custom build of curl supporting HTTP/3. Follow the instructions [here](https://github.com/curl/curl/blob/master/docs/HTTP3.md)
* Custom build of Istio from the latest master/main branch (because as of writing this 1.12 is not yet released)

## Testing
1. Install Istio with the [istio-operator config in this repo](istio-operator.yaml)
   ```
   $ istioctl install -f istio-operator.yaml -y
   ```
2. Install httpbin application from the samples directory of Istio repo
3. Generate and setup serving certificates for the gateway (TLS is a must for QUIC)
   ```
   $ ./generate_certs.sh
   $ kubectl -n istio-system create secret tls httpbin-cred --key=httpbin.key --cert=httpbin.crt
   ```
4. Apply Istio configs
   ```
   $ kubectl -n istio-system apply -f gateway-config.yaml
   ```

Finally, Enjoy! (here `qcurl` is the custom build of curl with HTTP/3 support)
```
$ curl -svk --http2 --resolve httpbin.quic-corp.com:443:$INGRESS_IP https://httpbin.quic-corp.com/headers
* Added httpbin.quic-corp.com:443:172.18.200.1 to DNS cache
* Hostname httpbin.quic-corp.com was found in DNS cache
*   Trying 172.18.200.1:443...
* Connected to httpbin.quic-corp.com (172.18.200.1) port 443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*  CAfile: /etc/pki/tls/certs/ca-bundle.crt
*  CApath: none
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
* TLSv1.3 (IN), TLS handshake, Finished (20):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384
* ALPN, server accepted to use h2
* Server certificate:
*  subject: C=IN; ST=KA; O=QuicCorp
*  start date: Oct 27 04:02:03 2021 GMT
*  expire date: Oct 27 04:02:03 2022 GMT
*  issuer: C=IN; ST=KA; O=QuicCorp
*  SSL certificate verify result: self signed certificate (18), continuing anyway.
* Using HTTP2, server supports multi-use
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x55d490492c70)
> GET /headers HTTP/2
> Host: httpbin.quic-corp.com
> user-agent: curl/7.76.1
> accept: */*
> 
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* old SSL session ID is stale, removing
* Connection state changed (MAX_CONCURRENT_STREAMS == 2147483647)!
< HTTP/2 200 
< server: istio-envoy
< date: Wed, 27 Oct 2021 05:25:47 GMT
< content-type: application/json
< content-length: 601
< access-control-allow-origin: *
< access-control-allow-credentials: true
< x-envoy-upstream-service-time: 2
< alt-svc: h3=":443"; ma=86400
< 
{
  "headers": {
    "Accept": "*/*", 
    "Host": "httpbin.quic-corp.com", 
    "User-Agent": "curl/7.76.1", 
    "X-B3-Parentspanid": "6d84b1bd4f0bf45c", 
    "X-B3-Sampled": "0", 
    "X-B3-Spanid": "797817a97ad662a3", 
    "X-B3-Traceid": "753df0dc8c07b0ed6d84b1bd4f0bf45c", 
    "X-Envoy-Attempt-Count": "1", 
    "X-Envoy-Internal": "true", 
    "X-Forwarded-Client-Cert": "By=spiffe://cluster.local/ns/httpbin/sa/httpbin;Hash=97bf9c90d4a5b9bb8f5da3e825dfa34f04631400420649394741807a320aa0a1;Subject=\"\";URI=spiffe://cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"
  }
}
```

```
$ qcurl -svk --http3 --resolve httpbin.quic-corp.com:443:$INGRESS_IP https://httpbin.quic-corp.com/headers
* Added httpbin.quic-corp.com:443:172.18.200.1 to DNS cache
* Hostname httpbin.quic-corp.com was found in DNS cache
*   Trying 172.18.200.1:443...
* Connect socket 5 over QUIC to 172.18.200.1:443
* Sent QUIC client Initial, ALPN: h3,h3-29,h3-28,h3-27
* Connected to httpbin.quic-corp.com () port 443 (#0)
* h3 [:method: GET]
* h3 [:path: /headers]
* h3 [:scheme: https]
* h3 [:authority: httpbin.quic-corp.com]
* h3 [user-agent: curl/7.78.0-DEV]
* h3 [accept: */*]
* Using HTTP/3 Stream ID: 0 (easy handle 0x1271260)
> GET /headers HTTP/3
> Host: httpbin.quic-corp.com
> user-agent: curl/7.78.0-DEV
> accept: */*
> 
< HTTP/3 200
< server: istio-envoy
< date: Wed, 27 Oct 2021 05:26:37 GMT
< content-type: application/json
< content-length: 642
< access-control-allow-origin: *
< access-control-allow-credentials: true
< x-envoy-upstream-service-time: 1
< alt-svc: h3=":443"; ma=86400
< 
{
  "headers": {
    "Accept": "*/*", 
    "Host": "httpbin.quic-corp.com", 
    "Transfer-Encoding": "chunked", 
    "User-Agent": "curl/7.78.0-DEV", 
    "X-B3-Parentspanid": "46eac59a61cd919b", 
    "X-B3-Sampled": "0", 
    "X-B3-Spanid": "ab6bf7a61405a2d1", 
    "X-B3-Traceid": "e2b138e4d3dfe28746eac59a61cd919b", 
    "X-Envoy-Attempt-Count": "1", 
    "X-Envoy-Internal": "true", 
    "X-Forwarded-Client-Cert": "By=spiffe://cluster.local/ns/httpbin/sa/httpbin;Hash=97bf9c90d4a5b9bb8f5da3e825dfa34f04631400420649394741807a320aa0a1;Subject=\"\";URI=spiffe://cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"
  }
}
```