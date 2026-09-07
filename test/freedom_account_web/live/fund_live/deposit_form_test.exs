defmodule FreedomAccountWeb.FundLive.DepositFormTest do
  @moduledoc false

  use FreedomAccountWeb.ConnCase, async: true

  alias FreedomAccount.Factory
  alias FreedomAccount.MoneyUtils

  describe "making a deposit" do
    setup [:create_account, :create_fund]

    test "deposits money to a fund", %{account: account, conn: conn, fund: fund} do
      other_fund = account |> Factory.fund() |> Factory.with_fund_balance()
      date = Factory.date()
      memo = Factory.memo()
      amount = Factory.money()
      account_balance = Money.add!(other_fund.current_balance, amount)

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds/#{fund}/deposits/new")
      |> expect(page_title_contains("Deposit"))
      |> expect(heading() |> by_css() |> filter(has_text: html_text("Deposit")) |> visible())
      |> expect("label" |> by_css() |> filter(has_text: html_text(fund)) |> visible())
      |> expect(count(by_css("#transaction-total"), 0))
      |> fill(by_label("Date", exact: true), to_string(date))
      |> fill(by_label("Memo", exact: true), to_string(memo))
      |> click(by_role(:button, name: "Make Deposit"))
      |> expect(count(by_css("#line-items-error"), 0))
      |> fill(by_label("Amount 0", exact: true), to_string(amount))
      |> click(by_role(:button, name: "Make Deposit"))
      |> expect(:info |> flash() |> by_css() |> filter(has_text: html_text("Deposit successful")) |> visible())
      |> expect(heading() |> by_css() |> filter(has_text: html_text(fund)) |> visible())
      |> expect(heading() |> by_css() |> filter(has_text: html_text(MoneyUtils.format(amount))) |> visible())
      |> expect(heading() |> by_css() |> filter(has_text: html_text(MoneyUtils.format(account_balance))) |> visible())
      |> expect(
        fund
        |> sidebar_fund_balance()
        |> by_css()
        |> filter(has_text: html_text(MoneyUtils.format(amount)))
        |> visible()
      )
      |> expect(table_cell() |> by_css() |> filter(has_text: html_text("#{date}")) |> visible())
      |> expect(table_cell() |> by_css() |> filter(has_text: html_text(memo)) |> visible())
      |> expect("deposit" |> role() |> by_css() |> filter(has_text: html_text(MoneyUtils.format(amount))) |> visible())
    end

    test "does not make deposit on cancel", %{account: account, conn: conn, fund: fund} do
      other_fund = account |> Factory.fund() |> Factory.with_fund_balance()
      date = Factory.date()
      memo = Factory.memo()
      amount = Factory.money()

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds/#{fund}/deposits/new")
      |> fill(by_label("Date", exact: true), to_string(date))
      |> fill(by_label("Memo", exact: true), to_string(memo))
      |> fill(by_label("Amount 0", exact: true), to_string(amount))
      |> click(by_role(:link, name: "Cancel"))
      |> expect(heading() |> by_css() |> filter(has_text: html_text(fund)) |> visible())
      |> expect(
        heading()
        |> by_css()
        |> filter(has_text: :usd |> Money.zero() |> MoneyUtils.format() |> html_text())
        |> visible()
      )
      |> expect(
        heading()
        |> by_css()
        |> filter(has_text: html_text(MoneyUtils.format(other_fund.current_balance)))
        |> visible()
      )
    end
  end
end
