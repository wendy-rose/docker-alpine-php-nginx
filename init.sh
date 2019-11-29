#!/bin/bash
set -e

su - worker -s /bin/sh -c "/usr/bin/supervisord -n -c /etc/supervisord.conf"