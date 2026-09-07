defmodule FreedomAccountWeb.TransactionLive.TransactionFormTest do
  use FreedomAccountWeb.ConnCase, async: true

  alias FreedomAccount.Factory
  alias FreedomAccount.MoneyUtils
  alias FreedomAccount.Transactions

  setup [:create_account, :create_fund, :create_loan]

  describe "updating account transactions" do
    test "edits single-fund transaction", %{conn: conn, fund: fund} do
      deposit = Factory.deposit(fund)
      [line_item] = deposit.line_items
      new_date = Factory.date()
      new_memo = Factory.memo()
      new_amount = Factory.money()

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/transactions/#{deposit}/edit?type=fund")
      |> expect(page_title_contains("Edit Transaction"))
      |> expect(heading() |> by_css() |> filter(has_text: html_text("Edit Transaction")) |> visible())
      |> expect(visible(by_css(field_value("#transaction_date", deposit.date))))
      |> expect(visible(by_css(field_value("#transaction_memo", deposit.memo))))
      |> expect(visible(by_css(field_value("#transaction_line_items_0_amount", line_item.amount))))
      |> expect("label" |> by_css() |> filter(has_text: html_text(fund.name)) |> visible())
      |> fill(by_label("Date", exact: true), to_string(new_date))
      |> fill(by_label("Memo", exact: true), to_string(new_memo))
      |> fill(by_label("Amount 0", exact: true), to_string(new_amount))
      |> click(by_role(:button, name: "Save Transaction"))
      |> expect(
        :info
        |> flash()
        |> by_css()
        |> filter(has_text: html_text("Transaction updated successfully"))
        |> visible()
      )
      |> expect(active_tab() |> by_css() |> filter(has_text: html_text("Transactions")) |> visible())
      |> expect(account_balance() |> by_css() |> filter(has_text: html_text(MoneyUtils.format(new_amount))) |> visible())
      |> expect(table_cell() |> by_css() |> filter(has_text: html_text("#{new_date}")) |> visible())
      |> expect(table_cell() |> by_css() |> filter(has_text: html_text(new_memo)) |> visible())
      |> expect("in" |> role() |> by_css() |> filter(has_text: html_text(MoneyUtils.format(new_amount))) |> visible())
    end

    test "edits multi-fund transaction", %{account: account, conn: conn, fund: fund1} do
      [fund2, fund3] = more_funds = for _i <- 1..2, do: Factory.fund(account)
      funds = [fund1 | more_funds]
      {:ok, transaction} = Transactions.regular_deposit(account, Factory.date(), funds)
      [line_item1, line_item2, line_item3] = transaction.line_items
      new_date = Factory.date()
      new_memo = Factory.memo()
      [new_amount1, new_amount2, new_amount3] = new_amounts = for _i <- 1..3, do: Factory.money()
      net_amount = MoneyUtils.sum(new_amounts)

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/transactions/#{transaction}/edit?type=fund")
      |> expect(page_title_contains("Edit Transaction"))
      |> expect(heading() |> by_css() |> filter(has_text: html_text("Edit Transaction")) |> visible())
      |> expect(visible(by_css(field_value("#transaction_date", transaction.date))))
      |> expect(visible(by_css(field_value("#transaction_memo", transaction.memo))))
      |> expect(visible(by_css(field_value("#transaction_line_items_0_amount", line_item1.amount))))
      |> expect(visible(by_css(field_value("#transaction_line_items_1_amount", line_item2.amount))))
      |> expect(visible(by_css(field_value("#transaction_line_items_2_amount", line_item3.amount))))
      |> expect("label" |> by_css() |> filter(has_text: html_text(fund1)) |> visible())
      |> expect("label" |> by_css() |> filter(has_text: html_text(fund2)) |> visible())
      |> expect("label" |> by_css() |> filter(has_text: html_text(fund3)) |> visible())
      |> fill(by_label("Date", exact: true), to_string(new_date))
      |> fill(by_label("Memo", exact: true), to_string(new_memo))
      |> fill(by_label("Amount 0", exact: true), to_string(new_amount1))
      |> fill(by_label("Amount 1", exact: true), to_string(new_amount2))
      |> fill(by_label("Amount 2", exact: true), to_string(new_amount3))
      |> click(by_role(:button, name: "Save Transaction"))
      |> expect(
        :info
        |> flash()
        |> by_css()
        |> filter(has_text: html_text("Transaction updated successfully"))
        |> visible()
      )
      |> expect(table_cell() |> by_css() |> filter(has_text: html_text("#{new_date}")) |> visible())
      |> expect(table_cell() |> by_css() |> filter(has_text: html_text(new_memo)) |> visible())
      |> expect("in" |> role() |> by_css() |> filter(has_text: html_text(MoneyUtils.format(net_amount))) |> visible())
    end

    test "does not update fund transaction on cancel", %{conn: conn, fund: fund} do
      deposit = Factory.deposit(fund)
      [line_item] = deposit.line_items
      new_date = Factory.date()
      new_memo = Factory.memo()
      new_amount = Factory.money()

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/transactions/#{deposit}/edit?type=fund")
      |> fill(by_label("Date", exact: true), to_string(new_date))
      |> fill(by_label("Memo", exact: true), to_string(new_memo))
      |> fill(by_label("Amount 0", exact: true), to_string(new_amount))
      |> click(by_role(:link, name: "Cancel"))
      |> expect(active_tab() |> by_css() |> filter(has_text: html_text("Transactions")) |> visible())
      |> expect(
        account_balance()
        |> by_css()
        |> filter(has_text: html_text(MoneyUtils.format(line_item.amount)))
        |> visible()
      )
    end

    test "edits loan transaction", %{conn: conn, loan: loan} do
      transaction = Factory.lend(loan)
      new_date = Factory.date()
      new_memo = Factory.memo()
      new_amount = Money.negate!(Factory.money())

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/transactions/#{transaction}/edit?type=loan")
      |> expect(page_title_contains("Edit Loan Transaction"))
      |> expect(heading() |> by_css() |> filter(has_text: html_text("Edit Loan Transaction")) |> visible())
      |> expect("loan" |> role() |> by_css() |> filter(has_text: html_text(loan)) |> visible())
      |> expect(visible(by_css(field_value("#loan_transaction_date", transaction.date))))
      |> expect(visible(by_css(field_value("#loan_transaction_memo", transaction.memo))))
      |> expect(visible(by_css(field_value("#loan_transaction_amount", transaction.amount))))
      |> fill(by_label("Date", exact: true), to_string(new_date))
      |> fill(by_label("Memo", exact: true), to_string(new_memo))
      |> fill(by_label("Amount", exact: true), to_string(new_amount))
      |> click(by_role(:button, name: "Save Transaction"))
      |> expect(
        :info
        |> flash()
        |> by_css()
        |> filter(has_text: html_text("Transaction updated successfully"))
        |> visible()
      )
      |> expect(active_tab() |> by_css() |> filter(has_text: html_text("Transactions")) |> visible())
      |> expect(account_balance() |> by_css() |> filter(has_text: html_text(MoneyUtils.format(new_amount))) |> visible())
      |> expect(table_cell() |> by_css() |> filter(has_text: html_text("#{new_date}")) |> visible())
      |> expect(table_cell() |> by_css() |> filter(has_text: html_text(new_memo)) |> visible())
      |> expect("out" |> role() |> by_css() |> filter(has_text: html_text(MoneyUtils.format(new_amount))) |> visible())
    end

    test "does not update loan transaction on cancel", %{conn: conn, loan: loan} do
      transaction = Factory.lend(loan)
      new_date = Factory.date()
      new_memo = Factory.memo()
      new_amount = Money.negate!(Factory.money())

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/transactions/#{transaction}/edit?type=loan")
      |> fill(by_label("Date", exact: true), to_string(new_date))
      |> fill(by_label("Memo", exact: true), to_string(new_memo))
      |> fill(by_label("Amount", exact: true), to_string(new_amount))
      |> click(by_role(:link, name: "Cancel"))
      |> expect(active_tab() |> by_css() |> filter(has_text: html_text("Transactions")) |> visible())
      |> expect(
        account_balance()
        |> by_css()
        |> filter(has_text: html_text(MoneyUtils.format(transaction.amount)))
        |> visible()
      )
    end
  end
end
