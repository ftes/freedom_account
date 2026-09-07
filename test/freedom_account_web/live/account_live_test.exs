defmodule FreedomAccountWeb.AccountLiveTest do
  use FreedomAccountWeb.ConnCase, async: true

  alias FreedomAccount.Factory

  describe "updating account settings" do
    setup :create_account

    test "updates account settings", %{conn: conn} do
      %{deposits_per_year: deposits, name: name} = Factory.account_attrs()

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/account/edit")
      |> expect(page_title_contains("Edit Account Settings"))
      |> expect(heading() |> by_css() |> filter(has_text: html_text("Edit Account Settings")) |> visible())
      |> fill(by_label("Name", exact: true), to_string(""))
      |> fill(by_label("Deposits / year", exact: true), to_string(""))
      |> expect(
        "#account_name"
        |> field_error()
        |> by_css()
        |> filter(has_text: html_text("can't be blank"))
        |> visible()
      )
      |> expect(
        "#account_deposits_per_year"
        |> field_error()
        |> by_css()
        |> filter(has_text: html_text("can't be blank"))
        |> visible()
      )
      |> fill(by_label("Name", exact: true), to_string(name))
      |> fill(by_label("Deposits / year", exact: true), to_string(deposits))
      |> click(by_role(:button, name: "Save Account"))
      |> expect(:info |> flash() |> by_css() |> filter(has_text: html_text("Account updated successfully")) |> visible())
      |> expect(heading() |> by_css() |> filter(has_text: html_text(name)) |> visible())
    end

    test "selects default fund", %{account: account, conn: conn} do
      funds = for _i <- 1..5, do: Factory.fund(account)
      default_fund = Enum.random(funds)
      default_fund_label = html_text(default_fund)

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/account/edit")
      |> select_option(by_css("#default-fund"), %{label: default_fund_label})
      |> click(by_role(:button, name: "Save Account"))
      |> expect(:info |> flash() |> by_css() |> filter(has_text: html_text("Account updated successfully")) |> visible())
      |> visit(~p"/account/edit")
      |> expect(
        "#default-fund"
        |> selected_option()
        |> by_css()
        |> filter(has_text: html_text(default_fund))
        |> visible()
      )
    end

    test "does not update account settings on cancel", %{account: account, conn: conn} do
      %{deposits_per_year: deposits, name: name} = Factory.account_attrs()

      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/account/edit")
      |> fill(by_label("Name", exact: true), to_string(name))
      |> fill(by_label("Deposits / year", exact: true), to_string(deposits))
      |> click(by_role(:link, name: "Cancel"))
      |> expect(heading() |> by_css() |> filter(has_text: html_text(account.name)) |> visible())
    end

    test "returns to fund list by default on save", %{conn: conn} do
      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/account/edit")
      |> click(by_role(:button, name: "Save Account"))
      |> expect(active_tab() |> by_css() |> filter(has_text: html_text("Funds")) |> visible())
    end

    test "returns to fund list by default on cancel", %{conn: conn} do
      :phoenix
      |> start_session(conn: conn)
      |> visit(~p"/account/edit")
      |> click(by_role(:link, name: "Cancel"))
      |> expect(active_tab() |> by_css() |> filter(has_text: html_text("Funds")) |> visible())
    end

    for {return_to, tab_title} <- [
          {"funds", "Funds"},
          {"loans", "Loans"},
          {"transactions", "Transactions"}
        ] do
      test "returns to #{return_to} list when specified on save", %{conn: conn} do
        return_to = unquote(return_to)
        tab_title = unquote(tab_title)

        params = %{return_to: return_to}

        :phoenix
        |> start_session(conn: conn)
        |> visit(~p"/account/edit?#{params}")
        |> click(by_role(:button, name: "Save Account"))
        |> expect(active_tab() |> by_css() |> filter(has_text: html_text(tab_title)) |> visible())
      end

      test "returns to #{return_to} list when specified on cancel", %{conn: conn} do
        return_to = unquote(return_to)
        tab_title = unquote(tab_title)

        params = %{return_to: return_to}

        :phoenix
        |> start_session(conn: conn)
        |> visit(~p"/account/edit?#{params}")
        |> click(by_role(:link, name: "Cancel"))
        |> expect(active_tab() |> by_css() |> filter(has_text: html_text(tab_title)) |> visible())
      end
    end
  end
end
