FROM php:8.2-fpm
USER 0

ARG APP_ENV
ENV APP_ENV $APP_ENV

# Copy composer.lock and composer.json
COPY composer.lock composer.json /var/www/

# Set working directory
WORKDIR /var/www

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    locales \
    zip \
    jpegoptim optipng pngquant gifsicle \
    vim \
    unzip \
    git \
    curl \
    libzip-dev

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install extensions
RUN docker-php-ext-install zip exif pcntl
RUN pecl install -o -f mongodb

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

#RUN if [ -z "`getent group www`" ]; then \
#  addgroup -g 1000 -S www ; \
#fi
#
#RUN if [ -z "`getent passwd www`" ]; then \
#  useradd -u 1000 -ms /bin/bash -g www www ; \
#fi

RUN if [ -z "`getent group www-data`" ]; then \
  addgroup -g 1000 -S www-data ; \
fi

RUN if [ -z "`getent passwd www-data`" ]; then \
  adduser -u 1000 -D -S -G www-data -h /app -g www-data www-data ; \
fi

# Xdebug
RUN pecl install -f xdebug && \
    docker-php-ext-enable xdebug && \
    echo "xdebug.mode=debug,coverage" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.remote_handler=dbgp" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.idekey=app" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.start_with_request=yes" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.client_port=9003" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.client_host=host.docker.internal" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    docker-php-ext-enable xdebug;

# Copy existing application directory contents
COPY . /var/www

# Copy existing application directory permissions
COPY --chown=www:www . /var/www

# Change current user to www--data
USER www-data

# Expose port 81 and start php-fpm server
EXPOSE 81
CMD ["php-fpm"]
