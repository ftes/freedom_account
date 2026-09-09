defmodule FreedomAccountWeb.FundLive.TransactionFormTest do
  use FreedomAccountWeb.ConnCase, async: true

  alias FreedomAccount.Factory
  alias FreedomAccount.MoneyUtils
  alias FreedomAccount.Transactions

  setup [:create_account, :create_fund]

  describe "updating transactions" do
    test "edits single-fund transaction", %{conn: conn, fund: fund} do
      deposit = Factory.deposit(fund)
      [line_item] = deposit.line_items
      new_date = Factory.date()
      new_memo = Factory.memo()
      new_amount = Factory.money()

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds/#{fund}/transactions/#{deposit}/edit")
      |> assert(page_title_contains("Edit Transaction"))
      |> assert(heading() |> by_css() |> filter(has_text: html_text("Edit Transaction")) |> visible())
      |> assert(visible(by_css(field_value("#transaction_date", deposit.date))))
      |> assert(visible(by_css(field_value("#transaction_memo", deposit.memo))))
      |> assert(visible(by_css(field_value("#transaction_line_items_0_amount", line_item.amount))))
      |> assert("label" |> by_css() |> filter(has_text: html_text(fund.name)) |> visible())
      |> fill(by_label("Date", exact: true), to_string(new_date))
      |> fill(by_label("Memo", exact: true), to_string(new_memo))
      |> fill(by_label("Amount 0", exact: true), to_string(new_amount))
      |> click(by_role(:button, name: "Save Transaction"))
      |> assert(
        :info
        |> flash()
        |> by_css()
        |> filter(has_text: html_text("Transaction updated successfully"))
        |> visible()
      )
      |> assert(heading() |> by_css() |> filter(has_text: html_text(fund)) |> visible())
      |> assert(heading() |> by_css() |> filter(has_text: html_text(MoneyUtils.format(new_amount))) |> visible())
      |> assert(
        fund
        |> sidebar_fund_balance()
        |> by_css()
        |> filter(has_text: html_text(MoneyUtils.format(new_amount)))
        |> visible()
      )
      |> assert(table_cell() |> by_css() |> filter(has_text: html_text("#{new_date}")) |> visible())
      |> assert(table_cell() |> by_css() |> filter(has_text: html_text(new_memo)) |> visible())
      |> assert(
        "deposit"
        |> role()
        |> by_css()
        |> filter(has_text: html_text(MoneyUtils.format(new_amount)))
        |> visible()
      )
    end

    test "edits multi-fund transaction", %{account: account, conn: conn, fund: fund1} do
      [fund2, fund3] = more_funds = for _i <- 1..2, do: Factory.fund(account)
      funds = [fund1 | more_funds]
      {:ok, transaction} = Transactions.regular_deposit(account, Factory.date(), funds)
      [line_item1, line_item2, line_item3] = transaction.line_items
      new_date = Factory.date()
      new_memo = Factory.memo()
      [new_amount1, new_amount2, new_amount3] = for _i <- 1..3, do: Factory.money()

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds/#{fund1}/transactions/#{transaction}/edit")
      |> assert(page_title_contains("Edit Transaction"))
      |> assert(heading() |> by_css() |> filter(has_text: html_text("Edit Transaction")) |> visible())
      |> assert(visible(by_css(field_value("#transaction_date", transaction.date))))
      |> assert(visible(by_css(field_value("#transaction_memo", transaction.memo))))
      |> assert(visible(by_css(field_value("#transaction_line_items_0_amount", line_item1.amount))))
      |> assert(visible(by_css(field_value("#transaction_line_items_1_amount", line_item2.amount))))
      |> assert(visible(by_css(field_value("#transaction_line_items_2_amount", line_item3.amount))))
      |> assert("label" |> by_css() |> filter(has_text: html_text(fund1)) |> visible())
      |> assert("label" |> by_css() |> filter(has_text: html_text(fund2)) |> visible())
      |> assert("label" |> by_css() |> filter(has_text: html_text(fund3)) |> visible())
      |> fill(by_label("Date", exact: true), to_string(new_date))
      |> fill(by_label("Memo", exact: true), to_string(new_memo))
      |> fill(by_label("Amount 0", exact: true), to_string(new_amount1))
      |> fill(by_label("Amount 1", exact: true), to_string(new_amount2))
      |> fill(by_label("Amount 2", exact: true), to_string(new_amount3))
      |> click(by_role(:button, name: "Save Transaction"))
      |> assert(
        :info
        |> flash()
        |> by_css()
        |> filter(has_text: html_text("Transaction updated successfully"))
        |> visible()
      )
      |> assert(table_cell() |> by_css() |> filter(has_text: html_text("#{new_date}")) |> visible())
      |> assert(table_cell() |> by_css() |> filter(has_text: html_text(new_memo)) |> visible())
      |> assert(
        "deposit"
        |> role()
        |> by_css()
        |> filter(has_text: html_text(MoneyUtils.format(new_amount1)))
        |> visible()
      )
    end

    test "does not update transaction on cancel", %{conn: conn, fund: fund} do
      deposit = Factory.deposit(fund)
      [line_item] = deposit.line_items
      new_date = Factory.date()
      new_memo = Factory.memo()
      new_amount = Factory.money()

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds/#{fund}/transactions/#{deposit}/edit")
      |> fill(by_label("Date", exact: true), to_string(new_date))
      |> fill(by_label("Memo", exact: true), to_string(new_memo))
      |> fill(by_label("Amount 0", exact: true), to_string(new_amount))
      |> click(by_role(:link, name: "Cancel"))
      |> assert(heading() |> by_css() |> filter(has_text: html_text(fund)) |> visible())
      |> assert(heading() |> by_css() |> filter(has_text: html_text(MoneyUtils.format(line_item.amount))) |> visible())
      |> assert(
        fund
        |> sidebar_fund_balance()
        |> by_css()
        |> filter(has_text: html_text(MoneyUtils.format(line_item.amount)))
        |> visible()
      )
    end
  end
end
