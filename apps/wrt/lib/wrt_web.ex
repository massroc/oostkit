defmodule WrtWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, and so on.

  This can be used in your application as:

      use WrtWeb, :controller
      use WrtWeb, :html

  The definitions below will be executed for every controller,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: [html: WrtWeb.Layouts]

      import Plug.Conn
      use Gettext, backend: WrtWeb.Gettext

      unquote(verified_routes())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      import Phoenix.HTML
      import PetalComponents.{
        Accordion, Alert, Avatar, Badge, Breadcrumbs, Button, ButtonGroup,
        Card, Container, Dropdown, Field, Form, Icon, Input, Link, Loading,
        Marquee, Modal, Pagination, Progress, Rating, Skeleton, SlideOver,
        Stepper, Tabs, Typography, UserDropdownMenu, Menu
      }

      alias PetalComponents.HeroiconsV1
      import WrtWeb.CoreComponents, except: [button: 1, icon: 1, input: 1]
      use Gettext, backend: WrtWeb.Gettext

      alias Phoenix.LiveView.JS

      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: WrtWeb.Endpoint,
        router: WrtWeb.Router,
        statics: WrtWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
