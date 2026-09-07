defmodule FreedomAccountWeb.FundTransactionListTest do
  use FreedomAccountWeb.ConnCase, async: true

  alias FreedomAccount.Factory
  alias FreedomAccount.LocalTime
  alias FreedomAccount.MoneyUtils
  alias FreedomAccountWeb.FundTransactionList

  setup [:create_account, :create_fund]

  describe "Index" do
    test "shows message when fund has no transactions", %{conn: conn, fund: fund} do
      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds/#{fund}")
      |> expect(visible(by_css("#no-transactions")))
    end

    test "displays transactions", %{conn: conn, account: account, fund: fund} do
      deposit = Factory.deposit(fund)
      [deposit_line_item] = deposit.line_items
      withdrawal = Factory.withdrawal(account, fund)
      [withdrawal_line_item] = withdrawal.line_items
      balance = Money.add!(deposit_line_item.amount, withdrawal_line_item.amount)

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds/#{fund}")
      |> expect(table_cell() |> by_css() |> filter(has_text: html_text("#{deposit.date}")) |> visible())
      |> expect(table_cell() |> by_css() |> filter(has_text: html_text(deposit.memo)) |> visible())
      |> expect(
        "deposit"
        |> role()
        |> by_css()
        |> filter(has_text: html_text(MoneyUtils.format(deposit_line_item.amount)))
        |> visible()
      )
      |> expect(table_cell() |> by_css() |> filter(has_text: html_text("#{withdrawal.date}")) |> visible())
      |> expect(table_cell() |> by_css() |> filter(has_text: html_text(withdrawal.memo)) |> visible())
      |> expect(
        "withdrawal"
        |> role()
        |> by_css()
        |> filter(has_text: html_text(MoneyUtils.format(withdrawal_line_item.amount)))
        |> visible()
      )
      |> expect(table_cell() |> by_css() |> filter(has_text: html_text(MoneyUtils.format(balance))) |> visible())
    end

    test "paginates transactions", %{conn: conn, fund: fund} do
      page_size = FundTransactionList.page_size()
      count = round(page_size * 2.5)

      transactions =
        for i <- 1..count do
          Factory.deposit(fund, date: Date.shift(LocalTime.today(), day: i * -1))
        end

      [page1, page2, page3] = Enum.chunk_every(transactions, page_size)

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds/#{fund}")
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

    test "allows editing transaction in listing", %{conn: conn, fund: fund} do
      deposit = Factory.deposit(fund)
      [line_item] = deposit.line_items

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds/#{fund}")
      |> click("#txn-#{line_item.id} td" |> by_css() |> filter(has_text: html_text(deposit.memo)))
      |> expect(Expect.url(~p"/funds/#{fund}/transactions/#{deposit}/edit"))
      |> click(by_role(:link, name: "Cancel"))
      |> expect(heading() |> by_css() |> filter(has_text: html_text(fund)) |> visible())
    end

    test "deletes transaction in listing", %{conn: conn, fund: fund} do
      deposit = Factory.deposit(fund)
      [line_item] = deposit.line_items

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds/#{fund}")
      |> click("#txn-#{line_item.id}" |> action_link() |> by_css() |> filter(has_text: html_text("Delete")))
      |> expect(heading() |> by_css() |> filter(has_text: html_text(fund)) |> visible())
      |> expect(heading() |> by_css() |> filter(has_text: html_text("$0.00")) |> visible())
      |> expect(fund |> sidebar_fund_balance() |> by_css() |> filter(has_text: html_text("$0.00")) |> visible())
      |> expect(count(by_css("#txn-#{line_item.id}"), 0))
    end

    defp assert_has_all_transactions(session, transactions) do
      Enum.reduce(transactions, session, fn txn, session ->
        expect(session, table_cell() |> by_css() |> filter(has_text: html_text("#{txn.date}")) |> visible())
      end)
    end
  end
end
