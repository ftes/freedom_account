defmodule FreedomAccountWeb.LoanTransactionListTest do
  use FreedomAccountWeb.ConnCase, async: true

  alias FreedomAccount.Factory
  alias FreedomAccount.LocalTime
  alias FreedomAccount.MoneyUtils
  alias FreedomAccountWeb.LoanTransactionList

  setup [:create_account, :create_loan]

  describe "Index" do
    test "shows message when loan has no transactions", %{conn: conn, loan: loan} do
      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans/#{loan}")
      |> expect(visible(by_css("#no-transactions")))
    end

    test "displays transactions", %{conn: conn, loan: loan} do
      lend = Factory.lend(loan)
      payment = Factory.payment(loan)
      balance = Money.add!(lend.amount, payment.amount)

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans/#{loan}")
      |> expect(table_cell() |> by_css() |> filter(has_text: html_text("#{lend.date}")) |> visible())
      |> expect(table_cell() |> by_css() |> filter(has_text: html_text(lend.memo)) |> visible())
      |> expect("loan" |> role() |> by_css() |> filter(has_text: html_text(MoneyUtils.format(lend.amount))) |> visible())
      |> expect(table_cell() |> by_css() |> filter(has_text: html_text("#{payment.date}")) |> visible())
      |> expect(table_cell() |> by_css() |> filter(has_text: html_text(payment.memo)) |> visible())
      |> expect(
        "payment"
        |> role()
        |> by_css()
        |> filter(has_text: html_text(MoneyUtils.format(payment.amount)))
        |> visible()
      )
      |> expect(table_cell() |> by_css() |> filter(has_text: html_text(MoneyUtils.format(balance))) |> visible())
    end

    test "paginates transactions", %{conn: conn, loan: loan} do
      page_size = LoanTransactionList.page_size()
      count = round(page_size * 2.5)

      transactions =
        for i <- 1..count do
          Factory.lend(loan, date: Date.shift(LocalTime.today(), day: i * -1))
        end

      [page1, page2, page3] = Enum.chunk_every(transactions, page_size)

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans/#{loan}")
      |> assert_has_all_transactions(page1)
      |> expect("button" |> disabled() |> by_css() |> filter(has_text: html_text("Previous Page")) |> visible())
      |> expect("button" |> enabled() |> by_css() |> filter(has_text: html_text("Next Page")) |> visible())
      |> click(by_role(:button, name: "Next Page"))
      |> assert_has_all_transactions(page2)
      |> expect("button" |> enabled() |> by_css() |> filter(has_text: html_text("Previous Page")) |> visible())
      |> expect("button" |> enabled() |> by_css() |> filter(has_text: html_text("Next Page")) |> visible())
      |> click(by_role(:button, name: "Next Page"))
      |> assert_has_all_transactions(page3)
      |> expect("button" |> enabled() |> by_css() |> filter(has_text: html_text("Previous Page")) |> visible())
      |> expect("button" |> disabled() |> by_css() |> filter(has_text: html_text("Next Page")) |> visible())
      |> click(by_role(:button, name: "Previous Page"))
      |> click(by_role(:button, name: "Previous Page"))
      |> assert_has_all_transactions(page1)
      |> expect("button" |> disabled() |> by_css() |> filter(has_text: html_text("Previous Page")) |> visible())
      |> expect("button" |> enabled() |> by_css() |> filter(has_text: html_text("Next Page")) |> visible())
    end

    test "allows editing transaction in listing", %{conn: conn, loan: loan} do
      transaction = Factory.lend(loan)

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans/#{loan}")
      |> click("#txn-#{transaction.id} td" |> by_css() |> filter(has_text: html_text(transaction.memo)))
      |> expect(Expect.url(~p"/loans/#{loan}/transactions/#{transaction}/edit"))
      |> click(by_role(:link, name: "Cancel"))
      |> expect(heading() |> by_css() |> filter(has_text: html_text(loan)) |> visible())
    end

    test "deletes transaction in listing", %{conn: conn, loan: loan} do
      transaction = Factory.lend(loan)

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans/#{loan}")
      |> click("#txn-#{transaction.id}" |> action_link() |> by_css() |> filter(has_text: html_text("Delete")))
      |> expect(heading() |> by_css() |> filter(has_text: html_text(loan)) |> visible())
      |> expect(heading() |> by_css() |> filter(has_text: html_text("$0.00")) |> visible())
      |> expect(loan |> sidebar_loan_balance() |> by_css() |> filter(has_text: html_text("$0.00")) |> visible())
      |> expect(count(by_css("#txn-#{transaction.id}"), 0))
    end

    defp assert_has_all_transactions(session, transactions) do
      Enum.reduce(transactions, session, fn txn, session ->
        expect(session, table_cell() |> by_css() |> filter(has_text: html_text("#{txn.date}")) |> visible())
      end)
    end
  end
end
