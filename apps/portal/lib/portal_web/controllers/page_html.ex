defmodule PortalWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.
  """
  use PortalWeb, :html

  def pulse_url(live_tools) do
    case Enum.find(live_tools, &(&1.id == "workgroup_pulse")) do
      %{url: url} when is_binary(url) -> url
      _ -> "#"
    end
  end

  embed_templates "page_html/*"
end
