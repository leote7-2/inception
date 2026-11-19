#!/bin/bash
set -e

if [ -z "$DOMAIN_NAME" ]; then
    echo "Erro: DOMAIN_NAME não está definido."
    exit 1
fi

# Substitui o placeholder pelo domínio
sed -i "s/DOMAIN_NAME_PLACEHOLDER/${DOMAIN_NAME}/g" \
    /etc/nginx/sites-available/default

# Gera o certificado TLS se necessário
if [ ! -f /etc/nginx/ssl/inception.crt ] || \
   [ ! -f /etc/nginx/ssl/inception.key ]; then
    echo "A gerar certificado TLS..."

    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/inception.key \
        -out /etc/nginx/ssl/inception.crt \
        -subj "/C=PT/ST=Lisboa/L=Lisboa/O=42/OU=42/CN=${DOMAIN_NAME}"
fi

# Valida a configuração do NGINX
echo "A validar a configuração do NGINX..."
nginx -t

# Arranca o NGINX em primeiro plano
echo "A arrancar NGINX..."
exec nginx -g "daemon off;"

