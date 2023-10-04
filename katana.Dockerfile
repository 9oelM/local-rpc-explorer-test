FROM rust:slim-buster as builder
RUN apt-get -y update; \
    apt-get install -y --no-install-recommends \
    curl libssl-dev make clang-11 g++ llvm protobuf-compiler \
    pkg-config libz-dev zstd git; \
    apt-get autoremove -y; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /dojo

RUN git clone https://github.com/dojoengine/dojo && \
    cd dojo && \
    # need to use the very latest version of Katana (maybe installing from source from main) 
    # as there are a few unrelased bug fixes that are quite important
    git reset --hard d4f36a226515d4ea6c75a7614db584f33f075e56 && \
    cargo install --path ./crates/katana --locked --force

FROM debian:buster-slim

RUN apt-get -y update; \
    apt-get install -y --no-install-recommends \
        curl; \
    apt-get autoremove -y; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

ENV HEALTH_CHECK_PORT=5050

HEALTHCHECK --interval=3s --timeout=5s --start-period=1s --retries=5 \
  CMD curl --request POST \
    --header "Content-Type: application/json" \
    --data '{"jsonrpc": "4.0","method": "starknet_chainId","id":1}' http://localhost:${HEALTH_CHECK_PORT} || exit 1

COPY --from=builder /dojo/dojo/target/release/katana /usr/local/bin/katana

CMD ["katana", "--disable-fee"]
