defmodule WoqWebapp.Router do
  use WoqWebapp.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", WoqWebapp do
    pipe_through :browser # Use the default browser stack

    # ... Should probably just make the default homepage the place to retrieve the results for now actually.
    get "/", ExperimentController, :query
    post "/", ExperimentController, :retrieve
  end

  scope "/api", WoqWebapp do
    pipe_through :api

    post "/submit_experiment", ExperimentController, :create
  end
end
