import Config

# =============================================================================
# Portal (prod)
# =============================================================================

config :portal, PortalWeb.Endpoint, cache_static_manifest: "priv/static/cache_manifest.json"

# =============================================================================
# WRT (prod)
# =============================================================================

config :wrt, WrtWeb.Endpoint, cache_static_manifest: "priv/static/cache_manifest.json"

# Disable Swoosh Local Memory Storage
config :swoosh, local: false

# =============================================================================
# Shared prod settings
# =============================================================================

# Configure Swoosh API client (uses Finch — finch_name set per-release in runtime.exs)
config :swoosh, api_client: Swoosh.ApiClient.Finch

# Do not print debug messages in production
config :logger, level: :info

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
