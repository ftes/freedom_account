defmodule FreedomAccountWeb.FundLive.IndexTest do
  @moduledoc false

  use FreedomAccountWeb.ConnCase, async: true

  alias FreedomAccount.Factory
  alias FreedomAccount.Funds
  alias FreedomAccount.MoneyUtils

  describe "listing all funds" do
    setup [:create_account]

    test "lists all funds", %{account: account, conn: conn} do
      fund = Factory.fund(account)
      Factory.deposit(fund)
      {:ok, fund} = Funds.with_updated_balance(fund)

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds")
      |> assert(page_title_contains("Funds"))
      |> assert(active_tab() |> by_css() |> filter(has_text: html_text("Funds")) |> visible())
      |> assert(fund |> fund_icon() |> by_css() |> filter(has_text: html_text(fund.icon)) |> visible())
      |> assert(fund |> fund_name() |> by_css() |> filter(has_text: html_text(fund.name)) |> visible())
      |> assert(fund |> fund_budget() |> by_css() |> filter(has_text: html_text("#{fund.budget}")) |> visible())
      |> assert(
        fund
        |> fund_frequency()
        |> by_css()
        |> filter(has_text: html_text("#{fund.times_per_year}"))
        |> visible()
      )
      |> assert(
        fund
        |> fund_balance()
        |> by_css()
        |> filter(has_text: html_text(MoneyUtils.format(fund.current_balance)))
        |> visible()
      )
    end

    test "shows prompt when list is empty", %{conn: conn} do
      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds")
      |> assert(active_tab() |> by_css() |> filter(has_text: html_text("Funds")) |> visible())
      |> assert(
        "#no-funds"
        |> by_css()
        |> filter(has_text: html_text("This account has no funds yet. Use the Add Fund button to add one."))
        |> visible()
      )
    end

    test "shows total funds balance", %{account: account, conn: conn} do
      fund = account |> Factory.fund() |> Factory.with_fund_balance()
      _loan = account |> Factory.loan() |> Factory.with_loan_balance()

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds")
      |> assert(
        active_tab()
        |> by_css()
        |> filter(has_text: html_text(MoneyUtils.format(fund.current_balance)))
        |> visible()
      )
    end

    test "allows creating a new fund from the listing", %{conn: conn} do
      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds")
      |> click(by_role(:link, name: "Add Fund"))
      |> assert(page_url(~p"/funds/new"))
      |> click(by_role(:link, name: "Cancel"))
      |> assert(active_tab() |> by_css() |> filter(has_text: html_text("Funds")) |> visible())
    end

    test "allows editing a fund in listing", %{account: account, conn: conn} do
      fund = account |> Factory.fund() |> Factory.with_fund_balance()

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds")
      |> click(fund |> fund_action() |> by_css() |> filter(has_text: html_text("Edit")))
      |> assert(page_url(~p"/funds/#{fund}/edit"))
      |> click(by_role(:link, name: "Cancel"))
      |> assert(active_tab() |> by_css() |> filter(has_text: html_text("Funds")) |> visible())
    end

    test "deletes fund in listing", %{account: account, conn: conn} do
      fund = Factory.fund(account)

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds")
      |> click("#funds-#{fund.id}" |> action_link() |> by_css() |> filter(has_text: html_text("Delete")))
      |> assert(count(by_css("#funds-#{fund.id}"), 0))
    end

    test "allows activating/deactivating funds from listing", %{account: account, conn: conn} do
      _fund = Factory.fund(account)

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds")
      |> click(by_role(:link, name: "Activate/Deactivate"))
      |> assert(page_url(~p"/funds/activate"))
      |> click(by_role(:link, name: "Cancel"))
      |> assert(active_tab() |> by_css() |> filter(has_text: html_text("Funds")) |> visible())
    end

    test "allows making a regular deposit from listing", %{conn: conn} do
      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds")
      |> click(by_role(:link, name: "Regular Deposit"))
      |> assert(page_url(~p"/funds/regular_deposit"))
      |> click(by_role(:link, name: "Cancel"))
      |> assert(active_tab() |> by_css() |> filter(has_text: html_text("Funds")) |> visible())
    end

    test "allows making a regular withdrawal from listing", %{account: account, conn: conn} do
      _fund = Factory.fund(account)

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds")
      |> click(by_role(:link, name: "Regular Withdrawal"))
      |> assert(page_url(~p"/funds/regular_withdrawal"))
      |> click(by_role(:link, name: "Cancel"))
      |> assert(active_tab() |> by_css() |> filter(has_text: html_text("Funds")) |> visible())
    end

    test "allows updating budget from listing", %{account: account, conn: conn} do
      _fund = Factory.fund(account)

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds")
      |> click(by_role(:link, name: "Budget"))
      |> assert(page_url(~p"/funds/budget"))
      |> click(by_role(:link, name: "Cancel"))
      |> assert(active_tab() |> by_css() |> filter(has_text: html_text("Funds")) |> visible())
    end
  end
end
