#!/bin/bash

# Defines a series of util functions and aliases to be used to overcome compatibility issues with Mac

# Return the current machine's IP
get_this_ip()
{
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo $(ipconfig getifaddr en0)
    else
        echo $(hostname -I | cut -d ' ' -f1)
    fi
}

# Set psed alias for using the GNU version of sed in Mac
if [[ $OSTYPE == "darwin"* ]]; then
    psed=gsed
else
    psed=sed
fi
