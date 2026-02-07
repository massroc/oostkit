defmodule PortalWeb.ErrorHTML do
  @moduledoc """
  This module is invoked by your endpoint in case of errors on HTML requests.
  """
  use PortalWeb, :html

  embed_templates "error_html/*"

  @dialyzer {:nowarn_function, render: 2}
  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
