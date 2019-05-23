FROM golang as configurability_php
MAINTAINER brian.wilkinson@1and1.co.uk
WORKDIR /go/src/github.com/1and1internet/configurability
RUN git clone https://github.com/1and1internet/configurability.git . \
	&& make php\
	&& echo "configurability php plugin successfully built"

FROM alpine as ioncube_loader
RUN apk add git \
	&& git -c http.sslVerify=false clone https://git.dev.glo.gb/cloudhostingpublic/ioncube_loader \
	&& tar zxf ioncube_loader/ioncube_loaders_lin_x86-64.tar.gz


FROM 1and1internet/debian-9-nginx
MAINTAINER brian.wilkinson@1and1.co.uk
ARG DEBIAN_FRONTEND=noninteractive
ARG PHPVER=7.3
COPY files /
COPY --from=configurability_php /go/src/github.com/1and1internet/configurability/bin/plugins/php.so /opt/configurability/goplugins
RUN \
    apt-get update && \
    apt-get install -y imagemagick graphicsmagick curl && \
    apt-get install -y php${PHPVER}-bcmath php${PHPVER}-bz2 php${PHPVER}-cli php${PHPVER}-common php${PHPVER}-curl php${PHPVER}-dba php${PHPVER}-fpm php${PHPVER}-gd php${PHPVER}-gmp php${PHPVER}-imap php${PHPVER}-intl php${PHPVER}-ldap php${PHPVER}-mbstring php${PHPVER}-mysql php${PHPVER}-odbc php${PHPVER}-pgsql php${PHPVER}-recode php${PHPVER}-snmp php${PHPVER}-soap php${PHPVER}-sqlite php${PHPVER}-tidy php${PHPVER}-xml php${PHPVER}-xmlrpc php${PHPVER}-xsl php${PHPVER}-zip && \
    apt-get install -y php-gnupg php-imagick php-mongodb php-fxsl && \
    mkdir /tmp/composer/ && \
    cd /tmp/composer && \
    curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    chmod a+x /usr/local/bin/composer && \
    cd / && \
    rm -rf /tmp/composer && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /etc/nginx/sites-enabled/default /etc/nginx/sites-available/* && \
    sed -i -e 's/^user = www-data$/;user = www-data/g' /etc/php/${PHPVER}/fpm/pool.d/www.conf && \
    sed -i -e 's/^group = www-data$/;group = www-data/g' /etc/php/${PHPVER}/fpm/pool.d/www.conf && \
    sed -i -e 's/^listen.owner = www-data$/;listen.owner = www-data/g' /etc/php/${PHPVER}/fpm/pool.d/www.conf && \
    sed -i -e 's/^listen.group = www-data$/;listen.group = www-data/g' /etc/php/${PHPVER}/fpm/pool.d/www.conf && \
    sed -i -e 's/max_execution_time = 30/max_execution_time = 300/g' /etc/php/${PHPVER}/fpm/php.ini && \
    sed -i -e 's/upload_max_filesize = 2M/upload_max_filesize = 256M/g' /etc/php/${PHPVER}/fpm/php.ini && \
    sed -i -e 's/post_max_size = 8M/post_max_size = 512M/g' /etc/php/${PHPVER}/fpm/php.ini && \
    sed -i -e 's/memory_limit = 128M/memory_limit = 512M/g' /etc/php/${PHPVER}/fpm/php.ini && \
    sed -i -e 's/fastcgi_param  SERVER_PORT        $server_port;/fastcgi_param  SERVER_PORT        $http_x_forwarded_port;/g' /etc/nginx/fastcgi.conf && \
    sed -i -e 's/fastcgi_param  SERVER_PORT        $server_port;/fastcgi_param  SERVER_PORT        $http_x_forwarded_port;/g' /etc/nginx/fastcgi_params && \
    sed -i -e '/sendfile on;/a\        fastcgi_read_timeout 300\;' /etc/nginx/nginx.conf && \
    mkdir --mode 777 /var/run/php && \
    chmod 755 /hooks /var/www && \
    chmod -R 777 /var/www/html /var/log && \
    sed -i -e 's/index index.html/index index.php index.html/g' /etc/nginx/sites-enabled/site.conf && \
    chmod 666 /etc/nginx/sites-enabled/site.conf && \
    nginx -t && \
    mkdir -p /run /var/lib/nginx /var/lib/php && \
    chmod -R 777 /run /var/lib/nginx /var/lib/php /etc/php/${PHPVER}/fpm/php.ini

COPY --from=ioncube_loader /ioncube/ioncube_loader_lin_${PHPVER}.so /usr/lib/php/20170718/
