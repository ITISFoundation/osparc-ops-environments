#!/bin/sh
# This subsititutes the entropypoint of traefik in order to
# load self-signed SSL certificates for external service loadbalancer URLs
# If necessary.
#
#Uncomment this to debug:
echo Running custom entrypointsh to add self-signed CAs
echo Remaining arguments passed to Traefik: "$@"
#
# Add cp statements for the certificates here:
cp /secrets/storageca.crt /usr/local/share/ca-certificates
# Update the systems certificates
update-ca-certificates
#
# Continue with traefik...
/bin/sh entrypoint.sh "$@"
