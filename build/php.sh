#!/bin/bash
set -e

# PHP and extensions version
PHPREDIS_VERSION=5.0.0
PHP_VERSION=7.1.30
RE2C_VERSION=1.1.1
IGBINARY_VERSION=3.0.1
XDEBUG_VERSION=2.7.2

# Install re2c for php
cd /home/worker/src
wget -q -O re2c-${RE2C_VERSION}.tar.gz https://mrzfiles.oss-cn-shenzhen.aliyuncs.com/resource/re2c-${RE2C_VERSION}.tar.gz
tar xzf re2c-${RE2C_VERSION}.tar.gz
cd re2c-${RE2C_VERSION}
./configure
make -j$(nproc)
make install
rm -rf /home/worker/src/re2c*

# Install PHP
echo "---------- Install PHP... ----------"
cd /home/worker/src
mkdir -p /home/worker/php
wget -q -O php-${PHP_VERSION}.tar.xz https://mrzfiles.oss-cn-shenzhen.aliyuncs.com/resource/php-${PHP_VERSION}.tar.xz
xz -d php-${PHP_VERSION}.tar.xz
tar -xvf php-${PHP_VERSION}.tar
cd php-${PHP_VERSION}

./configure \
       --prefix=/home/worker/php \
       --with-config-file-path=/home/worker/php/etc \
       --with-config-file-scan-dir=/home/worker/php/etc/php.d \
       --sysconfdir=/home/worker/php/etc \
       --enable-mysqlnd \
       --enable-zip \
       --enable-exif \
       --enable-ftp \
       --enable-mbstring \
       --enable-mbregex \
       --enable-fpm \
       --enable-bcmath \
       --enable-pcntl \
       --enable-soap \
       --enable-sockets \
       --enable-shmop \
       --enable-sysvmsg \
       --enable-sysvsem \
       --enable-sysvshm \
       --enable-fileinfo \
       --with-curl \
       --with-iconv \
       --with-gettext \
       --with-xsl \
       --with-xmlrpc \
       --with-mysqli=mysqlnd \
       --with-pdo-mysql=mysqlnd \
       --with-gd \
       --with-jpeg-dir \
       --with-png-dir \
       --with-zlib-dir \
       --with-freetype-dir \
       --with-pcre-regex \
       --with-zlib \
       --with-bz2 \
       --with-openssl \
       --with-mhash 

make -j$(nproc)
make install
rm -rf /home/worker/php/lib/php.ini
cp -f php.ini-development /home/worker/php/lib/php.ini
rm -rf /home/worker/src/php*
echo "---------- Install PHP...done ----------"

# Install PHP igbinary extension
echo "---------- Install PHP igbinary extension ----------"
cd /home/worker/src
wget -q -O igbinary-${IGBINARY_VERSION}.tgz https://mrzfiles.oss-cn-shenzhen.aliyuncs.com/resource/igbinary-${IGBINARY_VERSION}.tgz
tar zxf igbinary-${IGBINARY_VERSION}.tgz
cd igbinary-${IGBINARY_VERSION}
/home/worker/php/bin/phpize
./configure --with-php-config=/home/worker/php/bin/php-config
make clean
make -j$(nproc)
make install
rm -rf /home/worker/src/igbinary-*
echo "---------- Install PHP igbinary extension...done ---------- "

# Install PHP redis extension
echo "---------- Install PHP redis extension... ---------- "
cd /home/worker/src
wget -q -O redis-${PHPREDIS_VERSION}.tgz https://mrzfiles.oss-cn-shenzhen.aliyuncs.com/resource/redis-${PHPREDIS_VERSION}.tgz
tar zxf redis-${PHPREDIS_VERSION}.tgz
cd redis-${PHPREDIS_VERSION}
/home/worker/php/bin/phpize
./configure --with-php-config=/home/worker/php/bin/php-config
make clean
make -j$(nproc)
make install
rm -rf /home/worker/src/redis-*
echo "---------- Install PHP redis extension...done. ---------- "

# Install PHP xdebug extension
echo "---------- Install PHP xdebug extension... ---------- "
cd /home/worker/src
wget -q -O xdebug-${XDEBUG_VERSION}.tgz https://mrzfiles.oss-cn-shenzhen.aliyuncs.com/resource/xdebug-${XDEBUG_VERSION}.tgz
tar zxf xdebug-${XDEBUG_VERSION}.tgz
cd xdebug-${XDEBUG_VERSION}
/home/worker/php/bin/phpize
./configure --with-php-config=/home/worker/php/bin/php-config
make clean
make -j$(nproc)
make install
rm -rf /home/worker/src/xdebug-*
echo "---------- Install PHP xdebug extension...done ---------- "

ln -s /home/worker/php/bin/php /usr/local/bin/php

# Install composer
echo "---------- Install Composer... ---------- "
export COMPOSER_HOME=/home/worker/
wget https://getcomposer.org/download/1.8.6/composer.phar -O /usr/local/bin/composer
chmod a+x /usr/local/bin/composer
composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/
echo "---------- Install Composer...done ---------- "