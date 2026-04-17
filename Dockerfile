# syntax=docker/dockerfile:1.7

FROM alpine:3.20 AS assets
WORKDIR /src
COPY . .

FROM nginxinc/nginx-unprivileged:stable-alpine

ENV NGINX_ENTRYPOINT_QUIET_LOGS=1

COPY <<'EOF' /etc/nginx/conf.d/default.conf
server {
    listen 8080;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    server_tokens off;
    gzip on;
    gzip_types text/plain text/css application/javascript image/svg+xml;

    location ~* \.(css|js|jpg|jpeg|png|gif|svg|ico)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }

    location / {
        try_files $uri $uri/ =404;
    }
}
EOF

COPY --from=assets /src/ /usr/share/nginx/html/

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
    CMD wget -qO- http://127.0.0.1:8080/ >/dev/null 2>&1 || exit 1
