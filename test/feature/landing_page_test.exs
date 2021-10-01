defmodule Magpie.LandingPageTest do
  @moduledoc """
  Feature tests on the landing page
  """
  use Magpie.FeatureCase, async: true

  import Wallaby.Query

  test "Has exactly two buttons", %{session: session} do
    session
    |> visit("/")
    |> assert_has(css(".button", count: 2))
  end

  test "Has button-outline for custom records", %{session: session} do
    session
    |> visit("/")
    |> assert_has(css(".button-outline", value: "Manage Custom Records"))
  end

  test "Clicking on the experiments button leads to the experiment management page", %{
    session: session
  } do
    session
    |> visit("/")
    # In Bootstrap, `a` is used instead of `btn`. Thus it's a `link`.
    |> click(link("Manage Experiments"))
    |> assert_has(css(".page-title", text: "Manage Experiments"))
  end

  test "Clicking on the custom records button leads to the custom records management page", %{
    session: session
  } do
    session
    |> visit("/")
    # In Bootstrap, `a` is used instead of `btn`. Thus it's a `link`.
    |> click(link("Manage Custom Records"))
    |> assert_has(css(".page-title", text: "Manage Custom Records"))
  end
end
