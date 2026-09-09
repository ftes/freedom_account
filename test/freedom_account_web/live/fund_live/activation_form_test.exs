defmodule FreedomAccountWeb.FundLive.ActivationFormTest do
  use FreedomAccountWeb.ConnCase, async: true

  import Money.Sigil

  alias FreedomAccount.Factory

  describe "activating/deactivating funds" do
    setup [:create_account, :create_funds]

    test "activates/deactivates funds", %{conn: conn, funds: funds} do
      [can_deactivate, inactive, non_zero_balance, to_deactivate] = funds

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds/activate")
      |> assert(page_title_contains("Activate/Deactivate Funds"))
      |> assert(heading() |> by_css() |> filter(has_text: html_text("Activate/Deactivate Funds")) |> visible())
      |> assert("label" |> by_css() |> filter(has_text: html_text(can_deactivate)) |> visible())
      |> assert("label" |> by_css() |> filter(has_text: html_text(inactive)) |> visible())
      |> assert("label" |> by_css() |> filter(has_text: html_text(to_deactivate)) |> visible())
      |> assert("label" |> by_css() |> filter(has_text: html_text(non_zero_balance)) |> count(0))
      |> uncheck(exact_label(to_deactivate))
      |> check(exact_label(inactive))
      |> click(by_role(:button, name: "Update Funds"))
      |> assert(:info |> flash() |> by_css() |> filter(has_text: html_text("Funds updated successfully")) |> visible())
      |> assert(active_tab() |> by_css() |> filter(has_text: html_text("Funds")) |> visible())
      |> assert(visible(by_css(fund_card(can_deactivate))))
      |> assert(visible(by_css(fund_card(inactive))))
      |> assert(visible(by_css(fund_card(non_zero_balance))))
      |> assert(count(by_css(fund_card(to_deactivate)), 0))
    end

    test "does not activate/deactivate funds on cancel", %{conn: conn, funds: funds} do
      [can_deactivate, inactive, non_zero_balance, to_deactivate] = funds

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/funds/activate")
      |> assert(heading() |> by_css() |> filter(has_text: html_text("Activate/Deactivate Funds")) |> visible())
      |> uncheck(exact_label(to_deactivate))
      |> check(exact_label(inactive))
      |> click(by_role(:link, name: "Cancel"))
      |> assert(active_tab() |> by_css() |> filter(has_text: html_text("Funds")) |> visible())
      |> assert(visible(by_css(fund_card(can_deactivate))))
      |> assert(count(by_css(fund_card(inactive)), 0))
      |> assert(visible(by_css(fund_card(non_zero_balance))))
      |> assert(visible(by_css(fund_card(to_deactivate))))
    end
  end

  defp create_funds(%{account: account}) do
    funds = [
      Factory.fund(account, name: "Can Deactivate", current_balance: Money.zero(:usd)),
      Factory.inactive_fund(account, name: "Inactive", current_balance: Money.zero(:usd)),
      account |> Factory.fund(name: "Has Non-Zero Balance") |> Factory.with_fund_balance(~M[150]usd),
      Factory.fund(account, name: "To Deactivate", current_balance: Money.zero(:usd))
    ]

    %{funds: funds}
  end
end
