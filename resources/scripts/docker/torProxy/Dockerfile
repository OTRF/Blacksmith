FROM alpine:latest

RUN apk add --no-cache curl tor
COPY torrc /etc/tor/torrc
RUN chown -R tor /etc/tor

EXPOSE 9050

HEALTHCHECK --interval=60s --timeout=15s --start-period=20s \
    CMD curl -s --socks5 127.0.0.1:9050 'https://check.torproject.org/api/ip' | grep -qm1 -E '"IsTor"\s*:\s*true'

USER tor

CMD ["tor"]