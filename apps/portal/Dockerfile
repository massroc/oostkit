# Production Dockerfile for Fly.io deployment
# Build context: monorepo root (not app directory)
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

# Install mix dependencies
COPY apps/portal/mix.exs apps/portal/mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# Copy shared component library (path dependency)
COPY apps/oostkit_shared /oostkit_shared

# Copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to be re-compiled.
COPY apps/portal/config/config.exs apps/portal/config/${MIX_ENV}.exs config/
RUN mix deps.compile

COPY apps/portal/priv priv

COPY apps/portal/lib lib

# Copy shared design system preset (used by tailwind.config.js)
COPY shared /shared

COPY apps/portal/assets assets

# Compile assets
RUN mix assets.deploy

# Compile the release
RUN mix compile

# Changes to config/runtime.exs don't require recompiling the code
COPY apps/portal/config/runtime.exs config/

COPY apps/portal/rel rel
RUN mix release

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
COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/portal ./

# Ensure scripts are executable
RUN chmod +x /app/bin/*

USER nobody

# If using an environment that doesn't automatically reap zombie processes, it is
# advised to add an init process such as tini via `apt-get install tini` inside the
# temporary builder stage, and adding an entrypoint.
#
# ENTRYPOINT ["/tini", "--"]

CMD ["/app/bin/portal", "start"]
