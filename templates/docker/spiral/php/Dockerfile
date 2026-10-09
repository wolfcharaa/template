FROM php:8.4-cli-alpine AS base

RUN apk add --no-cache \
        bash \
        curl \
        icu-dev \
        libzip-dev \
        linux-headers \
        lua5.3 \
        postgresql-dev \
        shadow \
        su-exec \
        tar \
        unzip \
        wget \
        zip \
    && docker-php-ext-configure pcntl --enable-pcntl \
    && docker-php-ext-install -j"$(nproc)" \
        bcmath \
        intl \
        pcntl \
        pdo_pgsql \
        pgsql \
        sockets \
        zip \
    && docker-php-ext-enable opcache

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

ARG RR_VERSION=2025.1.15
RUN set -eux; \
    case "$(uname -m)" in \
        x86_64) RR_ARCH=amd64 ;; \
        aarch64) RR_ARCH=arm64 ;; \
        *) echo "Unsupported arch: $(uname -m)" >&2; exit 1 ;; \
    esac; \
    wget -qO /tmp/rr.tar.gz \
        "https://github.com/roadrunner-server/roadrunner/releases/download/v${RR_VERSION}/roadrunner-${RR_VERSION}-linux-${RR_ARCH}.tar.gz"; \
    tar -xzf /tmp/rr.tar.gz -C /tmp; \
    mv "/tmp/roadrunner-${RR_VERSION}-linux-${RR_ARCH}/rr" /usr/local/bin/rr; \
    chmod +x /usr/local/bin/rr; \
    rm -rf /tmp/rr.tar.gz /tmp/roadrunner-*

FROM base AS final

WORKDIR /var/www/html/app

COPY docker/php/php.ini /usr/local/etc/php/conf.d/zzz-custom.ini
COPY docker/templates/php-runtime.ini.tpl /usr/local/etc/php/conf.d/zz-runtime.ini.tpl
COPY docker/lua /usr/local/share/docker-lua
COPY docker/scripts/render-runtime-php-ini.lua /usr/local/bin/render-runtime-php-ini
COPY docker/php/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh /usr/local/bin/render-runtime-php-ini

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 8080
CMD ["rr", "serve", "-c", ".rr.yaml"]

FROM final AS app

ARG COMPOSER_INSTALL_FLAGS="--no-dev --optimize-autoloader"

ENV APP_SKIP_COMPOSER_INSTALL=1 \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME=/tmp/composer \
    COMPOSER_PROCESS_TIMEOUT=1200

COPY --chown=www-data:www-data app/composer.json app/composer.lock ./

RUN mkdir -p /tmp/composer \
    && chown -R www-data:www-data /var/www/html/app /tmp/composer \
    && COMPOSER_HOME=/tmp/composer su-exec www-data composer install ${COMPOSER_INSTALL_FLAGS} --no-interaction --prefer-dist --no-progress --no-scripts

COPY --chown=www-data:www-data app/ ./

RUN composer_dump_flags="--optimize" \
    && case " ${COMPOSER_INSTALL_FLAGS} " in *" --no-dev "*) composer_dump_flags="${composer_dump_flags} --no-dev" ;; esac \
    && su-exec www-data composer dump-autoload ${composer_dump_flags} --no-interaction \
    && mkdir -p runtime/cache runtime/logs runtime/session runtime/snapshots runtime/tmp \
    && chown -R www-data:www-data runtime vendor /tmp/composer
