FROM hexpm/elixir:1.15.4-erlang-24.3.4.13-debian-bullseye-20230612 AS builder

ENV MIX_ENV=prod

WORKDIR /explorer

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y git
RUN git clone https://github.com/lambdaclass/stark_compass_explorer.git . && \
    git reset --hard 4618aca68dbf0c037dbdfeac31603a9809592f24 && \
    # this migration file causes an error when building the image due to
    # https://github.com/lambdaclass/stark_compass_explorer/issues/309
    # but we are starting from a fresh database so we can just remove it
    rm priv/repo/migrations/20230929141348_change_blocks_pk.exs
RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.get 
RUN mix assets.deploy
RUN mix phx.digest
RUN mix compile
RUN mix release
RUN mix phx.gen.release

FROM elixir:1.15.4-otp-24
ENV MIX_ENV=prod

WORKDIR /explorer

COPY --from=builder /explorer/_build/$MIX_ENV/rel/starknet_explorer .

EXPOSE 4000

CMD ["sh", "-c", "/explorer/bin/starknet_explorer eval 'StarknetExplorer.Release.migrate' && /explorer/bin/starknet_explorer start"]
