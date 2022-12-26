FROM --platform=$TARGETPLATFORM debian:11.6
ARG TARGETOS
ARG TARGETARCH
ENV LANG='en_US.UTF-8' \
    LANGUAGE='en_US:en' \
    LC_ALL='en_US.UTF-8'
RUN set -ex; \
    apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    \
    tzdata locales \
    postgresql supervisor \
    ; \
    rm -rf /var/lib/apt/lists/*; \
    \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen en_US.UTF-8
USER postgres
RUN set -ex; \
    PG_ETC="/etc/postgresql/13/main"; \
    PG_SU="casdoor"; \
    PG_SU_PWD="casdoor"; \
    /etc/init.d/postgresql start && \
      psql --command "CREATE USER ${PG_SU} WITH SUPERUSER PASSWORD '${PG_SU_PWD}';" && \
      createdb -O ${PG_SU} casdoor && \
      echo "host all  all    0.0.0.0/0  md5" >> "${PG_ETC}/pg_hba.conf" && \
      echo "listen_addresses='*'" >> "${PG_ETC}/postgresql.conf" && \
    /etc/init.d/postgresql stop
USER root
WORKDIR /
COPY --from=casbin/casdoor:v1.197.0 /web/build /web/build
COPY bin/casdoor-$TARGETOS-$TARGETARCH /casdoor
COPY swagger /swagger
COPY hack/docker/conf/app.conf /conf/app.conf
COPY hack/docker/etc/supervisord /etc/supervisord
CMD ["supervisord", "-c", "/etc/supervisord/supervisord.conf"]
