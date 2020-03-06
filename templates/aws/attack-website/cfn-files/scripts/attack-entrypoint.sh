#!/bin/bash

# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

set -e

/usr/bin/python3 update-attack.py -c -b

cd output/ && /usr/bin/python3 -m pelican.server

exec "$@"
