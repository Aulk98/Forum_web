defmodule ForumWeb.AuthController do
  use ForumWeb, :controller
  alias Forum.Accounts
  plug Ueberauth

  def new(conn, _params), do: render(conn, :new)

  def create(conn, %{"email" => email, "password" => password}) do
    case Accounts.authenticate(email, password) do
      {:ok, user} ->
        login(conn, user)

      {:error, reason} ->
        handle_login_error(conn, reason)
    end
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, %{"provider" => provider}) do
    user_data = %{username: auth.info.nickname, token: auth.credentials.token, email: auth.info.email, provider: provider}

    case Accounts.findOrCreateUser(user_data) do
      {:ok, user} ->
        login(conn, user)

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Something went wrong")
        |> redirect(to: "/")
    end
  end

  defp login(conn, user) do
    conn
    |> assign(:current_user, user)
    |> put_session(:user_id, user.id)
    |> put_flash(:info, "Welcome #{user.username}!")
    |> redirect(to: Helpers.topic_path(conn, :index))
  end

  defp handle_login_error(conn, reason) do
    case reason do
      :bad_email ->
        conn
        |> put_flash(:error, "Unknown Email Address!")
        |> render(:new)

      :bad_password ->
        conn
        |> put_flash(:error, "Invalid Password!")
        |> render(:new)
    end
  end

  def logout(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: Helpers.topic_path(conn, :index))
  end
end
