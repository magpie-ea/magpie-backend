defmodule ProComPrag.Router do
  use ProComPrag.Web, :router

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

  scope "/", ProComPrag do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index

    get "/experiment", ExperimentController, :new
    post "/experiment", ExperimentController, :create

    get "/retrieve", ExperimentController, :query
    post "/retrieve", ExperimentController, :retrieve
  end

  scope "/api", ProComPrag do
    pipe_through :api

    post "/submit_experiment", ExperimentController, :create
  end
end
