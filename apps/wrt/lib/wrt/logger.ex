defmodule Wrt.Logger do
  @moduledoc """
  Structured logging helpers for the WRT application.

  Provides consistent logging for key business operations with
  structured metadata for easy searching and monitoring.
  """

  require Logger

  @doc """
  Logs an authentication event.
  """
  def log_auth(event, metadata \\ %{}) do
    metadata = Map.merge(metadata, %{category: :auth, event: event})

    case event do
      :login_success ->
        Logger.info("User logged in", metadata)

      :login_failure ->
        Logger.warning("Failed login attempt", metadata)

      :logout ->
        Logger.info("User logged out", metadata)

      :magic_link_created ->
        Logger.info("Magic link created", metadata)

      :magic_link_verified ->
        Logger.info("Magic link verified", metadata)

      :magic_link_expired ->
        Logger.info("Expired magic link access attempted", metadata)

      _ ->
        Logger.info("Auth event: #{event}", metadata)
    end
  end

  @doc """
  Logs a campaign event.
  """
  def log_campaign(event, metadata \\ %{}) do
    metadata = Map.merge(metadata, %{category: :campaign, event: event})

    case event do
      :created ->
        Logger.info("Campaign created", metadata)

      :started ->
        Logger.info("Campaign started", metadata)

      :completed ->
        Logger.info("Campaign completed", metadata)

      :round_started ->
        Logger.info("Round started", metadata)

      :round_closed ->
        Logger.info("Round closed", metadata)

      _ ->
        Logger.info("Campaign event: #{event}", metadata)
    end
  end

  @doc """
  Logs a nomination event.
  """
  def log_nomination(event, metadata \\ %{}) do
    metadata = Map.merge(metadata, %{category: :nomination, event: event})

    case event do
      :submitted ->
        Logger.info("Nominations submitted", metadata)

      :updated ->
        Logger.info("Nominations updated", metadata)

      _ ->
        Logger.info("Nomination event: #{event}", metadata)
    end
  end

  @doc """
  Logs an email event.
  """
  def log_email(event, metadata \\ %{}) do
    metadata = Map.merge(metadata, %{category: :email, event: event})

    case event do
      :sent ->
        Logger.info("Email sent", metadata)

      :delivered ->
        Logger.info("Email delivered", metadata)

      :opened ->
        Logger.info("Email opened", metadata)

      :clicked ->
        Logger.info("Email link clicked", metadata)

      :bounced ->
        Logger.warning("Email bounced", metadata)

      :failed ->
        Logger.error("Email send failed", metadata)

      _ ->
        Logger.info("Email event: #{event}", metadata)
    end
  end

  @doc """
  Logs a tenant event.
  """
  def log_tenant(event, metadata \\ %{}) do
    metadata = Map.merge(metadata, %{category: :tenant, event: event})

    case event do
      :created ->
        Logger.info("Tenant created", metadata)

      :migrated ->
        Logger.info("Tenant migrated", metadata)

      :dropped ->
        Logger.warning("Tenant dropped", metadata)

      _ ->
        Logger.info("Tenant event: #{event}", metadata)
    end
  end

  @doc """
  Logs an error with context.
  """
  def log_error(module, function, error, metadata \\ %{}) do
    metadata =
      Map.merge(metadata, %{
        category: :error,
        module: module,
        function: function,
        error: inspect(error)
      })

    Logger.error("Error in #{module}.#{function}: #{inspect(error)}", metadata)
  end

  @doc """
  Logs a rate limit event.
  """
  def log_rate_limit(ip, path, metadata \\ %{}) do
    metadata =
      Map.merge(metadata, %{
        category: :security,
        event: :rate_limited,
        ip: format_ip(ip),
        path: path
      })

    Logger.warning("Rate limit exceeded", metadata)
  end

  defp format_ip(ip) when is_tuple(ip) do
    ip
    |> Tuple.to_list()
    |> Enum.join(".")
  end

  defp format_ip(ip), do: inspect(ip)
end
