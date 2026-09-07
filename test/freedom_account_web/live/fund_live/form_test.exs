defmodule FreedomAccountWeb.FundLive.FormTest do
  @moduledoc false

  use FreedomAccountWeb.ConnCase, async: true

  alias FreedomAccount.Factory
  alias FreedomAccount.MoneyUtils

  setup [:create_account]

  describe "creating a new fund" do
    test "saves new fund", %{conn: conn} do
      %{budget: budget, icon: icon, name: name, times_per_year: times_per_year} = Factory.fund_attrs()

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds/new")
      |> expect(page_title_contains("Add Fund"))
      |> expect(heading() |> by_css() |> filter(has_text: html_text("Add Fund")) |> visible())
      |> fill(by_label("Icon", exact: true), to_string(""))
      |> fill(by_label("Name", exact: true), to_string(""))
      |> expect("#fund_icon" |> field_error() |> by_css() |> filter(has_text: html_text("can't be blank")) |> visible())
      |> expect("#fund_name" |> field_error() |> by_css() |> filter(has_text: html_text("can't be blank")) |> visible())
      |> fill(by_label("Icon", exact: true), to_string(icon))
      |> fill(by_label("Name", exact: true), to_string(name))
      |> fill(by_label("Budget", exact: true), to_string(budget))
      |> fill(by_label("Times/Year", exact: true), to_string(times_per_year))
      |> click(by_role(:button, name: "Save Fund"))
      |> expect(:info |> flash() |> by_css() |> filter(has_text: html_text("Fund created successfully")) |> visible())
      |> expect(fund_icon() |> by_css() |> filter(has_text: html_text(icon)) |> visible())
      |> expect(fund_name() |> by_css() |> filter(has_text: html_text(name)) |> visible())
      |> expect(fund_budget() |> by_css() |> filter(has_text: html_text("#{budget}")) |> visible())
      |> expect(fund_frequency() |> by_css() |> filter(has_text: html_text("#{times_per_year}")) |> visible())
      |> expect(fund_balance() |> by_css() |> filter(has_text: html_text("$0.00")) |> visible())
    end

    test "does not create fund on cancel", %{conn: conn} do
      %{budget: budget, icon: icon, name: name, times_per_year: times_per_year} = Factory.fund_attrs()

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds/new")
      |> fill(by_label("Icon", exact: true), to_string(icon))
      |> fill(by_label("Name", exact: true), to_string(name))
      |> fill(by_label("Budget", exact: true), to_string(budget))
      |> fill(by_label("Times/Year", exact: true), to_string(times_per_year))
      |> click(by_role(:link, name: "Cancel"))
      |> expect(fund_name() |> by_css() |> filter(has_text: html_text(name)) |> count(0))
    end
  end

  describe "editing a fund" do
    test "updates fund settings", %{account: account, conn: conn} do
      fund = account |> Factory.fund() |> Factory.with_fund_balance()
      %{budget: budget, icon: icon, name: name, times_per_year: times_per_year} = Factory.fund_attrs()

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds/#{fund}/edit")
      |> expect(page_title_contains("Edit Fund"))
      |> expect(heading() |> by_css() |> filter(has_text: html_text("Edit Fund")) |> visible())
      |> fill(by_label("Icon", exact: true), to_string(""))
      |> fill(by_label("Name", exact: true), to_string(""))
      |> expect("#fund_icon" |> field_error() |> by_css() |> filter(has_text: html_text("can't be blank")) |> visible())
      |> expect("#fund_name" |> field_error() |> by_css() |> filter(has_text: html_text("can't be blank")) |> visible())
      |> fill(by_label("Icon", exact: true), to_string(icon))
      |> fill(by_label("Name", exact: true), to_string(name))
      |> fill(by_label("Budget", exact: true), to_string(budget))
      |> fill(by_label("Times/Year", exact: true), to_string(times_per_year))
      |> click(by_role(:button, name: "Save Fund"))
      |> expect(:info |> flash() |> by_css() |> filter(has_text: html_text("Fund updated successfully")) |> visible())
      |> expect(fund |> fund_icon() |> by_css() |> filter(has_text: html_text(icon)) |> visible())
      |> expect(fund |> fund_name() |> by_css() |> filter(has_text: html_text(name)) |> visible())
      |> expect(fund |> fund_budget() |> by_css() |> filter(has_text: html_text("#{budget}")) |> visible())
      |> expect(fund |> fund_frequency() |> by_css() |> filter(has_text: html_text("#{times_per_year}")) |> visible())
      |> expect(
        fund
        |> fund_balance()
        |> by_css()
        |> filter(has_text: html_text(MoneyUtils.format(fund.current_balance)))
        |> visible()
      )
    end

    test "does not update fund on cancel", %{account: account, conn: conn} do
      fund = account |> Factory.fund() |> Factory.with_fund_balance()
      %{budget: budget, icon: icon, name: name, times_per_year: times_per_year} = Factory.fund_attrs()

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds/#{fund}/edit")
      |> fill(by_label("Icon", exact: true), to_string(icon))
      |> fill(by_label("Name", exact: true), to_string(name))
      |> fill(by_label("Budget", exact: true), to_string(budget))
      |> fill(by_label("Times/Year", exact: true), to_string(times_per_year))
      |> click(by_role(:link, name: "Cancel"))
      |> expect(fund |> fund_icon() |> by_css() |> filter(has_text: html_text(fund.icon)) |> visible())
      |> expect(fund |> fund_name() |> by_css() |> filter(has_text: html_text(fund.name)) |> visible())
      |> expect(fund |> fund_budget() |> by_css() |> filter(has_text: html_text("#{fund.budget}")) |> visible())
      |> expect(
        fund
        |> fund_frequency()
        |> by_css()
        |> filter(has_text: html_text("#{fund.times_per_year}"))
        |> visible()
      )
      |> expect(
        fund
        |> fund_balance()
        |> by_css()
        |> filter(has_text: html_text(MoneyUtils.format(fund.current_balance)))
        |> visible()
      )
    end
  end

  describe "returning to calling view" do
    setup :create_fund

    test "returns to fund list by default on save", %{conn: conn, fund: fund} do
      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds/#{fund}/edit")
      |> click(by_role(:button, name: "Save Fund"))
      |> expect(active_tab() |> by_css() |> filter(has_text: html_text("Funds")) |> visible())
    end

    test "returns to fund list by default on cancel", %{conn: conn, fund: fund} do
      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds/#{fund}/edit")
      |> click(by_role(:link, name: "Cancel"))
      |> expect(active_tab() |> by_css() |> filter(has_text: html_text("Funds")) |> visible())
    end

    test "returns to fund list when specified on save", %{conn: conn, fund: fund} do
      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds/#{fund}/edit?return_to=index")
      |> click(by_role(:button, name: "Save Fund"))
      |> expect(active_tab() |> by_css() |> filter(has_text: html_text("Funds")) |> visible())
    end

    test "returns to fund list when specified on cancel", %{conn: conn, fund: fund} do
      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds/#{fund}/edit?return_to=index")
      |> click(by_role(:link, name: "Cancel"))
      |> expect(active_tab() |> by_css() |> filter(has_text: html_text("Funds")) |> visible())
    end

    test "returns to individual fund view when specified on save", %{conn: conn, fund: fund} do
      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds/#{fund}/edit?return_to=show")
      |> click(by_role(:button, name: "Save Fund"))
      |> expect(heading() |> by_css() |> filter(has_text: html_text(fund)) |> visible())
    end

    test "returns to individual fund view when specified on cancel", %{conn: conn, fund: fund} do
      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds/#{fund}/edit?return_to=show")
      |> click(by_role(:link, name: "Cancel"))
      |> expect(heading() |> by_css() |> filter(has_text: html_text(fund)) |> visible())
    end
  end
end
