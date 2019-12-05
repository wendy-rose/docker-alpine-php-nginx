FROM alpine:3.10
MAINTAINER wendylin6970@gmail.com

# Add source
RUN mkdir -p /home/worker/src
ADD src /home/worker/src

ADD build /build

RUN sh /build/prepare.sh && \
       sh /build/php.sh && \
       sh /build/nginx.sh && \
       sh /build/finish.sh

ADD config /home/worker/

#Start up
COPY init.sh /etc/my_init.d/init.sh

WORKDIR /home/worker/data/www

EXPOSE 80

CMD ["sh", "-c", "/etc/my_init.d/init.sh"]