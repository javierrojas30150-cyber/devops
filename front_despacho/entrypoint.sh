#!/bin/sh
set -eu

# Set default values for backend hosts
export BACKEND_HOST="${BACKEND_HOST:-backend-ventas}"
export BACKEND_HOST_DESPACHOS="${BACKEND_HOST_DESPACHOS:-backend-despacho}"

echo "Starting frontend with BACKEND_HOST=$BACKEND_HOST and BACKEND_HOST_DESPACHOS=$BACKEND_HOST_DESPACHOS"

# Generate nginx config from template using sed (more reliable than envsubst)
sed -e "s|@BACKEND_HOST@|$BACKEND_HOST|g" \
    -e "s|@BACKEND_HOST_DESPACHOS@|$BACKEND_HOST_DESPACHOS|g" \
    /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf

echo "Generated nginx config:"
cat /etc/nginx/conf.d/default.conf

# Start nginx
exec nginx -g "daemon off;"