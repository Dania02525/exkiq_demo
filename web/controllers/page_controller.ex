defmodule ExkiqDemo.PageController do
  use ExkiqDemo.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
