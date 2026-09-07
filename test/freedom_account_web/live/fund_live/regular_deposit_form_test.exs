defmodule FreedomAccountWeb.FundLive.RegularDepositFormTest do
  use FreedomAccountWeb.ConnCase, async: true

  alias FreedomAccount.Accounts.Account
  alias FreedomAccount.Factory
  alias FreedomAccount.Funds
  alias FreedomAccount.Funds.Fund
  alias FreedomAccount.LocalTime
  alias FreedomAccount.MoneyUtils

  describe "making a regular deposit" do
    setup [:create_account, :create_funds]

    test "makes regular deposit", %{account: account, conn: conn, funds: funds} do
      [fund1, fund2, fund3] = funds
      [balance1, balance2, balance3] = Enum.map(funds, &expected_balance(&1, account))

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds/regular_deposit")
      |> expect(page_title_contains("Regular Deposit"))
      |> expect(heading() |> by_css() |> filter(has_text: html_text("Regular Deposit")) |> visible())
      |> expect(visible(by_css(field_value("#inputs_date", "#{LocalTime.today()}"))))
      |> fill(by_label("Date", exact: true), to_string(""))
      |> expect("#inputs_date" |> field_error() |> by_css() |> filter(has_text: html_text("can't be blank")) |> visible())
      |> fill(by_label("Date", exact: true), to_string(Factory.date()))
      |> click(by_role(:button, name: "Make Deposit"))
      |> expect(:info |> flash() |> by_css() |> filter(has_text: html_text("Regular deposit successful")) |> visible())
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

    test "does not make deposit on cancel", %{conn: conn, funds: funds} do
      [fund1, fund2, fund3] = funds

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds/regular_deposit")
      |> fill(by_label("Date", exact: true), to_string(Factory.date()))
      |> click(by_role(:link, name: "Cancel"))
      |> expect(active_tab() |> by_css() |> filter(has_text: html_text("Funds")) |> visible())
      |> expect(
        fund1
        |> fund_balance()
        |> by_css()
        |> filter(has_text: html_text(MoneyUtils.format(fund1.current_balance)))
        |> visible()
      )
      |> expect(
        fund2
        |> fund_balance()
        |> by_css()
        |> filter(has_text: html_text(MoneyUtils.format(fund2.current_balance)))
        |> visible()
      )
      |> expect(
        fund3
        |> fund_balance()
        |> by_css()
        |> filter(has_text: html_text(MoneyUtils.format(fund3.current_balance)))
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

  defp expected_balance(%Fund{} = fund, %Account{} = account) do
    fund
    |> Funds.regular_deposit_amount(account)
    |> Money.add!(fund.current_balance)
  end
end
