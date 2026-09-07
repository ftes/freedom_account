defmodule FreedomAccountWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use FreedomAccountWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  alias Phoenix.ConnTest
  alias Phoenix.HTML.Safe

  using opts do
    quote do
      use FreedomAccount.DataCase, unquote(opts)
      use FreedomAccountWeb, :verified_routes

      import Cerberus
      import Cerberus.Expect, except: [disabled: 1, enabled: 1, url: 1]
      import Cerberus.Locator
      import FreedomAccountWeb.ElementSelectors
      import Phoenix.ConnTest
      import Plug.Conn
      import unquote(__MODULE__)

      alias Cerberus.Expect
      alias Cerberus.Page

      @endpoint FreedomAccountWeb.Endpoint
      @moduletag :cerberus
    end
  end

  setup _context do
    {:ok, conn: ConnTest.build_conn()}
  end

  @spec html_text(Safe.t()) :: String.t()
  def html_text(value) when is_binary(value), do: value

  def html_text(value) do
    value
    |> Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  @spec exact_label(Safe.t()) :: Cerberus.Locator.t()
  def exact_label(value) do
    value
    |> html_text()
    |> Cerberus.Locator.by_label(exact: true)
  end

  @spec page_title_contains(Safe.t()) :: Cerberus.Expect.t()
  def page_title_contains(value) do
    value
    |> html_text()
    |> Regex.escape()
    |> Regex.compile!()
    |> Cerberus.Page.to_have_title()
  end
end
