FROM php:7.0-fpm

RUN apt-get update &&\
    apt-get install --no-install-recommends --assume-yes --quiet ca-certificates curl git &&\
    rm -rf /var/lib/apt/lists/*

RUN pecl install xdebug-2.5.5 && docker-php-ext-enable xdebug
RUN echo 'zend_extension="/usr/local/lib/php/extensions/no-debug-non-zts-20151012/xdebug.so"' >> /usr/local/etc/php/php.ini
RUN echo 'xdebug.remote_port=9000' >> /usr/local/etc/php/php.ini
RUN echo 'xdebug.remote_enable=1' >> /usr/local/etc/php/php.ini
RUN echo 'xdebug.remote_connect_back=1' >> /usr/local/etc/php/php.ini

RUN echo 'xdebug.profiler_enable=On' >> /usr/local/etc/php/php.ini
RUN echo 'xdebug.profiler_output_dir=/profiler' >> /usr/local/etc/php/php.ini
RUN echo 'xdebug.profiler_enable_trigger=On' >> /usr/local/etc/php/php.ini



RUN apt-get update && apt-get install -y \
	mc \
	git \
	libreoffice-core \
	libreoffice-writer \
        libmcrypt-dev \        
        curl  \
        libpng-dev \
        libmagickwand-dev \
        mysql-client
        

COPY conf/ /usr/local/etc/php-fpm.d/


RUN docker-php-ext-install pdo pdo_mysql mysqli mysqli gd iconv zip
#curl 
RUN pecl install imagick && docker-php-ext-enable imagick

CMD ["php-fpm"]

RUN curl -sS https://getcomposer.org/installer | php \
    &&mv composer.phar /usr/local/bin/composer \
    &&ln -s /usr/local/bin/composer /usr/bin/composer \
    &&git clone https://github.com/drush-ops/drush.git /usr/local/src/drush \
    &&cd /usr/local/src/drush \
    &&git checkout 7.4.0 \
    &&ln -s /usr/local/src/drush/drush /usr/bin/drush \
    &&composer install 

RUN docker-php-ext-install calendar

#RUN sed -i -e "s|^;date.timezone =.*$|date.timezone = Europe/Moscow|" /etc/php.ini

