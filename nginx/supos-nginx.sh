cat >/root/tools/nginx/conf.d/supos-nginx.conf << EOF
upstream backend {
    server ${W1} max_fails=2 fail_timeout=120s;   ### 当两次失败后，屏蔽 60s
    server ${W2} max_fails=2 fail_timeout=120s;
    server ${W3} max_fails=2 fail_timeout=120s;
  }

server {
  listen 8080 default_server;
  listen 8443 ssl;

  ssl_certificate /usr/local/nginx/ssl/nginx-default.crt;
  ssl_certificate_key /usr/local/nginx/ssl/nginx-default.key;
  ssl_protocols TLSv1.1 TLSv1.2;

  ssl_session_cache shared:SSL:10m;
  ssl_session_timeout 10m;
  ssl_prefer_server_ciphers on;
  ssl_ciphers ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256;
  server_name _;
  location / {
    proxy_pass http://backend/;
    proxy_next_upstream error timeout http_500 http_502 http_503 http_504;
    proxy_set_header Host dt.175.dev.supos.net;
    proxy_http_version 1.1;
    proxy_set_header   X-Real-IP        $remote_addr;
    proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;

    proxy_set_header  X-Forwarded-Port  $server_port;
    proxy_set_header  X-Forwarded-Proto $scheme;
    proxy_set_header  X-Forwarded-Host  $host;

    proxy_connect_timeout   5s;
    proxy_send_timeout      60s;
    proxy_read_timeout      300s;        ###当其中一个 upstream 宕机后，影响页面的响应切换时间，也影响正常业务的大图片，长时间的接口
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "Upgrade";
  }
}
EOF