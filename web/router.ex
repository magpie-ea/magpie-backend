defmodule BABE.Router do
  use BABE.Web, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", BABE do
    # Use the default browser stack
    pipe_through(:browser)

    get("/", PageController, :index)

    # No need for :show as this is currently already covered by :edit
    resources("/experiments", ExperimentController, except: [:show])

    # A special endpoint only for activating/deactivating an experiment
    get("/experiments/:id/toggle", ExperimentController, :toggle)

    get("/experiments/:id/retrieve", ExperimentController, :retrieve_as_csv)

    # get "/custom_records", CustomRecordController, :index
    resources("/custom_records", CustomRecordController, except: [:show])
  end

  scope "/api", BABE do
    pipe_through(:api)

    post("/submit_experiment/:id/", ExperimentController, :submit)
    get("/retrieve_experiment/:id/", ExperimentController, :retrieve_as_json)
  end
end
