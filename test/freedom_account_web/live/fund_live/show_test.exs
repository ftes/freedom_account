defmodule FreedomAccountWeb.FundLive.ShowTest do
  @moduledoc false

  use FreedomAccountWeb.ConnCase, async: true

  import Money.Sigil

  alias FreedomAccount.Factory
  alias FreedomAccount.Funds

  describe "viewing an individual fund" do
    setup [:create_account, :create_fund]

    test "drills down to individual fund and back", %{account: account, conn: conn, fund: fund} do
      per_deposit = Funds.regular_deposit_amount(fund, account)

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds")
      |> click(fund |> fund_card() |> by_css() |> filter(has_text: html_text(fund.name)))
      |> assert(page_title_contains(fund))
      |> assert(heading() |> by_css() |> filter(has_text: html_text(fund)) |> visible())
      |> assert(heading() |> by_css() |> filter(has_text: html_text("$0.00")) |> visible())
      |> assert(fund_subtitle() |> by_css() |> filter(has_text: html_text("#{fund.budget}")) |> visible())
      |> assert(fund_subtitle() |> by_css() |> filter(has_text: html_text("#{fund.times_per_year}")) |> visible())
      |> assert(fund_subtitle() |> by_css() |> filter(has_text: html_text("#{per_deposit}")) |> visible())
      |> click(by_role(:link, name: "Back to Funds"))
      |> assert(page_title_contains("Funds"))
      |> assert(active_tab() |> by_css() |> filter(has_text: html_text("Funds")) |> visible())
    end

    test "displays fund", %{conn: conn, fund: fund} do
      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds/#{fund}")
      |> assert(heading() |> by_css() |> filter(has_text: html_text(fund)) |> visible())
    end

    test "allows editing fund", %{conn: conn, fund: fund} do
      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds/#{fund}")
      |> click(by_role(:link, name: "Edit Details"))
      |> assert(page_url(~r{/funds/#{fund.id}/edit(?:\?.*)?$}))
      |> click(by_role(:link, name: "Cancel"))
      |> assert(heading() |> by_css() |> filter(has_text: html_text(fund)) |> visible())
    end

    test "allows depositing money to a fund", %{conn: conn, fund: fund} do
      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds/#{fund}")
      |> click(by_role(:link, name: "Deposit"))
      |> assert(page_url(~p"/funds/#{fund}/deposits/new"))
      |> click(by_role(:link, name: "Cancel"))
      |> assert(heading() |> by_css() |> filter(has_text: html_text(fund)) |> visible())
    end

    test "allows withdrawing money from a fund", %{conn: conn, fund: fund} do
      Factory.deposit(fund, amount: ~M[5000]usd)

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds/#{fund}")
      |> click(by_role(:link, name: "Withdraw"))
      |> assert(count(by_css(flash(:error)), 0))
      |> assert(page_url(~p"/funds/#{fund}/withdrawals/new"))
      |> click(by_role(:link, name: "Cancel"))
      |> assert(heading() |> by_css() |> filter(has_text: html_text(fund)) |> visible())
    end
  end
end
