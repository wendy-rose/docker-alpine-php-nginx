#!/bin/sh

# Source networking configuration
. /etc/sysconfig/network

# worker account configuration
. /home/worker/.bash_profile

# Source function library.
. /etc/rc.d/init.d/functions

ulimit -SHn 65535

function stop_nginx()
{
    printf "Stoping Nginx...\n"
	/home/worker/nginx/sbin/nginx -s stop
}

function start_nginx()
{
    printf "Starting Nginx...\n"
	/home/worker/nginx/sbin/nginx -c /home/worker/nginx/conf/nginx.conf
}

function restart_nginx()
{
    printf "Restarting Nginx...\n"
	/home/worker/nginx/sbin/nginx -s reload
}

if [ "$1" = "start" ]; then
    start_nginx
elif [ "$1" = "stop" ]; then
    stop_nginx
elif [ "$1" = "restart" ]; then
    restart_nginx
else
    printf "Usage: /home/worker/nginx/sbin/nginx.sh {start|stop|restart}\n"
fi