defmodule FreedomAccountWeb.HomeControllerTest do
  use FreedomAccountWeb.ConnCase, async: true

  setup :create_account

  test "redirects to fund list page", %{conn: conn} do
    :phoenix
    |> start_session(conn: conn)
    |> visit(~p"/")
    |> expect(page_title_contains("Funds"))
  end
end
