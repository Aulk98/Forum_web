defmodule Forum.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Forum.Repo
  alias Forum.Accounts.User

  def list_users do
    Repo.all(User)
  end

  def get_user!(id), do: Repo.get!(User, id)

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  def findOrCreateUser(user_data) do
    changeset = User.oauth_changeset(%User{}, user_data)

    case Repo.get_by(User, email: changeset.changes.email) do
      nil ->
        Repo.insert(changeset)

      user ->
        oauth_user?(user, changeset)
    end
  end

  defp oauth_user?(user, changeset) do
    case user.provider do
      "email" ->
        Repo.update(changeset)

      _ ->
        {:ok, user}
    end
  end

  def authenticate(email, password) do
    user = Repo.get_by(User, email: String.downcase(email))

    cond do
      user && Argon2.verify_pass(password, user.password_hash) ->
        {:ok, user}

      user ->
        {:error, :bad_password}

      true ->
        {:error, :bad_email}
    end
  end
end
