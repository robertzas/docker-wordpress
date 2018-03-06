FROM alpine:3.7

ENV SSH_PASSWD "root:Docker!"

RUN addgroup -g 82 -S www-data \
    && adduser -u 82 -D -S -G www-data www-data

# Install packages from stable repo's
RUN apk --no-cache upgrade \
    && apk --no-cache add supervisor curl bash \
    # Setup SSH
    openssh \
    && /usr/bin/ssh-keygen -A \
    && echo "$SSH_PASSWD" | chpasswd 
COPY config/sshd_config /etc/ssh/


# Install packages from testing repo's
RUN apk --no-cache add \
    php7 \
    php7-fpm \
    php7-mysqli \
    php7-json \
    php7-openssl \
    php7-curl \
    php7-zlib \
    php7-xml \
    php7-phar \
    php7-intl \
    php7-dom \
    php7-xmlreader \
    php7-ctype \
    php7-mbstring \
    php7-gd \
    php7-memcached \
    php7-opcache \
    nginx \
    mariadb mariadb-client \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/main/ \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/

# Wordpress
ENV WORDPRESS_VERSION 4.9.4
ENV WORDPRESS_SHA1 0e630bf940fd586b10e099cd9195b3e825fb194c

RUN mkdir -p /usr/src

# Upstream tarballs include ./wordpress/ so this gives us /usr/src/wordpress
RUN curl -o wordpress.tar.gz -SL https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz \
    && echo "$WORDPRESS_SHA1 *wordpress.tar.gz" | sha1sum -c - \
    && tar -xzf wordpress.tar.gz -C /usr/src/ \
    && rm wordpress.tar.gz \
    && chown -R www-data:www-data /usr/src/wordpress

# Copy WP config
COPY config/wp-secrets.php /usr/src/wordpress
COPY config/wp-config.php /usr/src/wordpress
RUN chown -R www-data:www-data /usr/src/wordpress \
    && chmod -R 777 /usr/src/wordpress

# Copy other configs
COPY config/nginx.conf /etc/nginx/nginx.conf
COPY config/fpm-pool.conf /etc/php7/php-fpm.d/zzz_custom.conf
COPY config/php.ini /etc/php7/conf.d/zzz_custom.ini
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY config/my.cnf /etc/mysql/my.cnf

# Make logs dir
RUN mkdir -p /home/LogFiles/

# Entrypoint to copy wp-content
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]

EXPOSE 2222 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
