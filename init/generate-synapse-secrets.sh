#!/usr/bin/bash

# a replacement entrypoint script for the synapse docker image which generates default config & secrets if needed.

if [[ -f ${SYNAPSE_CONFIG_PATH} ]]
then
	echo "Synapse config found - not generating default"
	exit 0
fi

echo "Synapse config not found - generating default for secrets"
exec /start.py generate