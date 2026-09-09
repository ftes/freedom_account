defmodule FreedomAccountWeb.LoanLive.TransactionFormTest do
  use FreedomAccountWeb.ConnCase, async: true

  alias FreedomAccount.Factory
  alias FreedomAccount.MoneyUtils

  setup [:create_account, :create_loan]

  describe "updating transactions" do
    test "edits transaction", %{conn: conn, loan: loan} do
      transaction = Factory.lend(loan)
      new_date = Factory.date()
      new_memo = Factory.memo()
      new_amount = Money.negate!(Factory.money())

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans/#{loan}/transactions/#{transaction}/edit")
      |> assert(page_title_contains("Edit Loan Transaction"))
      |> assert(heading() |> by_css() |> filter(has_text: html_text("Edit Loan Transaction")) |> visible())
      |> assert("loan" |> role() |> by_css() |> filter(has_text: html_text(loan)) |> visible())
      |> assert(visible(by_css(field_value("#loan_transaction_date", transaction.date))))
      |> assert(visible(by_css(field_value("#loan_transaction_memo", transaction.memo))))
      |> assert(visible(by_css(field_value("#loan_transaction_amount", transaction.amount))))
      |> fill(by_label("Date", exact: true), to_string(new_date))
      |> fill(by_label("Memo", exact: true), to_string(new_memo))
      |> fill(by_label("Amount", exact: true), to_string(new_amount))
      |> click(by_role(:button, name: "Save Transaction"))
      |> assert(
        :info
        |> flash()
        |> by_css()
        |> filter(has_text: html_text("Transaction updated successfully"))
        |> visible()
      )
      |> assert(heading() |> by_css() |> filter(has_text: html_text(loan)) |> visible())
      |> assert(heading() |> by_css() |> filter(has_text: html_text(MoneyUtils.format(new_amount))) |> visible())
      |> assert(
        loan
        |> sidebar_loan_balance()
        |> by_css()
        |> filter(has_text: html_text(MoneyUtils.format(new_amount)))
        |> visible()
      )
      |> assert(table_cell() |> by_css() |> filter(has_text: html_text("#{new_date}")) |> visible())
      |> assert(table_cell() |> by_css() |> filter(has_text: html_text(new_memo)) |> visible())
      |> assert("loan" |> role() |> by_css() |> filter(has_text: html_text(MoneyUtils.format(new_amount))) |> visible())
    end

    test "does not update transaction on cancel", %{conn: conn, loan: loan} do
      transaction = Factory.lend(loan)
      new_date = Factory.date()
      new_memo = Factory.memo()
      new_amount = Money.negate!(Factory.money())

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans/#{loan}/transactions/#{transaction}/edit")
      |> fill(by_label("Date", exact: true), to_string(new_date))
      |> fill(by_label("Memo", exact: true), to_string(new_memo))
      |> fill(by_label("Amount", exact: true), to_string(new_amount))
      |> click(by_role(:link, name: "Cancel"))
      |> assert(heading() |> by_css() |> filter(has_text: html_text(loan)) |> visible())
      |> assert(heading() |> by_css() |> filter(has_text: html_text(MoneyUtils.format(transaction.amount))) |> visible())
      |> assert(
        loan
        |> sidebar_loan_balance()
        |> by_css()
        |> filter(has_text: html_text(MoneyUtils.format(transaction.amount)))
        |> visible()
      )
    end
  end
end
