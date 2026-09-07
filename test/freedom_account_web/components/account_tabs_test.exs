defmodule FreedomAccountWeb.AccountTabsTest do
  @moduledoc false
  use FreedomAccountWeb.ConnCase, async: true

  setup :create_account

  describe "switching tabs" do
    test "only funds tab is active on fund list page", %{conn: conn} do
      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds")
      |> expect(active_tab() |> by_css() |> filter(has_text: html_text("Funds")) |> visible())
      |> expect(inactive_tab() |> by_css() |> filter(has_text: html_text("Loans")) |> visible())
      |> expect(inactive_tab() |> by_css() |> filter(has_text: html_text("Transactions")) |> visible())
    end

    test "only loans tab is active on loan list page", %{conn: conn} do
      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans")
      |> expect(active_tab() |> by_css() |> filter(has_text: html_text("Loans")) |> visible())
      |> expect(inactive_tab() |> by_css() |> filter(has_text: html_text("Funds")) |> visible())
      |> expect(inactive_tab() |> by_css() |> filter(has_text: html_text("Transactions")) |> visible())
    end

    test "only transactions tab is active on transaction list page", %{conn: conn} do
      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/transactions")
      |> expect(active_tab() |> by_css() |> filter(has_text: html_text("Transactions")) |> visible())
      |> expect(inactive_tab() |> by_css() |> filter(has_text: html_text("Funds")) |> visible())
      |> expect(inactive_tab() |> by_css() |> filter(has_text: html_text("Loans")) |> visible())
    end

    test "shows balances on funds and loans tabs", %{conn: conn} do
      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/")
      |> expect(active_tab() |> by_css() |> filter(has_text: html_text("$0.00")) |> visible())
      |> expect(inactive_tab() |> by_css() |> filter(has_text: html_text("$0.00")) |> visible())
    end

    test "can switch tabs", %{conn: conn} do
      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds")
      |> click(by_role(:tab, name: "Loans"))
      |> expect(active_tab() |> by_css() |> filter(has_text: html_text("Loans")) |> visible())
      |> expect(inactive_tab() |> by_css() |> filter(has_text: html_text("Funds")) |> visible())
      |> expect(inactive_tab() |> by_css() |> filter(has_text: html_text("Transactions")) |> visible())
      |> click(by_role(:tab, name: "Transactions"))
      |> expect(active_tab() |> by_css() |> filter(has_text: html_text("Transactions")) |> visible())
      |> expect(inactive_tab() |> by_css() |> filter(has_text: html_text("Funds")) |> visible())
      |> expect(inactive_tab() |> by_css() |> filter(has_text: html_text("Loans")) |> visible())
      |> click(by_role(:tab, name: "Funds"))
      |> expect(active_tab() |> by_css() |> filter(has_text: html_text("Funds")) |> visible())
      |> expect(inactive_tab() |> by_css() |> filter(has_text: html_text("Loans")) |> visible())
      |> expect(inactive_tab() |> by_css() |> filter(has_text: html_text("Transactions")) |> visible())
    end
  end
end
