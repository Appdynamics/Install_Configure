#!/bin/bash
#
# Local install onto this host
./econsole-cmds.sh installPlatform
./econsole-cmds.sh addLocalHost
./econsole-cmds.sh installController
./econsole-cmds.sh installEventsService

./econsole-cmds.sh licenseLocal
