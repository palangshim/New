FROM php:8.3-apache-bookworm
COPY rhymix.tar.gz entrypoint.sh /tmp/
RUN apt-get update \
 && apt-get install -y --no-install-recommends libcurl4-openssl-dev libfreetype6-dev libicu-dev libjpeg62-turbo-dev libonig-dev libpng-dev libwebp-dev libzip-dev \
 && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
 && docker-php-ext-install -j2 bcmath curl exif gd intl mbstring mysqli opcache pdo_mysql zip \
 && a2enmod rewrite headers setenvif \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /usr/src/rhymix \
 && tar -xzf /tmp/rhymix.tar.gz --strip-components=1 -C /usr/src/rhymix \
 && rm /tmp/rhymix.tar.gz \
 && printf '<Directory /var/www/html>\nAllowOverride All\nRequire all granted\n</Directory>\nSetEnvIf X-Forwarded-Proto "^https$" HTTPS=on\nServerName localhost\n' > /etc/apache2/conf-available/rhymix.conf \
 && a2enconf rhymix \
 && printf 'date.timezone=Asia/Seoul\nmemory_limit=256M\nupload_max_filesize=64M\npost_max_size=72M\nmax_execution_time=120\nexpose_php=Off\n' > /usr/local/etc/php/conf.d/rhymix.ini \
 && mv /tmp/entrypoint.sh /usr/local/bin/rhymix-entrypoint \
 && chmod 755 /usr/local/bin/rhymix-entrypoint
ENTRYPOINT ["rhymix-entrypoint"]
CMD ["apache2-foreground"]
