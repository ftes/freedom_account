defmodule FreedomAccountWeb.FundLive.RegularWithdrawalFormTest do
  use FreedomAccountWeb.ConnCase, async: true

  alias FreedomAccount.Factory
  alias FreedomAccount.MoneyUtils

  describe "making a regular withdrawal" do
    setup [:create_account, :create_funds]

    test "makes regular withdrawal", %{conn: conn, funds: funds} do
      [fund1, fund2, fund3] = funds

      [{amount1, balance1}, {amount2, balance2}, {amount3, balance3}] =
        for fund <- funds do
          amount = fund.current_balance |> Money.mult!(:rand.uniform()) |> Money.round()
          balance = Money.sub!(fund.current_balance, amount)
          {amount, balance}
        end

      total1 = amount1
      total2 = Money.add!(total1, amount2)
      total3 = Money.add!(total2, amount3)

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds/regular_withdrawal")
      |> expect(page_title_contains("Regular Withdrawal"))
      |> expect(heading() |> by_css() |> filter(has_text: html_text("Regular Withdrawal")) |> visible())
      |> expect(
        "#transaction-total"
        |> by_css()
        |> filter(has_text: :usd |> Money.zero() |> MoneyUtils.format() |> html_text())
        |> visible()
      )
      |> expect("label" |> by_css() |> filter(has_text: html_text(fund1)) |> visible())
      |> expect("label" |> by_css() |> filter(has_text: html_text(fund2)) |> visible())
      |> expect("label" |> by_css() |> filter(has_text: html_text(fund3)) |> visible())
      |> fill(by_label("Date", exact: true), to_string(""))
      |> expect(
        "#transaction_date"
        |> field_error()
        |> by_css()
        |> filter(has_text: html_text("can't be blank"))
        |> visible()
      )
      |> fill(by_label("Date", exact: true), to_string(Factory.date()))
      |> fill(by_label("Memo", exact: true), to_string("Cover expenses"))
      |> click(by_role(:button, name: "Make Withdrawal"))
      |> expect(
        "#line-items-error"
        |> by_css()
        |> filter(has_text: html_text("Requires at least one line item with a non-zero amount"))
        |> visible()
      )
      |> fill(by_label("Amount 0", exact: true), to_string("#{amount1}"))
      |> expect("#transaction-total" |> by_css() |> filter(has_text: html_text(MoneyUtils.format(total1))) |> visible())
      |> fill(by_label("Amount 1", exact: true), to_string("#{amount2}"))
      |> expect("#transaction-total" |> by_css() |> filter(has_text: html_text(MoneyUtils.format(total2))) |> visible())
      |> fill(by_label("Amount 2", exact: true), to_string("#{amount3}"))
      |> expect("#transaction-total" |> by_css() |> filter(has_text: html_text(MoneyUtils.format(total3))) |> visible())
      |> click(by_role(:button, name: "Make Withdrawal"))
      |> expect(:info |> flash() |> by_css() |> filter(has_text: html_text("Withdrawal successful")) |> visible())
      |> expect(active_tab() |> by_css() |> filter(has_text: html_text("Funds")) |> visible())
      |> expect(
        fund1
        |> fund_balance()
        |> by_css()
        |> filter(has_text: html_text(MoneyUtils.format(balance1)))
        |> visible()
      )
      |> expect(
        fund2
        |> fund_balance()
        |> by_css()
        |> filter(has_text: html_text(MoneyUtils.format(balance2)))
        |> visible()
      )
      |> expect(
        fund3
        |> fund_balance()
        |> by_css()
        |> filter(has_text: html_text(MoneyUtils.format(balance3)))
        |> visible()
      )
    end

    test "does not make withdrawal on cancel", %{conn: conn, funds: funds} do
      fund1 = hd(funds)
      amount = fund1.current_balance |> Money.mult!(:rand.uniform()) |> Money.round()

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds/regular_withdrawal")
      |> fill(by_label("Date", exact: true), to_string(Factory.date()))
      |> fill(by_label("Memo", exact: true), to_string("Cover expenses"))
      |> fill(by_label("Amount 0", exact: true), to_string("#{amount}"))
      |> click(by_role(:link, name: "Cancel"))
      |> expect(active_tab() |> by_css() |> filter(has_text: html_text("Funds")) |> visible())
      |> expect(
        fund1
        |> fund_balance()
        |> by_css()
        |> filter(has_text: html_text(MoneyUtils.format(fund1.current_balance)))
        |> visible()
      )
    end
  end

  defp create_funds(%{account: account}) do
    funds =
      for _i <- 1..3 do
        account |> Factory.fund() |> Factory.with_fund_balance()
      end

    %{funds: Enum.sort_by(funds, & &1.name)}
  end
end
