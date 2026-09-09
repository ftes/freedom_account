defmodule FreedomAccountWeb.LoanLive.PaymentFormTest do
  @moduledoc false

  use FreedomAccountWeb.ConnCase, async: true

  import Money.Sigil

  alias FreedomAccount.Factory
  alias FreedomAccount.MoneyUtils

  describe "accepting a payment on a loan" do
    setup [:create_account, :create_loan]

    test "receives a payment on a loan", %{account: account, conn: conn, loan: loan} do
      fund = account |> Factory.fund() |> Factory.with_fund_balance()
      loan_amount = ~M[5000]usd
      date = Factory.date()
      memo = Factory.memo()
      amount = Factory.money()
      balance = Money.sub!(amount, loan_amount)
      account_balance = Money.add!(fund.current_balance, balance)

      Factory.lend(loan, amount: loan_amount)

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans/#{loan}/payments/new")
      |> assert(page_title_contains("Payment"))
      |> assert(heading() |> by_css() |> filter(has_text: html_text("Payment")) |> visible())
      |> fill(by_label("Date", exact: true), to_string(date))
      |> fill(by_label("Memo", exact: true), to_string(memo))
      |> fill(by_label("Amount", exact: true), to_string(amount))
      |> click(by_role(:button, name: "Receive Payment"))
      |> assert(:info |> flash() |> by_css() |> filter(has_text: html_text("Payment successful")) |> visible())
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
      |> assert("payment" |> role() |> by_css() |> filter(has_text: html_text(MoneyUtils.format(amount))) |> visible())
    end

    test "does not receive a payment on cancel", %{account: account, conn: conn, loan: loan} do
      fund = account |> Factory.fund() |> Factory.with_fund_balance()
      loan_amount = ~M[5000]usd
      date = Factory.date()
      memo = Factory.memo()
      amount = Factory.money()
      balance = Money.negate!(loan_amount)
      account_balance = Money.sub!(fund.current_balance, loan_amount)

      Factory.lend(loan, amount: loan_amount)

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans/#{loan}/payments/new")
      |> fill(by_label("Date", exact: true), to_string(date))
      |> fill(by_label("Memo", exact: true), to_string(memo))
      |> fill(by_label("Amount", exact: true), to_string(amount))
      |> click(by_role(:link, name: "Cancel"))
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
    end
  end
end
