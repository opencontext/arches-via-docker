#!/bin/sh

set -e

if [ -z "$DOMAINS" ]; then
  echo "DOMAINS environment variable is not set"
  exit 1;
fi

use_dummy_certificate() {
  # Switch sympolic links to reference the apprpriate SSL keys
  mkdir -p /etc/symb_link_ssl;

  if [ -f "/etc/letsencrypt/live/$1/fullchain.pem" ]; then
    echo "Nginx to use Let's Encrypt certificate for $1";
    ln -sfn  "/etc/letsencrypt/live/$1/fullchain.pem" /etc/symb_link_ssl/fullchain.pem;
    ln -sfn  "/etc/letsencrypt/live/$1/privkey.pem" /etc/symb_link_ssl/privkey.pem;
  else
   echo "Nginx to use dummy (testing) SSL certificate for $1"
    ln -sfn  "/etc/nginx/sites/ssl/dummy/$1/fullchain.pem" /etc/symb_link_ssl/fullchain.pem;
    ln -sfn  "/etc/nginx/sites/ssl/dummy/$1/privkey.pem" /etc/symb_link_ssl/privkey.pem;
  fi
}

use_lets_encrypt_certificate() {
  # Switch sympolic links to reference the apprpriate SSL keys
  mkdir -p /etc/symb_link_ssl;

  if [ -f "/etc/letsencrypt/live/$1/fullchain.pem" ]; then
    echo "Nginx to use Let's Encrypt certificate for $1";
    ln -sfn  "/etc/letsencrypt/live/$1/fullchain.pem" /etc/symb_link_ssl/fullchain.pem;
    ln -sfn  "/etc/letsencrypt/live/$1/privkey.pem" /etc/symb_link_ssl/privkey.pem;
  else
   echo "Nginx to use dummy (testing) SSL certificate for $1"
    ln -sfn  "/etc/nginx/sites/ssl/dummy/$1/fullchain.pem" /etc/symb_link_ssl/fullchain.pem;
    ln -sfn  "/etc/nginx/sites/ssl/dummy/$1/privkey.pem" /etc/symb_link_ssl/privkey.pem;
  fi
}

reload_nginx() {
  echo "Reloading Nginx configuration"
  nginx -s reload;
}

wait_for_lets_encrypt() {
  certpath_fixed=$(echo "$CERT_PATH" | tr -d \");
  until [ -d "/etc/letsencrypt/live/$1" ]; do
    echo "CERT_PATH is apparently $certpath_fixed, with contents: ";
    ls $certpath_fixed;
    echo "Waiting for Let's Encrypt certificates for $1";
    sleep 10s & wait ${!}
  done
  use_lets_encrypt_certificate "$1"
  reload_nginx
}

if [ ! -f /etc/nginx/sites/ssl/ssl-dhparams.pem ]; then
  mkdir -p "/etc/nginx/sites/ssl"
  openssl dhparam -out /etc/nginx/sites/ssl/ssl-dhparams.pem 2048
fi

domains_fixed=$(echo "$DOMAINS" | tr -d \")
for domain in $domains_fixed; do
  echo "Checking configuration for $domain"

  echo "Make sure we have a cerbot directory for $domain";
  mkdir -p /var/www/certbot/$domain;

  echo "Prepping cerbot acme-challenge folder for: $domain"
    mkdir -p /var/www/certbot/$domain/.well-known/acme-challenge
    echo "look here for $domain cert dir (deep)!" > /var/www/certbot/$domain/.well-known/acme-challenge/hello.txt;
    chmod 644 /var/www/certbot/$domain/.well-known/acme-challenge/hello.txt;
    echo "look here for $domain cert dir (shallow)!" > /var/www/certbot/$domain/hello.txt;
    chmod 644 /var/www/certbot/$domain/hello.txt;

  if [ ! -f "/etc/nginx/sites/$domain.conf" ]; then
    echo "Skip creating Nginx configuration file /etc/nginx/sites/$domain.conf"
    # sed "s/\${domain}/$domain/g" /customization/site.conf.tpl > "/etc/nginx/sites/$domain.conf"
  fi

  if [ ! -f "/etc/nginx/sites/ssl/dummy/$domain/fullchain.pem" ]; then

    echo "Generating dummy ceritificate for $domain"
    mkdir -p /etc/nginx/sites/ssl/dummy/$domain
    printf "[dn]\nCN=${domain}\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:$domain, DNS:www.$domain\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth" > openssl.cnf
    openssl req -x509 -out "/etc/nginx/sites/ssl/dummy/$domain/fullchain.pem" -keyout "/etc/nginx/sites/ssl/dummy/$domain/privkey.pem" \
      -newkey rsa:2048 -nodes -sha256 \
      -subj "/CN=${domain}" -extensions EXT -config openssl.cnf
    rm -f openssl.cnf

  fi

  if [ ! -d "/etc/letsencrypt/live/$domain" ]; then
    use_dummy_certificate "$domain"
    wait_for_lets_encrypt "$domain" &
  else
    use_lets_encrypt_certificate "$domain"
  fi

  echo "-----------------------------------------------";
  echo "Check out the contents of /static_root/";
  ls /static_root;
  echo "-----------------------------------------------";
done

exec nginx -g "daemon off;"