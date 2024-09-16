defmodule Forum.Discussion do
  @moduledoc """
  The Discussion context.
  """

  import Ecto.Query, warn: false
  alias Forum.Repo

  alias Forum.Discussion.{Topic, Comment}

  def list_topics do
    Repo.all(Topic)
  end

  def get_topic!(id), do: Repo.get!(Topic, id)

  def create_topic(attrs \\ %{}) do
    %Topic{}
    |> Topic.changeset(attrs)
    |> Repo.insert()
  end

  def update_topic(%Topic{} = topic, attrs) do
    topic
    |> Topic.changeset(attrs)
    |> Repo.update()
  end

  def delete_topic(%Topic{} = topic) do
    Repo.transaction(fn ->
      Repo.delete_all Ecto.assoc(topic, :comments)

      Repo.delete(topic)
    end)
  end

  def change_topic(%Topic{} = topic, attrs \\ %{}) do
    Topic.changeset(topic, attrs)
  end

  def get_topic_with_comments(id) do
    Repo.one(
      from(t in Topic,
        where: t.id == ^id,
        left_join: c in assoc(t, :comments),
        left_join: u in assoc(c, :user),
        order_by: [asc: c.inserted_at],
        preload: [comments: {c, user: u}]
      )
    )
  end

  def list_comments do
    Repo.all(Comment)
  end

  def get_comment!(id), do: Repo.get!(Comment, id)

  def create_comment(user, topic, attrs \\ %{}) do
    %Comment{}
    |> Comment.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Ecto.Changeset.put_assoc(:topic, topic)
    |> Repo.insert()
  end

  def update_comment(%Comment{} = comment, attrs) do
    comment
    |> Comment.changeset(attrs)
    |> Repo.update()
  end

  def delete_comment(%Comment{} = comment) do
    Repo.delete(comment)
  end

  def change_comment(%Comment{} = comment, attrs \\ %{}) do
    Comment.changeset(comment, attrs)
  end

  def load_comment_user(comment) do
    Repo.preload(comment, :user)
  end
end
