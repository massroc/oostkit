defmodule WrtWeb.PageController do
  use WrtWeb, :controller

  def home(conn, _params) do
    render(conn, :home, page_title: "Workshop Referral Tool")
  end
end
