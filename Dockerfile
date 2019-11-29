FROM alpine:3.9
MAINTAINER wendylin6970@gmail.com

ADD build /build

RUN sh /build/prepare.sh && \
       sh /build/php.sh && \
       sh /build/nginx.sh && \
       sh /build/finish.sh

ADD config/nginx /home/worker/nginx/
ADD config/php /home/worker/php/
ADD config/supervisor/supervisord.conf /etc/supervisord.conf
ADD config/supervisor/conf.d /etc/supervisor/conf.d/

#Start up
COPY init.sh /etc/my_init.d/init.sh

WORKDIR /home/worker/data/www

EXPOSE 80

CMD ["sh", "-c", "/etc/my_init.d/init.sh"]