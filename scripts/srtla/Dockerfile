# Polaris Relay - Récepteur SRTLA (BELABOX srtla_rec)
# Base Debian (glibc) pour rester aligné sur la cible Debian 12 : le binaire
# produit est identique à une compilation native sur le VPS.

FROM debian:bookworm-slim AS build

ARG SRTLA_REF=main
RUN apt-get update \
    && apt-get install -y --no-install-recommends git build-essential ca-certificates \
    && rm -rf /var/lib/apt/lists/*
RUN git clone https://github.com/BELABOX/srtla /src \
    && cd /src \
    && git checkout "${SRTLA_REF}" \
    && make

FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends tini \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --system --create-home --shell /usr/sbin/nologin polaris

COPY --from=build /src/srtla_rec /usr/local/bin/srtla_rec
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/srtla_rec

USER polaris

# UDP : port d'écoute SRTLA (agrégation des liens depuis IRL Pro)
EXPOSE 5000/udp

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
