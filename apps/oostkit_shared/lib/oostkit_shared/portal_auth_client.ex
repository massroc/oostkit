defmodule OostkitShared.PortalAuthClient do
  @moduledoc """
  HTTP client for validating Portal session tokens.

  Calls Portal's `/api/internal/auth/validate` endpoint and caches
  results in ETS with a 5-minute TTL to minimize API calls.

  ## Configuration

      config :oostkit_shared, :portal_auth,
        api_url: "http://localhost:4002",
        api_key: "dev_internal_api_key",
        finch: MyApp.Finch

  """

  require Logger

  @cache_table :portal_auth_cache
  @cache_ttl_seconds 300

  def child_spec(_opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :worker
    }
  end

  def start_link do
    :ets.new(@cache_table, [:set, :public, :named_table, read_concurrency: true])
    :ignore
  end

  @doc """
  Validates a Portal session token. Returns `{:ok, user_map}` or `{:error, reason}`.

  Results are cached for 5 minutes.
  """
  def validate_token(encoded_token) do
    case cached_result(encoded_token) do
      {:ok, _} = hit -> hit
      {:error, _} = hit -> hit
      :miss -> fetch_and_cache(encoded_token)
    end
  end

  defp cached_result(token) do
    case :ets.lookup(@cache_table, token) do
      [{^token, result, expires_at}] ->
        if System.monotonic_time(:second) < expires_at do
          result
        else
          :ets.delete(@cache_table, token)
          :miss
        end

      [] ->
        :miss
    end
  rescue
    ArgumentError -> :miss
  end

  defp fetch_and_cache(encoded_token) do
    result = do_validate(encoded_token)
    expires_at = System.monotonic_time(:second) + @cache_ttl_seconds
    :ets.insert(@cache_table, {encoded_token, result, expires_at})
    result
  rescue
    e ->
      Logger.error("Portal auth validation failed: #{inspect(e)}")
      {:error, :request_failed}
  end

  defp do_validate(encoded_token) do
    config = portal_auth_config()
    url = config[:api_url] <> "/api/internal/auth/validate"
    api_key = config[:api_key] || ""
    finch_name = config[:finch]

    body = Jason.encode!(%{token: encoded_token})

    headers = [
      {"authorization", "Bearer #{api_key}"},
      {"content-type", "application/json"}
    ]

    request = Finch.build(:post, url, headers, body)

    case Finch.request(request, finch_name) do
      {:ok, %Finch.Response{status: 200, body: resp_body}} ->
        case Jason.decode(resp_body) do
          {:ok, %{"valid" => true, "user" => user}} -> {:ok, user}
          _ -> {:error, :invalid_response}
        end

      {:ok, %Finch.Response{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp portal_auth_config do
    Application.get_env(:oostkit_shared, :portal_auth, [])
  end
end
