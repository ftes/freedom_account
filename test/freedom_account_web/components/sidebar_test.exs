defmodule FreedomAccountWeb.SidebarTest do
  use FreedomAccountWeb.ConnCase, async: true

  alias FreedomAccount.Factory
  alias FreedomAccount.MoneyUtils

  defp create_funds(%{account: account}) do
    funds =
      for _i <- 1..3 do
        account |> Factory.fund() |> Factory.with_fund_balance()
      end

    %{funds: Enum.sort_by(funds, & &1.name)}
  end

  defp create_loans(%{account: account}) do
    loans =
      for _i <- 1..3 do
        account |> Factory.loan() |> Factory.with_loan_balance()
      end

    %{loans: Enum.sort_by(loans, & &1.name)}
  end

  describe "sidebar component" do
    setup [:create_account, :create_funds, :create_loans]

    test "displays both funds and loans on fund show page", %{conn: conn, funds: funds} do
      fund = hd(funds)

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds/#{fund}")
      |> expect(heading() |> by_css() |> filter(has_text: html_text("Funds")) |> visible())
      |> expect(heading() |> by_css() |> filter(has_text: html_text("Loans")) |> visible())
    end

    test "displays both funds and loans on loan show page", %{conn: conn, loans: loans} do
      loan = hd(loans)

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans/#{loan}")
      |> expect(heading() |> by_css() |> filter(has_text: html_text("Funds")) |> visible())
      |> expect(heading() |> by_css() |> filter(has_text: html_text("Loans")) |> visible())
    end

    test "displays simple list of funds", %{conn: conn, funds: funds} do
      [fund1, fund2, fund3] = funds

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds/#{fund1}")
      |> expect(heading() |> by_css() |> filter(has_text: html_text("Funds")) |> visible())
      |> expect(link() |> by_css() |> filter(has_text: html_text(fund1)) |> visible())
      |> expect(link() |> by_css() |> filter(has_text: html_text(fund2)) |> visible())
      |> expect(link() |> by_css() |> filter(has_text: html_text(fund3)) |> visible())
    end

    test "navigates to other funds", %{conn: conn, funds: funds} do
      [fund1, fund2, _rest] = funds

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds/#{fund1}")
      |> click(by_role(:link, name: fund2.name))
      |> expect(heading() |> by_css() |> filter(has_text: html_text(fund2)) |> visible())
    end

    test "returns to fund list when header clicked", %{conn: conn, funds: funds} do
      fund = hd(funds)

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds/#{fund}")
      |> click(heading_link() |> by_css() |> filter(has_text: html_text("Funds")))
      |> expect(Fluffy.Page.to_have_url(~p"/funds"))
    end

    test "displays simple list of loans", %{conn: conn, loans: loans} do
      [loan1, loan2, loan3] = loans

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans/#{loan1}")
      |> expect(heading() |> by_css() |> filter(has_text: html_text("Loans")) |> visible())
      |> expect(link() |> by_css() |> filter(has_text: html_text(loan1)) |> visible())
      |> expect(link() |> by_css() |> filter(has_text: html_text(loan2)) |> visible())
      |> expect(link() |> by_css() |> filter(has_text: html_text(loan3)) |> visible())
    end

    test "navigates to other loans", %{conn: conn, loans: loans} do
      [loan1, loan2, _rest] = loans

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans/#{loan1}")
      |> click(by_role(:link, name: loan2.name))
      |> expect(heading() |> by_css() |> filter(has_text: html_text(loan2)) |> visible())
    end

    test "returns to loan list when header clicked", %{conn: conn, loans: loans} do
      loan = hd(loans)

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans/#{loan}")
      |> click(heading_link() |> by_css() |> filter(has_text: html_text("Loans")))
      |> expect(Fluffy.Page.to_have_url(~p"/loans"))
    end

    test "displays balances in headers", %{conn: conn, funds: funds, loans: loans} do
      funds_balance = funds |> Enum.map(& &1.current_balance) |> MoneyUtils.sum()
      loans_balance = loans |> Enum.map(& &1.current_balance) |> MoneyUtils.sum()

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds/#{hd(funds)}")
      |> expect(heading() |> by_css() |> filter(has_text: html_text(MoneyUtils.format(funds_balance))) |> visible())
      |> expect(heading() |> by_css() |> filter(has_text: html_text(MoneyUtils.format(loans_balance))) |> visible())
    end
  end
end
