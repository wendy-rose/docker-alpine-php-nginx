#!/bin/bash
set -e

su - worker -s /bin/sh -c "/usr/bin/supervisord -n -c /home/worker/supervisor/supervisord.conf"