defmodule FreedomAccountWeb.LoanLive.ActivationFormTest do
  use FreedomAccountWeb.ConnCase, async: true

  import Money.Sigil

  alias FreedomAccount.Factory

  describe "activating/deactivating loans" do
    setup [:create_account, :create_loans]

    test "activates/deactivates loans", %{conn: conn, loans: loans} do
      [can_deactivate, inactive, non_zero_balance, to_deactivate] = loans

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans/activate")
      |> expect(page_title_contains("Activate/Deactivate Loans"))
      |> expect(heading() |> by_css() |> filter(has_text: html_text("Activate/Deactivate Loans")) |> visible())
      |> expect("label" |> by_css() |> filter(has_text: html_text(can_deactivate)) |> visible())
      |> expect("label" |> by_css() |> filter(has_text: html_text(inactive)) |> visible())
      |> expect("label" |> by_css() |> filter(has_text: html_text(to_deactivate)) |> visible())
      |> expect("label" |> by_css() |> filter(has_text: html_text(non_zero_balance)) |> count(0))
      |> uncheck(exact_label(to_deactivate))
      |> check(exact_label(inactive))
      |> click(by_role(:button, name: "Update Loans"))
      |> expect(:info |> flash() |> by_css() |> filter(has_text: html_text("Loans updated successfully")) |> visible())
      |> expect(active_tab() |> by_css() |> filter(has_text: html_text("Loans")) |> visible())
      |> expect(visible(by_css(loan_card(can_deactivate))))
      |> expect(visible(by_css(loan_card(inactive))))
      |> expect(visible(by_css(loan_card(non_zero_balance))))
      |> expect(count(by_css(loan_card(to_deactivate)), 0))
    end

    test "does not activate/deactivate loans on cancel", %{conn: conn, loans: loans} do
      [can_deactivate, inactive, non_zero_balance, to_deactivate] = loans

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/loans/activate")
      |> expect(heading() |> by_css() |> filter(has_text: html_text("Activate/Deactivate Loans")) |> visible())
      |> uncheck(exact_label(to_deactivate))
      |> check(exact_label(inactive))
      |> click(by_role(:link, name: "Cancel"))
      |> expect(active_tab() |> by_css() |> filter(has_text: html_text("Loans")) |> visible())
      |> expect(visible(by_css(loan_card(can_deactivate))))
      |> expect(count(by_css(loan_card(inactive)), 0))
      |> expect(visible(by_css(loan_card(non_zero_balance))))
      |> expect(visible(by_css(loan_card(to_deactivate))))
    end
  end

  defp create_loans(%{account: account}) do
    loans = [
      Factory.loan(account, name: "Can Deactivate", current_balance: Money.zero(:usd)),
      Factory.inactive_loan(account, name: "Inactive", current_balance: Money.zero(:usd)),
      account |> Factory.loan(name: "Has Non-Zero Balance") |> Factory.with_loan_balance(~M[150]usd),
      Factory.loan(account, name: "To Deactivate", current_balance: Money.zero(:usd))
    ]

    %{loans: loans}
  end
end
