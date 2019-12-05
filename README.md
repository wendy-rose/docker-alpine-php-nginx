# 基于Alpine的PHP和Nginx镜像

## 镜像内容

* Alpine-3.10
* Supervisor
* Re2c-1.1.1
* ImageMagick-7.0.8
* Yaml-0.2.2
* Hiredis-0.14.0
* Libmemcached-1.0.18
* PHP-7.2.25
* PHP-Redis-5.0.0
* PHP-Memcached-3.1.3
* PHP-Igbinary-3.0.1
* PHP-Xdebug-2.7.2
* PHP-Swoole-4.4.12
* PHP-Yaml-2.0.4
* PHP-Mongodb-1.5.5
* PHP-Yaf-3.0.8
* PHP-Imagick-3.4.4
* PHP-Inotify-2.0.0
* PHP-Event-2.5.3
* Nginx-1.16.0

## 安装与运行

### 在线仓库

`docker pull registry.cn-hangzhou.aliyuncs.com/base-php/alpine-php-nginx:3.0`

### 构建

从github拉取代码后，在根目录执行`docker build -t [image name]:[tag] .`

### 运行

在线拉取后，可以通过`docker images`查看镜像，整个镜像大小为524M。

然后执行`docker run -d --name=[your container name] -p 80:80 [image name]`，

启动后容器内会启动PHP-FPM和Nginx，同时对外暴露80端口

注意：容器启动后是有开启opcache，请注意缓存问题。

## 容器内一些文件和位置

这里是一些相关配置文件和位置，方便你进行镜像的定制：

`/home/worker/data` 数据目录，这里放一些诸如你的代码或者日志等待

`/home/worker/data/www` 固定的web目录。当然你可以在`/home/worker/php/etc/php-fpm.ini`中修改它。


下面是一些固定的文件路径：

`/home/worker/data/php/logs/php_errors.log` php的错误日志

`/home/worker/data/php/logs/opcache_errors.log` opcache 错误日志

`/home/worker/data/php/run/php-fpm.pid` php pid 地址。

`/home/worker/data/php/logs/php-fpm.log` php-fpm 日志。

`/home/worker/data/php/logs/www.access.log` access log

`/home/worker/data/nginx/logs/` Nginx的log文件

`/home/worker/data/supervisor/logs/` Supervisor的log文件

PHP安装在`/home/worker/php`中，其中的etc目录是PHP扩展目录的配置地方，每个扩展都是以ini文件分开配置，其他的文件和目录都是基本的PHP安装时的文件或者目录

Nginx安装在`/home/worker/nginx`，其中Nginx的server配置文件是在`/home/worker/nginx/conf.d`，还有`/home/worker/nginx/certs`目录为https证书放置的地方

Supervisor守护进程，PHP-FPM和Nginx都是用此托管，`/etc/supervisord.conf`为Supervisor的配置，如果想添加守护进程，文件请以`.conf`后缀，放置到`/etc/supervisor/conf.d`，然后重启镜像即可

`/etc/my_init.d/init.sh` 是镜像启动脚本文件，如果有想在镜像启动时执行的，可以在`/etc/my_init.d/`目录下添加shell文件，然后在init.sh添加执行shell文件即可，文件内容如下：

```shell
#!/bin/bash
set -e

su - worker -s /bin/sh -c "/usr/bin/supervisord -n -c /etc/supervisord.conf"
```

## 打包项目镜像

这里主要讲如何利用此镜像将项目打包成一个镜像。首先在项目的根目录创建一个docker文件夹和Dockerfile的文件。其中docker文件主要是放项目的Nginx的server配置文件，
Dockerfile是项目的镜像构建文件。下面我以laravel为例子说一下。

* 创建docker文件，并且在里面创建trade-pay.conf文件，文件内容如下：

```conf
server {
    listen 80;
    server_name trade.test.cc;
    index index.html index.htm index.php;
    root /home/worker/data/www/trade-pay/public;
    location ^~ /.git
    {
	   return 404;
    }
    location / {
        if (!-f $request_filename){
            rewrite ^/(.*)$ /index.php?/$1 last;
            break;
        }
    }
    location ~ .*\.(php|php5)?$
    {
        fastcgi_pass unix:///dev/shm/php-fpm.sock;
        fastcgi_index index.php;
        include /home/worker/nginx/conf/fastcgi_params;
    }
    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }
    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }
    access_log  /home/worker/data/nginx/logs/trade.log main;
    error_log   /home/worker/data/nginx/logs/trade.error.log;
}
```

* 创建Dockerfile文件，内容如下：

```dockerfile
FROM registry.cn-hangzhou.aliyuncs.com/base-php/alpine-php-nginx:3.0
MAINTAINER wendylin6970@gmail.com

# source codes
RUN mkdir -p /home/worker/data/www/trade-pay
COPY . /home/worker/data/www/trade-pay

# init auth
RUN chmod -R 777 /home/worker/data/www/trade-pay/storage && \
     chmod -R 777 /home/worker/data/www/trade-pay/bootstrap/cache

# copy trade-pay nginx config
COPY docker/trade-pay.conf /home/worker/nginx/conf.d/trade-pay.conf

EXPOSE 80
```

执行`docker build -t [your image name] .`，就可以看成功构建了镜像，接着执行

`docker run -d --name=[your container name] -p 80:80 [image name]`,

通过`docker ps -a`就可以查看容器已经启动，这样就可以使用。


## 开发环境搭建

上面讲述的如何将项目打包成一个镜像，在开发环境下我们使用docker-compose进行容器编排，由于该镜像已经包含了Nginx，因此只需将该镜像与其他服务链接起来。

我们应该有一个目录专门放这些配置文件，假设有个目录叫docker-dev，它的目录结构大概是这样的：

```
docker-dev            部署目录
├─mysql               数据库配置目录
│  ├─my.cnf           公共模块目录（可更改）
│  ├─conf.d           模块目录(可更改)
│  │  ├─my.cnf     模块配置文件
│  │  ├─mysqld_safe_syslog.cnf  模块函数文件
│  │  └─ ...          更多类库目录
├─nginx               Nginx配置目录
│  ├─conf.d           vhost配置目录
│  ├─nginx.conf       要覆盖的nginx.conf
├─php                 PHP配置目录
│  ├─php-fpm.conf 	  要覆盖的php-fpm conf
│  ├─php-fpm.ini 	  要覆盖的php-fpm.ini
│  ├─php.d            扩展配置目录
│  │  ├─xdebug.ini    要启用 Xdebug，在该ini文件里填入 `zend_extension=xdebug.so`
├─redis               缓存配置目录
│  ├─redis.conf       要覆盖的redis.conf
├─supervisor          supervisor守护进程
│  ├─conf.d           supervisor配置文件
├─docker-compose.yml  docker-compose 编排文件
├─init.sh               启动脚本
```

接下来看一下docker-compose.yml，具体的解析看注释即可：

```docker
version: '2'
services:
  php:
    restart: always
    image: registry.cn-hangzhou.aliyuncs.com/base-php/alpine-php-nginx:3.0
    container_name: web
    volumes:
    - /d/WWW:/home/worker/data/www  # 将宿主机的代码目录映射到容器的www目录
	# ... 如果有更多的开发中业务代码，一并放到这里并映射到容器
    - ./php/php-fpm.ini:/home/worker/php/etc/php-fpm.ini # 用开发配置覆盖容器里的fpm配置
    - ./php/php-fpm.conf:/home/worker/php/etc/php-fpm.conf # 同上
    - ./php/php.d/xdebug.ini:/home/worker/php/etc/php.d/xdebug.ini # 开发环境开启xdebug。
    - ./nginx/nginx.conf:/home/worker/nginx/conf/nginx.conf # 用开发配置覆盖容器里的nginx配置文件
    - ./nginx/conf.d:/home/worker/nginx/conf.d #nginx Vhost目录映射
    - ./init.sh:/etc/my_init.d/init.sh # 业务的启动配置，一般是启动php-fpm和nginx，也可以按需写其他执行脚本
    ports:
      - "80:80"
      - "39001:39001"
      - "39002:39002"
    networks:
      - new
    depends_on:
      - redis
      - memcached
      - mysql
    extra_hosts:
      - "trade.test.cc:192.168.6.53" # 将一个用于开发的虚拟域名指向到宿主机的IP。
  redis:
    restart: always
    image:  registry.cn-hangzhou.aliyuncs.com/qyyteam/redis:1.0.0
    ports:
      - "6379:6379"
    volumes:
      - /d/persistent/redis:/data # 左边的目录是我宿主机上的持久化redis存储目录，这里换成自己的。
      - ./redis/redis.conf:/usr/local/etc/redis/redis.conf # 用开发配置覆盖redis容器里的配置
    networks:
      - new
    container_name: redis
  mysql:
	image: daocloud.io/library/mysql:5.7.20
    restart: always
    ports:
      - "3306:3306"
    volumes:
      - /d/server/MySql/data:/var/lib/mysql
      # 左边的目录是我宿主机上的持久化Mysql存储目录，这里换成一个全新的M或者已经存在的数据库目录。
    environment:
      - MYSQL_ROOT_PASSWORD=root
      - MYSQL_USER=root
      - MYSQL_PASSWORD=root
    networks:
      - new
    container_name: mysql
networks:
    new:
```

通过上述的编排，我们已经PHP+Nginx，mysql，redis服务链接在一起，如果你还需要其他的服务要用到，需要你自己动手编排实现。
再看一下init.sh文件，这里面只是启动PHP+Nginx的服务，文件内容已经在容器内一些文件和位置说了。

最后在docker-compose.yml文件目录中，使用`docker-compose -p dev up -d`，如果有多个docker-compose.yml，可以使用-f来区分启动不同的编排服务。
这样PHP+Nginx，mysql，redis服务都启动起来了。
