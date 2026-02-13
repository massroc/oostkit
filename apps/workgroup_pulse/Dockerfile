# Production Dockerfile for Fly.io deployment
# Build context: monorepo root (umbrella project)
#
# https://hub.docker.com/r/hexpm/elixir/tags?page=1&name=ubuntu
# https://hub.docker.com/_/ubuntu?tab=tags

ARG ELIXIR_VERSION=1.18.3
ARG OTP_VERSION=27.2
ARG UBUNTU_VERSION=jammy-20260109

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-ubuntu-${UBUNTU_VERSION}"
ARG RUNNER_IMAGE="ubuntu:${UBUNTU_VERSION}"

FROM ${BUILDER_IMAGE} AS builder

# Install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git curl \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Prepare build dir
WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set build ENV
ENV MIX_ENV="prod"

# Copy umbrella root and child mix.exs files
COPY mix.exs ./
COPY apps/workgroup_pulse/mix.exs apps/workgroup_pulse/
COPY apps/oostkit_shared/mix.exs apps/oostkit_shared/

RUN mix deps.get --only $MIX_ENV

# Copy root config (compile-time config)
COPY config/config.exs config/${MIX_ENV}.exs config/

# Copy shared component library source
COPY apps/oostkit_shared/lib apps/oostkit_shared/lib

RUN mix deps.compile

COPY apps/workgroup_pulse/priv apps/workgroup_pulse/priv

COPY apps/workgroup_pulse/lib apps/workgroup_pulse/lib

# Copy shared design system preset (used by tailwind.config.js)
COPY shared/ shared/

COPY apps/workgroup_pulse/assets apps/workgroup_pulse/assets

# Compile assets
RUN cd apps/workgroup_pulse && mix assets.deploy

# Compile the release
RUN mix compile

# Changes to config/runtime.exs don't require recompiling the code
COPY config/runtime.exs config/

COPY apps/workgroup_pulse/rel apps/workgroup_pulse/rel
RUN mix release workgroup_pulse

# Start a new build stage so that the final image will only contain
# the compiled release and other runtime necessities
FROM ${RUNNER_IMAGE}

RUN apt-get update -y && \
  apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

WORKDIR "/app"
RUN chown nobody /app

# set runner ENV
ENV MIX_ENV="prod"

# Only copy the final release from the build stage
COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/workgroup_pulse ./

# Ensure scripts are executable
RUN chmod +x /app/bin/*

USER nobody

CMD ["/app/bin/workgroup_pulse", "start"]
