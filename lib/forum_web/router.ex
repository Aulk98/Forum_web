defmodule ForumWeb.Router do
  use ForumWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ForumWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug ForumWeb.Plug.Auth
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ForumWeb do
    pipe_through :browser

    get "/", TopicController, :index
    resources "/topics", TopicController, except: [:index, :show, :edit]

    live_session :topics,
      on_mount: [{ForumWeb.Plug.Auth, :mount_current_user}] do
      live "/topics/:id", TopicLive.Show, :show
    end

    live_session :topic,
      on_mount: [{ForumWeb.Plug.Auth, :ensure_authenticated}] do
      live "/topics/:id/edit", TopicLive.Show, :edit
      live "/topics/:id/comments/new", TopicLive.Show, :new_comment
      live "/topics/:id/comments/:comment_id/edit", TopicLive.Show, :edit_comment
    end

    resources "/users", UserController, only: [:new, :create]
  end

  scope "/auth", ForumWeb do
    pipe_through :browser

    get "/login", AuthController, :new
    post "/login", AuthController, :create
    get "/logout", AuthController, :logout
    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
  end

  # Other scopes may use custom stacks.
  # scope "/api", ForumWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:forum, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ForumWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
