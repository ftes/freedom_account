defmodule FreedomAccountWeb.LoanLive.FormTest do
  @moduledoc false

  use FreedomAccountWeb.ConnCase, async: true

  alias FreedomAccount.Factory
  alias FreedomAccount.MoneyUtils

  setup [:create_account]

  describe "creating a new loan" do
    test "saves new loan", %{conn: conn} do
      %{icon: icon, name: name} = Factory.loan_attrs()

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans/new")
      |> expect(page_title_contains("Add Loan"))
      |> expect(heading() |> by_css() |> filter(has_text: html_text("Add Loan")) |> visible())
      |> fill(by_label("Icon", exact: true), to_string(""))
      |> fill(by_label("Name", exact: true), to_string(""))
      |> expect("#loan_icon" |> field_error() |> by_css() |> filter(has_text: html_text("can't be blank")) |> visible())
      |> expect("#loan_name" |> field_error() |> by_css() |> filter(has_text: html_text("can't be blank")) |> visible())
      |> fill(by_label("Icon", exact: true), to_string(icon))
      |> fill(by_label("Name", exact: true), to_string(name))
      |> click(by_role(:button, name: "Save Loan"))
      |> expect(:info |> flash() |> by_css() |> filter(has_text: html_text("Loan created successfully")) |> visible())
      |> expect(loan_icon() |> by_css() |> filter(has_text: html_text(icon)) |> visible())
      |> expect(loan_name() |> by_css() |> filter(has_text: html_text(name)) |> visible())
      |> expect(loan_balance() |> by_css() |> filter(has_text: html_text("$0.00")) |> visible())
    end

    test "does not create loan on cancel", %{conn: conn} do
      %{icon: icon, name: name} = Factory.loan_attrs()

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans/new")
      |> fill(by_label("Icon", exact: true), to_string(icon))
      |> fill(by_label("Name", exact: true), to_string(name))
      |> click(by_role(:link, name: "Cancel"))
      |> expect(loan_name() |> by_css() |> filter(has_text: html_text(name)) |> count(0))
    end
  end

  describe "editing a loan" do
    test "updates loan settings", %{account: account, conn: conn} do
      loan = account |> Factory.loan() |> Factory.with_loan_balance()
      %{icon: icon, name: name} = Factory.loan_attrs()

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans/#{loan}/edit")
      |> expect(page_title_contains("Edit Loan"))
      |> expect(heading() |> by_css() |> filter(has_text: html_text("Edit Loan")) |> visible())
      |> fill(by_label("Icon", exact: true), to_string(""))
      |> fill(by_label("Name", exact: true), to_string(""))
      |> expect("#loan_icon" |> field_error() |> by_css() |> filter(has_text: html_text("can't be blank")) |> visible())
      |> expect("#loan_name" |> field_error() |> by_css() |> filter(has_text: html_text("can't be blank")) |> visible())
      |> fill(by_label("Icon", exact: true), to_string(icon))
      |> fill(by_label("Name", exact: true), to_string(name))
      |> click(by_role(:button, name: "Save Loan"))
      |> expect(:info |> flash() |> by_css() |> filter(has_text: html_text("Loan updated successfully")) |> visible())
      |> expect(loan |> loan_icon() |> by_css() |> filter(has_text: html_text(icon)) |> visible())
      |> expect(loan |> loan_name() |> by_css() |> filter(has_text: html_text(name)) |> visible())
      |> expect(
        loan
        |> loan_balance()
        |> by_css()
        |> filter(has_text: html_text(MoneyUtils.format(loan.current_balance)))
        |> visible()
      )
    end

    test "does not update loan settings on cancel", %{account: account, conn: conn} do
      loan = account |> Factory.loan() |> Factory.with_loan_balance()
      %{icon: icon, name: name} = Factory.loan_attrs()

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans/#{loan}/edit")
      |> fill(by_label("Icon", exact: true), to_string(icon))
      |> fill(by_label("Name", exact: true), to_string(name))
      |> click(by_role(:link, name: "Cancel"))
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
  end

  describe "returning to calling view" do
    setup :create_loan

    test "returns to loan list by default on save", %{conn: conn, loan: loan} do
      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans/#{loan}/edit")
      |> click(by_role(:button, name: "Save Loan"))
      |> expect(active_tab() |> by_css() |> filter(has_text: html_text("Loans")) |> visible())
    end

    test "returns to loan list by default on cancel", %{conn: conn, loan: loan} do
      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans/#{loan}/edit")
      |> click(by_role(:link, name: "Cancel"))
      |> expect(active_tab() |> by_css() |> filter(has_text: html_text("Loans")) |> visible())
    end

    test "returns to loan list when specified on save", %{conn: conn, loan: loan} do
      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans/#{loan}/edit?return_to=index")
      |> click(by_role(:button, name: "Save Loan"))
      |> expect(active_tab() |> by_css() |> filter(has_text: html_text("Loans")) |> visible())
    end

    test "returns to loan list when specified on cancel", %{conn: conn, loan: loan} do
      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans/#{loan}/edit?return_to=index")
      |> click(by_role(:link, name: "Cancel"))
      |> expect(active_tab() |> by_css() |> filter(has_text: html_text("Loans")) |> visible())
    end

    test "returns to individual loan view when specified on save", %{conn: conn, loan: loan} do
      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans/#{loan}/edit?return_to=show")
      |> click(by_role(:button, name: "Save Loan"))
      |> expect(heading() |> by_css() |> filter(has_text: html_text(loan)) |> visible())
    end

    test "returns to individual loan view when specified on cancel", %{conn: conn, loan: loan} do
      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans/#{loan}/edit?return_to=show")
      |> click(by_role(:link, name: "Cancel"))
      |> expect(heading() |> by_css() |> filter(has_text: html_text(loan)) |> visible())
    end
  end
end
