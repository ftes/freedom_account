defmodule FreedomAccountWeb.FundLive.WithdrawalFormTest do
  @moduledoc false

  use FreedomAccountWeb.ConnCase, async: true

  import Money.Sigil

  alias FreedomAccount.Factory
  alias FreedomAccount.MoneyUtils

  describe "making a withdrawal" do
    setup [:create_account, :create_fund]

    test "withdraws money from a fund", %{account: account, conn: conn, fund: fund} do
      other_fund = account |> Factory.fund() |> Factory.with_fund_balance()
      deposit_amount = ~M[5000]usd
      date = Factory.date()
      memo = Factory.memo()
      amount = Factory.money()
      balance = Money.sub!(deposit_amount, amount)
      account_balance = Money.add!(other_fund.current_balance, balance)

      Factory.deposit(fund, amount: deposit_amount)

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds/#{fund}/withdrawals/new")
      |> assert(page_title_contains("Withdraw"))
      |> assert(heading() |> by_css() |> filter(has_text: html_text("Withdraw")) |> visible())
      |> assert("label" |> by_css() |> filter(has_text: html_text(fund)) |> visible())
      |> assert(count(by_css("#transaction-total"), 0))
      |> fill(by_label("Date", exact: true), to_string(date))
      |> fill(by_label("Memo", exact: true), to_string(memo))
      |> click(by_role(:button, name: "Make Withdrawal"))
      |> assert(count(by_css("#line-items-error"), 0))
      |> fill(by_label("Amount 0", exact: true), to_string(amount))
      |> click(by_role(:button, name: "Make Withdrawal"))
      |> assert(:info |> flash() |> by_css() |> filter(has_text: html_text("Withdrawal successful")) |> visible())
      |> assert(heading() |> by_css() |> filter(has_text: html_text(fund)) |> visible())
      |> assert(heading() |> by_css() |> filter(has_text: html_text(MoneyUtils.format(balance))) |> visible())
      |> assert(heading() |> by_css() |> filter(has_text: html_text(MoneyUtils.format(account_balance))) |> visible())
      |> assert(
        fund
        |> sidebar_fund_balance()
        |> by_css()
        |> filter(has_text: html_text(MoneyUtils.format(balance)))
        |> visible()
      )
      |> assert(table_cell() |> by_css() |> filter(has_text: html_text("#{date}")) |> visible())
      |> assert(table_cell() |> by_css() |> filter(has_text: html_text(memo)) |> visible())
      |> assert("withdrawal" |> role() |> by_css() |> filter(has_text: html_text(MoneyUtils.format(amount))) |> visible())
    end

    test "does not make deposit on cancel", %{account: account, conn: conn, fund: fund} do
      other_fund = account |> Factory.fund() |> Factory.with_fund_balance()
      deposit_amount = ~M[5000]usd
      date = Factory.date()
      memo = Factory.memo()
      amount = Factory.money()
      account_balance = Money.add!(other_fund.current_balance, deposit_amount)

      Factory.deposit(fund, amount: deposit_amount)

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds/#{fund}/withdrawals/new")
      |> fill(by_label("Date", exact: true), to_string(date))
      |> fill(by_label("Memo", exact: true), to_string(memo))
      |> fill(by_label("Amount 0", exact: true), to_string(amount))
      |> click(by_role(:link, name: "Cancel"))
      |> assert(heading() |> by_css() |> filter(has_text: html_text(fund)) |> visible())
      |> assert(heading() |> by_css() |> filter(has_text: html_text(MoneyUtils.format(deposit_amount))) |> visible())
      |> assert(heading() |> by_css() |> filter(has_text: html_text(MoneyUtils.format(account_balance))) |> visible())
      |> assert(
        fund
        |> sidebar_fund_balance()
        |> by_css()
        |> filter(has_text: html_text(MoneyUtils.format(deposit_amount)))
        |> visible()
      )
    end
  end
end
