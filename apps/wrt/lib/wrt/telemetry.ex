defmodule Wrt.Telemetry do
  @moduledoc """
  Telemetry event helpers for WRT business operations.

  Provides functions to emit telemetry events for key business metrics
  that can be collected by monitoring systems.
  """

  @doc """
  Emits a telemetry event for login attempts.
  """
  def login_attempt(result, metadata \\ %{}) do
    :telemetry.execute(
      [:wrt, :auth, :login],
      %{count: 1},
      Map.merge(metadata, %{result: result})
    )
  end

  @doc """
  Emits a telemetry event for magic link operations.
  """
  def magic_link(action, metadata \\ %{}) do
    :telemetry.execute(
      [:wrt, :auth, :magic_link],
      %{count: 1},
      Map.merge(metadata, %{action: action})
    )
  end

  @doc """
  Emits a telemetry event for nomination submissions.
  """
  def nomination_submitted(tenant, count, metadata \\ %{}) do
    :telemetry.execute(
      [:wrt, :nomination, :submit],
      %{count: count},
      Map.merge(metadata, %{tenant: tenant})
    )
  end

  @doc """
  Emits a telemetry event for emails sent.
  """
  def email_sent(type, result, metadata \\ %{}) do
    :telemetry.execute(
      [:wrt, :email, :send],
      %{count: 1},
      Map.merge(metadata, %{type: type, result: result})
    )
  end

  @doc """
  Emits a telemetry event for rate limited requests.
  """
  def rate_limited(path, metadata \\ %{}) do
    :telemetry.execute(
      [:wrt, :rate_limit, :blocked],
      %{count: 1},
      Map.merge(metadata, %{path: path})
    )
  end

  @doc """
  Emits a telemetry event for round operations.
  """
  def round_event(action, metadata \\ %{}) do
    :telemetry.execute(
      [:wrt, :round, action],
      %{count: 1},
      metadata
    )
  end

  @doc """
  Emits a telemetry event for campaign operations.
  """
  def campaign_event(action, metadata \\ %{}) do
    :telemetry.execute(
      [:wrt, :campaign, action],
      %{count: 1},
      metadata
    )
  end
end
