#!/bin/bash

# Defines a series of util functions and aliases to be used to overcome compatibility issues with Mac

# Return the current machine's IP
get_this_private_ip()
{
    if [[ "$OSTYPE" == "darwin"* ]]; then
        ipconfig getifaddr en0
    else
        hostname -I | cut -d ' ' -f1
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
