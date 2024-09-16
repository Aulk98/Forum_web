defmodule Forum.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :token, :string, default: nil
    field :username, :string
    field :provider, :string, default: "email"
    field :email, :string
    field :password_hash, :string
    field :admin, :boolean, default: false
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true

    has_many :topics, Forum.Discussion.Topic
    has_many :comments, Forum.Discussion.Comment

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :email, :password])
    |> validate_required([:username, :email, :password])
    |> validate_format(:email, ~r/@/)
    |> validate_length(:password, min: 6)
    |> validate_confirmation(:password)
    |> downcase_email()
    |> unique_constraint(:email)
    |> put_password_hash()
  end

  def oauth_changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :email, :token, :provider])
    |> validate_required([:username, :email, :token, :provider])
    |> downcase_email()
    |> unique_constraint(:email)
  end

  defp put_password_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        put_change(changeset, :password_hash, Argon2.hash_pwd_salt(password))

      _ ->
        changeset
    end
  end

  defp downcase_email(changeset) do
    case get_field(changeset, :email) do
      nil -> changeset
      email -> put_change(changeset, :email, String.downcase(email))
    end
  end
end
