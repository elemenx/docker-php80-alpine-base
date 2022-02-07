FROM php:8.1-cli-alpine

ENV CFLAGS="$CFLAGS -D_GNU_SOURCE"

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Add Repositories
RUN rm -f /etc/apk/repositories &&\
    echo "http://dl-cdn.alpinelinux.org/alpine/v3.15/main" >> /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/v3.15/community" >> /etc/apk/repositories

# Add Build Dependencies
RUN apk add --no-cache --virtual .build-deps  \
    zlib-dev \
    libjpeg-turbo-dev \
    libjpeg-turbo \
    libpng-dev \
    libxml2-dev \
    jpeg-dev \
    bzip2-dev \
    libzip-dev \
    gmp-dev \
    gettext-dev

# Add Production Dependencies
RUN apk add --update --no-cache \
    file \
    git \
    jpegoptim \
    pngquant \
    optipng \
    autoconf \
    automake \
    g++ \
    libtool \
    libzip \
    make \
    texinfo \
    gettext \
    supervisor \
    curl \
    tzdata \
    nano \
    icu-dev \
    freetype-dev \
    imagemagick-dev \
    imagemagick \
    mysql-client

# Configure & Install Extension
RUN docker-php-ext-configure \
    opcache --enable-opcache &&\
    docker-php-ext-configure gd --with-freetype --with-jpeg &&\
    docker-php-ext-install \
    opcache \
    mysqli \
    pdo \
    pdo_mysql \
    sockets \
    intl \
    gd \
    gmp \
    exif \
    zip \
    bz2 \
    pcntl \
    bcmath

RUN pecl install swoole && docker-php-ext-enable swoole && \
    pecl install redis && docker-php-ext-enable redis

ARG IMAGICK_LAST_COMMIT='52ec37ff633de0e5cca159a6437b8c340afe7831'

RUN mkdir -p /usr/src/php/ext/imagick && \
    curl -fsSL https://github.com/Imagick/imagick/archive/${IMAGICK_LAST_COMMIT}.tar.gz | tar xvz -C /usr/src/php/ext/imagick --strip 1 && \
    docker-php-ext-install imagick

# Add Composer
RUN curl -s https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer && \
    composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/

ENV COMPOSER_ALLOW_SUPERUSER=1
ENV COMPOSER_MEMORY_LIMIT=-1
ENV PATH="./vendor/bin:$PATH"

# Remove Build Dependencies
RUN apk del -f .build-deps && \
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo 'Asia/Shanghai' > /etc/timezone

# Setup Working Dir
WORKDIR /var/www/html

CMD ["/usr/bin/supervisord"]
