#!/bin/bash

set -e
#set -x

# basic script to generate templated config for our various docker images.
# it runs in its own alpine docker image to pull in yq as a dep, and to let the whole thing be managed by docker-compose.

# by this point, synapse & mas should generated default config files & secrets
# via generate-synapse-secrets.sh and generate-mas-secrets.sh

if [[ ! -s /secrets/synapse/signing.key ]] # TODO: check for existence of other secrets?
then
	# extract synapse secrets from the config and move them into ./secrets
	echo "Extracting generated synapse secrets..."
	mkdir -p /secrets/synapse
	for secret in registration_shared_secret macaroon_secret_key form_secret pepper_secret worker_replication_secret
	do
		yq .$secret /data/synapse/homeserver.yaml.default > /secrets/synapse/$secret
	done
	# ...and files too, just to keep all our secrets in one place
	mv /data/synapse/${DOMAIN}.signing.key /secrets/synapse/signing.key
fi

if [[ ! -f /secrets/mas/secrets ]] # TODO: check for existence of other secrets?
then
	echo "Extracting generated MAS secrets..."
	mkdir -p /secrets/mas
	# extract MAS secrets from the config and move them into ./secrets
	for secret in matrix.secret
	do
		yq .$secret /data/mas/config.yaml.default > /secrets/mas/$secret
	done
	yq '(.secrets) as $s
	    ireduce({}; setpath($s | path; $s))' /data/mas/config.yaml.default > /secrets/mas/secrets
	head -c16 /dev/urandom | base64 | tr -d '=' > /secrets/mas/client.secret
fi

if [[ ! -s /secrets/postgres/postgres_password ]]
then
	mkdir -p /secrets/postgres
	head -c16 /dev/urandom | base64 | tr -d '=' > /secrets/postgres/postgres_password
fi

mkdir -p /secrets/livekit
if [[ ! -s /secrets/livekit/livekit_api_key ]]
then
	(echo -n API; (head -c8 /dev/urandom | base64)) | tr -d '=' > /secrets/livekit/livekit_api_key
fi
if [[ ! -s /secrets/livekit/livekit_secret_key ]]
then
	head -c28 /dev/urandom | base64 | tr -d '=' > /secrets/livekit/livekit_secret_key
fi

mkdir -p /secrets/hookshot
if [[ ! -s /secrets/hookshot/hookshot_passkey ]]
then
	openssl genpkey -out /secrets/hookshot/hookshot_passkey -outform PEM -algorithm RSA -pkeyopt rsa_keygen_bits:4096
fi

# Previous: if [[ ! -s /secrets/hookshot/hookshot_github_key && ! -z $HOOKSHOT_GITHUB_PRIVATE_KEY ]]
if [[ ! -z $HOOKSHOT_GITHUB_PRIVATE_KEY ]]
then
	echo $HOOKSHOT_GITHUB_PRIVATE_KEY > /secrets/hookshot/hookshot_github_key && sed 's/ /\n/g' /secrets/hookshot/hookshot_github_key
fi

# TODO: compare the default generated config with our templates to see if our templates are stale
# we'd have to strip out the secrets from the generated configs to be able to diff them sensibly

# now we have our secrets extracted from the default configs, overwrite the configs with our templates

# for simplicity, we just use envsubst for now rather than ansible+jinja or something.
template() {
	dir=$1
	echo "Templating configs in $dir"
	for file in `find $dir -type f`
	do
		mkdir -p `dirname ${file/-template/}`
		envsubst < $file > ${file/-template/}
	done
}

export CONFIG_HEADER="# WARNING: This file is autogenerated by Zapal's Matrix stack from templates"
export DOLLAR='$' # evil hack to escape dollars in config files
(
	export SECRETS_SYNAPSE_REGISTRATION_SHARED_SECRET=$(</secrets/synapse/registration_shared_secret)
	export SECRETS_SYNAPSE_MACAROON_SECRET_KEY=$(</secrets/synapse/macaroon_secret_key)
	export SECRETS_SYNAPSE_FORM_SECRET=$(</secrets/synapse/form_secret)
	export SECRETS_SYNAPSE_PEPPER_SECRET=$(</secrets/synapse/pepper_secret)
	export SECRETS_SYNAPSE_WORKER_REPLICATION_SECRET=$(</secrets/synapse/worker_replication_secret)
	export SECRETS_MAS_MATRIX_SECRET=$(</secrets/mas/matrix.secret)
	export SECRETS_MAS_CLIENT_SECRET=$(</secrets/mas/client.secret)
	export SECRETS_POSTGRES_PASSWORD=$(</secrets/postgres/postgres_password)
	template "/data-template/synapse"
)

(
	export SECRETS_MAS_SECRETS=$(</secrets/mas/secrets)
	export SECRETS_MAS_MATRIX_SECRET=$(</secrets/mas/matrix.secret)
	export SECRETS_MAS_CLIENT_SECRET=$(</secrets/mas/client.secret)
	export SECRETS_POSTGRES_PASSWORD=$(</secrets/postgres/postgres_password)
	template "/data-template/mas"
)

(
	export SECRETS_LIVEKIT_API_KEY=$(</secrets/livekit/livekit_api_key)
	export SECRETS_LIVEKIT_SECRET_KEY=$(</secrets/livekit/livekit_secret_key)
	template "/data-template/livekit"
)

template "/data-template/hookshot"
template "/data-template/element-web"
template "/data-template/element-call"
template "/data-template/nginx"