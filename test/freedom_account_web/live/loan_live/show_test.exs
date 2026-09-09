defmodule FreedomAccountWeb.LoanLive.ShowTest do
  @moduledoc false

  use FreedomAccountWeb.ConnCase, async: true

  describe "viewing an individual loan" do
    setup [:create_account, :create_loan]

    test "drills down to individual loan and back", %{conn: conn, loan: loan} do
      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans")
      |> click(loan |> loan_card() |> by_css() |> filter(has_text: html_text(loan.name)))
      |> assert(page_title_contains(loan))
      |> assert(heading() |> by_css() |> filter(has_text: html_text(loan)) |> visible())
      |> assert(heading() |> by_css() |> filter(has_text: html_text("$0.00")) |> visible())
      |> click(by_role(:link, name: "Back to Loans"))
      |> assert(page_title_contains("Loans"))
      |> assert(active_tab() |> by_css() |> filter(has_text: html_text("Loans")) |> visible())
    end

    test "displays loan", %{conn: conn, loan: loan} do
      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans/#{loan}")
      |> assert(heading() |> by_css() |> filter(has_text: html_text(loan)) |> visible())
    end

    test "allows editing loan", %{conn: conn, loan: loan} do
      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans/#{loan}")
      |> click(by_role(:link, name: "Edit Details"))
      |> assert(page_url(~r{/loans/#{loan.id}/edit(?:\?.*)?$}))
      |> click(by_role(:link, name: "Cancel"))
      |> assert(heading() |> by_css() |> filter(has_text: html_text(loan)) |> visible())
    end

    test "allows lending money from a loan", %{conn: conn, loan: loan} do
      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans/#{loan}")
      |> click(by_role(:link, name: "Lend"))
      |> assert(page_url(~p"/loans/#{loan}/loans/new"))
      |> click(by_role(:link, name: "Cancel"))
      |> assert(heading() |> by_css() |> filter(has_text: html_text(loan)) |> visible())
    end

    test "allows receiving payment on a loan", %{conn: conn, loan: loan} do
      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans/#{loan}")
      |> click(by_role(:link, name: "Payment"))
      |> assert(page_url(~p"/loans/#{loan}/payments/new"))
      |> click(by_role(:link, name: "Cancel"))
      |> assert(heading() |> by_css() |> filter(has_text: html_text(loan)) |> visible())
    end
  end
end
