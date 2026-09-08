defmodule FreedomAccountWeb.LoanLive.IndexTest do
  @moduledoc false

  use FreedomAccountWeb.ConnCase, async: true

  alias FreedomAccount.Factory
  alias FreedomAccount.Loans
  alias FreedomAccount.MoneyUtils

  describe "listing all loans" do
    setup [:create_account]

    test "lists all loans", %{account: account, conn: conn} do
      loan = Factory.loan(account)
      Factory.lend(loan)
      {:ok, loan} = Loans.with_updated_balance(loan)

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans")
      |> expect(page_title_contains("Loans"))
      |> expect(active_tab() |> by_css() |> filter(has_text: html_text("Loans")) |> visible())
      |> expect(loan |> loan_icon() |> by_css() |> filter(has_text: html_text(loan.icon)) |> visible())
      |> expect(loan |> loan_name() |> by_css() |> filter(has_text: html_text(loan.name)) |> visible())
      |> expect(
        loan
        |> loan_balance()
        |> by_css()
        |> filter(has_text: html_text(MoneyUtils.format(loan.current_balance)))
        |> visible()
      )
    end

    test "shows prompt when list is empty", %{conn: conn} do
      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans")
      |> expect(active_tab() |> by_css() |> filter(has_text: html_text("Loans")) |> visible())
      |> expect(
        "#no-loans"
        |> by_css()
        |> filter(has_text: html_text("This account has no active loans. Use the Add Loan button to add one."))
        |> visible()
      )
    end

    test "shows total loans balance", %{account: account, conn: conn} do
      loan = account |> Factory.loan() |> Factory.with_loan_balance()
      _fund = account |> Factory.fund() |> Factory.with_fund_balance()

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans")
      |> expect(
        active_tab()
        |> by_css()
        |> filter(has_text: html_text(MoneyUtils.format(loan.current_balance)))
        |> visible()
      )
    end

    test "allows creating a new loan from the listing", %{conn: conn} do
      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans")
      |> click(by_role(:link, name: "Add Loan"))
      |> expect(Cerberus.Page.to_have_url(~p"/loans/new"))
      |> click(by_role(:link, name: "Cancel"))
      |> expect(active_tab() |> by_css() |> filter(has_text: html_text("Loans")) |> visible())
    end

    test "allows editing a loan in listing", %{account: account, conn: conn} do
      loan = account |> Factory.loan() |> Factory.with_loan_balance()

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans")
      |> click("#loans-#{loan.id}" |> action_link() |> by_css() |> filter(has_text: html_text("Edit")))
      |> expect(Cerberus.Page.to_have_url(~p"/loans/#{loan}/edit"))
      |> click(by_role(:link, name: "Cancel"))
      |> expect(active_tab() |> by_css() |> filter(has_text: html_text("Loans")) |> visible())
    end

    test "deletes loan in listing", %{account: account, conn: conn} do
      loan = Factory.loan(account)

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans")
      |> click("#loans-#{loan.id}" |> action_link() |> by_css() |> filter(has_text: html_text("Delete")))
      |> expect(count(by_css("#loans-#{loan.id}"), 0))
    end

    test "allows activating/deactivating loans from listing", %{account: account, conn: conn} do
      _loan = Factory.loan(account)

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans")
      |> click(by_role(:link, name: "Activate/Deactivate"))
      |> expect(Cerberus.Page.to_have_url(~p"/loans/activate"))
      |> click(by_role(:link, name: "Cancel"))
      |> expect(active_tab() |> by_css() |> filter(has_text: html_text("Loans")) |> visible())
    end
  end
end
