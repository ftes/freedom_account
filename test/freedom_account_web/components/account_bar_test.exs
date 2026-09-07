defmodule FreedomAccountWeb.AccountBarTest do
  @moduledoc false

  use FreedomAccountWeb.ConnCase, async: true

  @moduletag capture_log: true

  describe "Show" do
    setup [:create_account]

    test "displays account", %{conn: conn, account: account} do
      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/")
      |> expect(title() |> by_css() |> filter(has_text: html_text("Freedom Account")) |> visible())
      |> expect(heading() |> by_css() |> filter(has_text: html_text(account.name)) |> visible())
    end

    test "updates account from fund list view", %{conn: conn} do
      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds")
      |> click(by_role(:link, name: "Settings"))
      |> expect(Expect.url(~r{/account/edit(?:\?.*)?$}))
      |> expect(heading() |> by_css() |> filter(has_text: html_text("Edit Account Settings")) |> visible())
      |> click(by_role(:button, name: "Save Account"))
      |> expect(page_title_contains("Funds"))
    end

    test "updates account from loan list view", %{conn: conn} do
      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans")
      |> click(by_role(:link, name: "Settings"))
      |> expect(Expect.url(~r{/account/edit(?:\?.*)?$}))
      |> expect(heading() |> by_css() |> filter(has_text: html_text("Edit Account Settings")) |> visible())
      |> click(by_role(:button, name: "Save Account"))
      |> expect(page_title_contains("Loans"))
    end

    test "updates account from transaction list view", %{conn: conn} do
      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/transactions")
      |> click(by_role(:link, name: "Settings"))
      |> expect(Expect.url(~r{/account/edit(?:\?.*)?$}))
      |> expect(heading() |> by_css() |> filter(has_text: html_text("Edit Account Settings")) |> visible())
      |> click(by_role(:button, name: "Save Account"))
      |> expect(page_title_contains("Transactions"))
    end
  end
end
