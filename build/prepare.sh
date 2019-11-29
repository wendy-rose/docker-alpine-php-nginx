#!/bin/bash
set -e

SRC_DIR=/home/worker/src

# Init base environment
echo "---------- Preparing APT repositories ----------"
cp /etc/apk/repositories /etc/apk/repositories.bak

echo "http://mirrors.aliyun.com/alpine/latest-stable/main/" > /etc/apk/repositories
echo "http://mirrors.aliyun.com/alpine/latest-stable/community/" >> /etc/apk/repositories

apk update
# 构建环境时时所需的包，这些包会在构建完成时删除
apk add --no-cache --virtual .build-deps \
        autoconf \
        dpkg-dev dpkg \
        file \
        g++ \
        gcc \
        libc-dev \
        make \
        pkgconf \
        tar \
        unzip\
        xz \
        libressl \
        coreutils \
        curl-dev \
        libedit-dev \
        libressl-dev \
        sqlite-dev \
        imap-dev \
        libmcrypt-dev \
        zlib-dev \
        gnupg \
        gd-dev \
        geoip-dev\
        bzip2-dev

# 构建环境时时所需的包，需要保留的包
apk add --no-cache --virtual .fetch-deps \
        ca-certificates \
        bash \
        tzdata \
        linux-headers\
        curl \
        pcre-dev \
        supervisor \
        libxml2-dev \
        libpng-dev \
        libjpeg-turbo-dev \
        libxslt-dev \
        freetype-dev \
        gettext-dev

# Config timezone/passwd/networking
echo "---------- Config timezone/passwd/networking... ----------"
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo 'Asia/Shanghai' > /etc/timezone
echo "root:root" | chpasswd
echo "---------- Config timezone/passwd/networking...done ----------"

# Add user worker
set -x \
    && addgroup -g 1000 -S worker \
    && adduser -u 1000 -D -S -G worker worker
echo "worker:worker" | chpasswd
echo 'worker  ALL=(ALL)  NOPASSWD: ALL' >> /etc/sudoers

# mkdir src dir
mkdir -p ${SRC_DIR}
