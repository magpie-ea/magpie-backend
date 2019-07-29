# defmodule Magpie.LandingPageTest do
#   @moduledoc """
#   Feature tests on the landing page
#   """
#   use Magpie.FeatureCase, async: true

#   import Wallaby.Query

#   test "Has exactly two buttons", %{session: session} do
#     session
#     |> visit("/")
#     |> assert_has(css(".btn", count: 2))
#   end

#   test "Has btn-primary for experiments", %{session: session} do
#     session
#     |> visit("/")
#     |> assert_has(css(".btn-primary", text: "Manage Experiments"))
#   end

#   test "Has btn-success for custom records", %{session: session} do
#     session
#     |> visit("/")
#     |> assert_has(css(".btn-success", text: "Manage Custom Records"))
#   end

#   test "Clicking on the experiemnts button leads to the experiment management page", %{
#     session: session
#   } do
#     session
#     |> visit("/")
#     # In Bootstrap, `a` is used instead of `btn`. Thus it's a `link`.
#     |> click(link("Manage Experiments"))
#     |> assert_has(css(".page-title", text: "Manage Experiments"))
#   end

#   test "Clicking on the custom records button leads to the custom records management page", %{
#     session: session
#   } do
#     session
#     |> visit("/")
#     # In Bootstrap, `a` is used instead of `btn`. Thus it's a `link`.
#     |> click(link("Manage Custom Records"))
#     |> assert_has(css(".page-title", text: "Manage Custom Records"))
#   end
# end
