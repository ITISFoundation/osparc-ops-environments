#!/bin/bash

# Defines a series of util functions and aliases to be used to overcome compatibility issues with Mac

# Return the current machine's IP
# Don't use `hostname -I`. `hostname` is part of net-tools, a package universally regarded as old and unmaintained.
# Modern GNU/Linux distributions use the up-to-date implementation from GNU/inetutils
# However, debian contributor Miachael Meskes has decided to code a dedicated, different `hostname` for debian, which follows different versioning schemes and
# is incompatible with the "official" one from GNU. The CLI option `-I` is not supported by the GNU/inetutils's hostname.
get_this_private_ip()
{
    if [[ "$OSTYPE" == "darwin"* ]]; then
        ipconfig getifaddr en0
    else
        hostname -i | cut -d ' ' -f1
    fi
}

get_this_public_ip()
{
    dig TXT +short o-o.myaddr.l.google.com @ns1.google.com | awk -F'"' '{ print $2}'
}

# Set psed alias for using the GNU version of sed in Mac
if [[ $OSTYPE == "darwin"* ]]; then
    psed=gsed
else
    # shellcheck disable=SC2034,SC2209
    psed=sed
fi
