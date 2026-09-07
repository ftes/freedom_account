defmodule FreedomAccountWeb.FundLive.BudgetFormTest do
  use FreedomAccountWeb.ConnCase, async: true

  alias FreedomAccount.Accounts.Account
  alias FreedomAccount.Factory
  alias FreedomAccount.Funds
  alias FreedomAccount.Funds.Fund
  alias FreedomAccount.MoneyUtils

  describe "updating the budget" do
    setup :create_account

    test "updates budget", %{account: account, conn: conn} do
      funds =
        1..3
        |> Enum.map(fn _i -> Factory.fund(account) end)
        |> Enum.sort_by(& &1.name)

      [fund0, fund1, fund2] = funds
      attrs = [attrs0, attrs1, attrs2] = Enum.map(funds, fn _fund -> Factory.fund_attrs() end)

      amounts =
        [amount1, amount2, amount3] =
        funds
        |> Enum.zip(attrs)
        |> Enum.map(&regular_deposit_amount(&1, account))

      total = MoneyUtils.sum(amounts)

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds/budget")
      |> expect(page_title_contains("Update Budget"))
      |> expect(heading() |> by_css() |> filter(has_text: html_text("Update Budget")) |> visible())
      |> expect("label" |> by_css() |> filter(has_text: html_text(fund0)) |> visible())
      |> expect("label" |> by_css() |> filter(has_text: html_text(fund1)) |> visible())
      |> expect("label" |> by_css() |> filter(has_text: html_text(fund2)) |> visible())
      |> fill(by_label("Budget 1", exact: true), to_string(""))
      |> fill(by_label("Times/Year 2", exact: true), to_string(""))
      |> expect(
        "#budget_funds_1_budget"
        |> field_error()
        |> by_css()
        |> filter(has_text: html_text("can't be blank"))
        |> visible()
      )
      |> expect(
        "#budget_funds_2_times_per_year"
        |> field_error()
        |> by_css()
        |> filter(has_text: html_text("can't be blank"))
        |> visible()
      )
      |> fill(by_label("Budget 0", exact: true), to_string(attrs0[:budget]))
      |> fill(by_label("Times/Year 0", exact: true), to_string(attrs0[:times_per_year]))
      |> expect("deposit-amount-0" |> role() |> by_css() |> filter(has_text: html_text("#{amount1}")) |> visible())
      |> fill(by_label("Budget 1", exact: true), to_string(attrs1[:budget]))
      |> fill(by_label("Times/Year 1", exact: true), to_string(attrs1[:times_per_year]))
      |> expect("deposit-amount-1" |> role() |> by_css() |> filter(has_text: html_text("#{amount2}")) |> visible())
      |> fill(by_label("Budget 2", exact: true), to_string(attrs2[:budget]))
      |> fill(by_label("Times/Year 2", exact: true), to_string(attrs2[:times_per_year]))
      |> expect("deposit-amount-2" |> role() |> by_css() |> filter(has_text: html_text("#{amount3}")) |> visible())
      |> expect("#deposit-total" |> by_css() |> filter(has_text: html_text("#{total}")) |> visible())
      |> click(by_role(:button, name: "Update Budget"))
      |> expect(:info |> flash() |> by_css() |> filter(has_text: html_text("Budget updated successfully")) |> visible())
      |> expect(active_tab() |> by_css() |> filter(has_text: html_text("Funds")) |> visible())
      |> expect(fund1 |> fund_budget() |> by_css() |> filter(has_text: html_text("#{attrs1[:budget]}")) |> visible())
      |> expect(
        fund2
        |> fund_frequency()
        |> by_css()
        |> filter(has_text: html_text("#{attrs2[:times_per_year]}"))
        |> visible()
      )
    end

    test "does not update budget on cancel", %{account: account, conn: conn} do
      fund = Factory.fund(account)
      attrs = Factory.fund_attrs()

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds/budget")
      |> fill(by_label("Budget 0", exact: true), to_string(attrs[:budget]))
      |> fill(by_label("Times/Year 0", exact: true), to_string(attrs[:times_per_year]))
      |> click(by_role(:link, name: "Cancel"))
      |> expect(active_tab() |> by_css() |> filter(has_text: html_text("Funds")) |> visible())
      |> expect(fund |> fund_budget() |> by_css() |> filter(has_text: html_text("#{fund.budget}")) |> visible())
      |> expect(
        fund
        |> fund_frequency()
        |> by_css()
        |> filter(has_text: html_text("#{fund.times_per_year}"))
        |> visible()
      )
    end

    defp regular_deposit_amount({%Fund{} = fund, attrs}, %Account{} = account) do
      fund
      |> Funds.change_fund(attrs)
      |> Funds.regular_deposit_amount(account)
    end
  end
end
