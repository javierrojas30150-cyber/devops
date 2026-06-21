# Multistage
# Stage 1: build React
FROM node:20-alpine AS builder
WORKDIR /build
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: nginx sin privilegios root
FROM nginxinc/nginx-unprivileged:alpine
USER root
RUN apk add --no-cache gettext \
  && mkdir -p /etc/nginx/templates /etc/nginx/conf.d \
  && chown -R nginx:nginx /etc/nginx

# Crear entrypoint script inline para evitar problemas de permisos en Windows
RUN echo '#!/bin/sh' > /docker-entrypoint.sh && \
    echo 'set -eu' >> /docker-entrypoint.sh && \
    echo 'BACKEND_HOST="${BACKEND_HOST:-backend-ventas}"' >> /docker-entrypoint.sh && \
    echo 'BACKEND_HOST_DESPACHOS="${BACKEND_HOST_DESPACHOS:-backend-despacho}"' >> /docker-entrypoint.sh && \
    echo 'export BACKEND_HOST BACKEND_HOST_DESPACHOS' >> /docker-entrypoint.sh && \
    echo 'envsubst < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf' >> /docker-entrypoint.sh && \
    echo 'exec nginx -g "daemon off;"' >> /docker-entrypoint.sh && \
    chmod +x /docker-entrypoint.sh && \
    chown nginx:nginx /docker-entrypoint.sh

COPY nginx.conf.template /etc/nginx/templates/default.conf.template
COPY --from=builder /build/dist /usr/share/nginx/html
USER nginx
ENV BACKEND_HOST=backend-ventas
EXPOSE 8080
ENTRYPOINT ["/docker-entrypoint.sh"]
