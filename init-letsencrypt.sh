#!/bin/bash

# taken from https://raw.githubusercontent.com/wmnnd/nginx-certbot/refs/heads/master/init-letsencrypt.sh

#set -x

if ! [ -x "$(command -v docker)" ]; then
  echo 'Error: docker is not installed.' >&2
  exit 1
fi

source .env
domains=($DOMAINS)
rsa_key_size=4096
data_path="./data/certbot"
read -p "admin email address for letsencrypt: " email
staging=0 # Set to 1 if you're testing your setup to avoid hitting request limits

if [ -d "$data_path" ]; then
  read -p "Existing data found for $domains. Continue and replace existing certificate? (y/N) " decision
  if [ "$decision" != "Y" ] && [ "$decision" != "y" ]; then
    exit
  fi
fi

if [ ! -e "data/ssl/options-ssl-nginx.conf" ] || [ ! -e "data/ssl/ssl-dhparams.pem" ]; then
  echo "### Downloading recommended TLS parameters ..."
  mkdir -p "$data_path/conf"
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "data/ssl/options-ssl-nginx.conf"
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "data/ssl/ssl-dhparams.pem"
  echo
fi

# echo "### Creating dummy certificate for $domains ..."
# # N.B. in bash, $domains will return the first value of the array in string context, so this is not a bug:
# mkdir -p "$data_path/conf/live/$domains"
# path="/etc/letsencrypt/live/$domains"
# docker compose run --rm --entrypoint "\
#   openssl req -x509 -nodes -newkey rsa:$rsa_key_size -days 1\
#     -keyout '$path/privkey.pem' \
#     -out '$path/fullchain.pem' \
#     -subj '/CN=localhost'; \
#   cp /etc/ssl/certs/ca-certificates.crt '$path'" certbot
# echo
# 
# echo "### Starting nginx ..."
# docker compose up --force-recreate -d nginx
# echo
# 
# exit
# 
# echo "### Deleting dummy certificate for $domains ..."
# docker compose run --rm --entrypoint "\
#   rm -Rf /etc/letsencrypt/live/$domains && \
#   rm -Rf /etc/letsencrypt/archive/$domains && \
#   rm -Rf /etc/letsencrypt/renewal/$domains.conf" certbot
# echo

echo "### Requesting Let's Encrypt certificate for $domains ..."
#Join $domains to -d args
domain_args=""
for domain in "${domains[@]}"; do
  domain_args="$domain_args -d $domain"
done

# Select appropriate email arg
case "$email" in
  "") email_arg="--register-unsafely-without-email" ;;
  *) email_arg="--email $email" ;;
esac

# Enable staging mode if needed
if [ $staging != "0" ]; then staging_arg="--staging"; fi

docker compose run -p 80:80 --rm --entrypoint " \
  sh -c \"certbot certonly --standalone \
    $staging_arg \
    $email_arg \
    $domain_args \
    --rsa-key-size $rsa_key_size \
    --agree-tos \
    --force-renewal;
  cp /etc/letsencrypt/live/$domains/*.pem /data/ssl; \
  cp /etc/ssl/certs/ca-certificates.crt /data/ssl; \
  chown -R $USER_ID:$GROUP_ID /data/ssl; \
    \"" certbot
echo

# echo "### Reloading nginx ..."
# docker compose exec nginx nginx -s reload
