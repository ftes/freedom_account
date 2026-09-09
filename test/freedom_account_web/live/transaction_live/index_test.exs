defmodule FreedomAccountWeb.TransactionLive.IndexTest do
  use FreedomAccountWeb.ConnCase, async: true

  alias FreedomAccount.Factory
  alias FreedomAccount.LocalTime
  alias FreedomAccount.MoneyUtils
  alias FreedomAccountWeb.TransactionLive

  setup [:create_account, :create_fund, :create_loan]

  describe "listing account transactions" do
    test "shows message when account has no transactions", %{conn: conn} do
      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/transactions")
      |> assert(visible(by_css("#no-transactions")))
    end

    test "displays transactions", %{conn: conn, account: account, fund: fund, loan: loan} do
      deposit = Factory.deposit(fund)
      [deposit_line_item] = deposit.line_items
      withdrawal = Factory.withdrawal(account, fund)
      [withdrawal_line_item] = withdrawal.line_items
      lend = Factory.lend(loan)
      payment = Factory.payment(loan)
      balance = MoneyUtils.sum([deposit_line_item.amount, withdrawal_line_item.amount, lend.amount, payment.amount])

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/transactions")
      |> assert(table_cell() |> by_css() |> filter(has_text: html_text("#{deposit.date}")) |> visible())
      |> assert(table_cell() |> by_css() |> filter(has_text: html_text(deposit.memo)) |> visible())
      |> assert(
        "in"
        |> role()
        |> by_css()
        |> filter(has_text: html_text(MoneyUtils.format(deposit_line_item.amount)))
        |> visible()
      )
      |> assert(table_cell() |> by_css() |> filter(has_text: html_text("#{withdrawal.date}")) |> visible())
      |> assert(table_cell() |> by_css() |> filter(has_text: html_text(withdrawal.memo)) |> visible())
      |> assert(table_cell() |> by_css() |> filter(has_text: html_text(fund)) |> count(2))
      |> assert(
        "out"
        |> role()
        |> by_css()
        |> filter(has_text: html_text(MoneyUtils.format(withdrawal_line_item.amount)))
        |> visible()
      )
      |> assert(table_cell() |> by_css() |> filter(has_text: html_text("#{lend.date}")) |> visible())
      |> assert(table_cell() |> by_css() |> filter(has_text: html_text(lend.memo)) |> visible())
      |> assert("out" |> role() |> by_css() |> filter(has_text: html_text(MoneyUtils.format(lend.amount))) |> visible())
      |> assert(table_cell() |> by_css() |> filter(has_text: html_text("#{payment.date}")) |> visible())
      |> assert(table_cell() |> by_css() |> filter(has_text: html_text(payment.memo)) |> visible())
      |> assert(table_cell() |> by_css() |> filter(has_text: html_text(loan)) |> count(2))
      |> assert("in" |> role() |> by_css() |> filter(has_text: html_text(MoneyUtils.format(payment.amount))) |> visible())
      |> assert(table_cell() |> by_css() |> filter(has_text: html_text(MoneyUtils.format(balance))) |> visible())
    end

    test "paginates transactions", %{conn: conn, fund: fund} do
      page_size = TransactionLive.Index.page_size()
      count = round(page_size * 2.5)

      transactions =
        for i <- 1..count do
          Factory.deposit(fund, date: Date.shift(LocalTime.today(), day: i * -1))
        end

      [page1, page2, page3] = Enum.chunk_every(transactions, page_size)

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/transactions")
      |> assert_has_all_transactions(page1)
      |> assert("button" |> disabled() |> by_css() |> filter(has_text: html_text("Previous Page")) |> visible())
      |> assert("button" |> enabled() |> by_css() |> filter(has_text: html_text("Next Page")) |> visible())
      |> click(by_role(:button, name: "Next Page"))
      |> assert_has_all_transactions(page2)
      |> assert("button" |> enabled() |> by_css() |> filter(has_text: html_text("Previous Page")) |> visible())
      |> assert("button" |> enabled() |> by_css() |> filter(has_text: html_text("Next Page")) |> visible())
      |> click(by_role(:button, name: "Next Page"))
      |> assert_has_all_transactions(page3)
      |> assert("button" |> enabled() |> by_css() |> filter(has_text: html_text("Previous Page")) |> visible())
      |> assert("button" |> disabled() |> by_css() |> filter(has_text: html_text("Next Page")) |> visible())
      |> click(by_role(:button, name: "Previous Page"))
      |> click(by_role(:button, name: "Previous Page"))
      |> assert_has_all_transactions(page1)
      |> assert("button" |> disabled() |> by_css() |> filter(has_text: html_text("Previous Page")) |> visible())
      |> assert("button" |> enabled() |> by_css() |> filter(has_text: html_text("Next Page")) |> visible())
    end

    test "allows editing fund transaction in listing", %{conn: conn, fund: fund} do
      deposit = Factory.deposit(fund)

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/transactions")
      |> click("#txn-fund-#{deposit.id} td" |> by_css() |> filter(has_text: html_text(deposit.memo)))
      |> assert(page_url(~p"/transactions/#{deposit}/edit?type=fund"))
      |> click(by_role(:link, name: "Cancel"))
      |> assert(active_tab() |> by_css() |> filter(has_text: html_text("Transactions")) |> visible())
    end

    test "allows editing loan transaction in listing", %{conn: conn, loan: loan} do
      transaction = Factory.lend(loan)

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/transactions")
      |> click("#txn-loan-#{transaction.id} td" |> by_css() |> filter(has_text: html_text(transaction.memo)))
      |> assert(page_url(~p"/transactions/#{transaction}/edit?type=loan"))
      |> click(by_role(:link, name: "Cancel"))
      |> assert(active_tab() |> by_css() |> filter(has_text: html_text("Transactions")) |> visible())
    end

    test "deletes fund transaction in listing", %{conn: conn, fund: fund} do
      deposit = Factory.deposit(fund)

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/transactions")
      |> click("#txn-fund-#{deposit.id}" |> action_link() |> by_css() |> filter(has_text: html_text("Delete")))
      |> assert(active_tab() |> by_css() |> filter(has_text: html_text("Transactions")) |> visible())
      |> assert(account_balance() |> by_css() |> filter(has_text: html_text("$0.00")) |> visible())
      |> assert(count(by_css("#txn-#{deposit.id}"), 0))
    end

    test "deletes loan transaction in listing", %{conn: conn, loan: loan} do
      lend = Factory.lend(loan)

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/transactions")
      |> click("#txn-loan-#{lend.id}" |> action_link() |> by_css() |> filter(has_text: html_text("Delete")))
      |> assert(active_tab() |> by_css() |> filter(has_text: html_text("Transactions")) |> visible())
      |> assert(account_balance() |> by_css() |> filter(has_text: html_text("$0.00")) |> visible())
      |> assert(count(by_css("#txn-#{lend.id}"), 0))
    end

    defp assert_has_all_transactions(session, transactions) do
      Enum.reduce(transactions, session, fn txn, session ->
        assert(session, table_cell() |> by_css() |> filter(has_text: html_text("#{txn.date}")) |> visible())
      end)
    end
  end
end
