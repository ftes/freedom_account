defmodule FreedomAccountWeb.LoanLive.LoanFormTest do
  @moduledoc false

  use FreedomAccountWeb.ConnCase, async: true

  alias FreedomAccount.Factory
  alias FreedomAccount.MoneyUtils

  describe "lending money" do
    setup [:create_account, :create_loan]

    test "lends money from a loan", %{account: account, conn: conn, loan: loan} do
      fund = account |> Factory.fund() |> Factory.with_fund_balance()
      date = Factory.date()
      memo = Factory.memo()
      amount = Factory.money()
      balance = Money.negate!(amount)
      account_balance = Money.sub!(fund.current_balance, amount)

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans/#{loan}/loans/new")
      |> assert(page_title_contains("Lend"))
      |> assert(heading() |> by_css() |> filter(has_text: html_text("Lend")) |> visible())
      |> fill(by_label("Date", exact: true), to_string(date))
      |> fill(by_label("Memo", exact: true), to_string(memo))
      |> fill(by_label("Amount", exact: true), to_string(amount))
      |> click(by_role(:button, name: "Lend Money"))
      |> assert(:info |> flash() |> by_css() |> filter(has_text: html_text("Money lent successfully")) |> visible())
      |> assert(heading() |> by_css() |> filter(has_text: html_text(loan)) |> visible())
      |> assert(heading() |> by_css() |> filter(has_text: html_text(MoneyUtils.format(balance))) |> visible())
      |> assert(
        account_balance()
        |> by_css()
        |> filter(has_text: html_text(MoneyUtils.format(account_balance)))
        |> visible()
      )
      |> assert(
        loan
        |> sidebar_loan_balance()
        |> by_css()
        |> filter(has_text: html_text(MoneyUtils.format(balance)))
        |> visible()
      )
      |> assert(table_cell() |> by_css() |> filter(has_text: html_text("#{date}")) |> visible())
      |> assert(table_cell() |> by_css() |> filter(has_text: html_text(memo)) |> visible())
      |> assert("loan" |> role() |> by_css() |> filter(has_text: html_text(MoneyUtils.format(amount))) |> visible())
    end

    test "does not record loan on cancel", %{account: account, conn: conn, loan: loan} do
      fund = account |> Factory.fund() |> Factory.with_fund_balance()
      date = Factory.date()
      memo = Factory.memo()
      amount = Factory.money()

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans/#{loan}/loans/new")
      |> fill(by_label("Date", exact: true), to_string(date))
      |> fill(by_label("Memo", exact: true), to_string(memo))
      |> fill(by_label("Amount", exact: true), to_string(amount))
      |> click(by_role(:link, name: "Cancel"))
      |> assert(heading() |> by_css() |> filter(has_text: html_text(loan)) |> visible())
      |> assert(
        heading()
        |> by_css()
        |> filter(has_text: :usd |> Money.zero() |> MoneyUtils.format() |> html_text())
        |> visible()
      )
      |> assert(
        heading()
        |> by_css()
        |> filter(has_text: html_text(MoneyUtils.format(fund.current_balance)))
        |> visible()
      )
      |> assert(
        loan
        |> sidebar_loan_balance()
        |> by_css()
        |> filter(has_text: :usd |> Money.zero() |> MoneyUtils.format() |> html_text())
        |> visible()
      )
    end
  end
end
