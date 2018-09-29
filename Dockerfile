FROM php:7.2-fpm

WORKDIR /app

# Versions
ENV COMPOSER_VERSION 1.1.2

RUN apt-get update && \
    apt-get install -y apt-transport-https autoconf ca-certificates curl g++ gcc git \
        libfontconfig1 libjpeg62-turbo-dev libpng-dev libxml2-dev libxrender1 make \
        zip zlib1g-dev nodejs yarn && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --version=${COMPOSER_VERSION} && \
    chmod +x /usr/local/bin/composer && \
    rm -rf /var/lib/apt/lists/*

RUN pecl install apcu && \
    echo "extension=apcu.so" > /usr/local/etc/php/conf.d/apcu.ini && \
    docker-php-ext-install bcmath && \
    docker-php-ext-configure gd --with-jpeg-dir=/usr/include/ && \
    docker-php-ext-install -j$(nproc) gd zip pdo pdo_mysql soap sockets pcntl opcache shmop && \
    echo "opcache.enable_cli=1" > /usr/local/etc/php/conf.d/opcache-cli.ini && \
    chown www-data.www-data -R $(php-config --prefix)/etc/php/conf.d

ADD ./composer.json ./composer.lock /app/

RUN composer global require hirak/prestissimo && \
		/usr/local/bin/composer install --no-autoloader --no-scripts

COPY . /app

RUN /usr/local/bin/composer install

RUN mkdir -p \
        bootstrap/cache \
        storage/app \
        storage/framework/cache \
        storage/framework/sessions \
        storage/framework/views \
        storage/logs && \
    mv envs/.env.production .env && \
    chown www-data:www-data /app && \
    chown -R www-data:www-data storage bootstrap/cache/

#USER www-data

ENTRYPOINT ["bin/entrypoint.sh"]
CMD ["web"]
