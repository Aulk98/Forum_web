defmodule Forum.Discussion.Topic do
  use Ecto.Schema
  import Ecto.Changeset

  schema "topics" do
    field :title, :string
    field :description, :string
    belongs_to :user, Forum.Accounts.User
    has_many :comments, Forum.Discussion.Comment

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(topic, attrs) do
    topic
    |> cast(attrs, [:title, :description])
    |> validate_required([:title])
    |> set_default_description()
  end

  defp set_default_description(changeset) do
    title = get_field(changeset, :title)

    if is_nil(get_field(changeset, :description)) && title do
      put_change(changeset, :description, "Description for \"#{title}\"")
    else
      changeset
    end
  end
end
