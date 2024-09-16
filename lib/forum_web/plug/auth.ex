defmodule ForumWeb.Plug.Auth do
  import Plug.Conn
  import Phoenix.Controller

  alias ForumWeb.Router.Helpers, as: Routes
  alias Forum.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    user_id = get_session(conn, :user_id)

    cond do
      user = user_id && Accounts.get_user!(user_id) ->
        assign(conn, :current_user, user)

      true ->
        assign(conn, :current_user, nil)
    end
  end

  def valid_user(conn, _opts) do
    cond do
      conn.assigns.current_user ->
        conn

      true ->
        conn
        |> put_flash(:error, "You must be logged in to access that page")
        |> redirect(to: Routes.auth_path(conn, :new))
        |> halt()
    end
  end

  def on_mount(:mount_current_user, _params, session, socket) do
    {:cont, mount_current_user(socket, session)}
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You must log in to access this page.")
        |> Phoenix.LiveView.redirect(to: Routes.auth_path(socket, :new))

      {:halt, socket}
    end
  end

  defp mount_current_user(socket, session) do
    Phoenix.Component.assign_new(socket, :current_user, fn ->
      if user_id = session["user_id"], do: Accounts.get_user!(user_id) end)
  end
end
