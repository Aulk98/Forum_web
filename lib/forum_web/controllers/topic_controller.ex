defmodule ForumWeb.TopicController do
  use ForumWeb, :controller
  alias Forum.Discussion
  alias Forum.Discussion.Topic

  plug :valid_user when action in [:new, :create, :delete]
  plug :check_topic_owner when action in [:delete]

  def index(conn, _params) do
    topics = Discussion.list_topics()
    render(conn, :index, topics: topics)
  end


  def new(conn, _params) do
    changeset = Discussion.change_topic(%Topic{})

    conn
    |> assign(:page_title, "Create New Topic")
    |> render(:new, changeset: changeset)
  end

  def create(conn, %{"topic" => topic_params}) do
    case Discussion.create_topic(topic_params) do
      {:ok, _topic} ->
        conn
        |> put_flash(:info, "Topic created successfully.")
        |> redirect(to: ~p"/")

      {:error, changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    topic = Discussion.get_topic!(id)
    Discussion.delete_topic(topic)

    conn
    |> put_flash(:info, "Topic: #{topic.title} successfully deleted.")
    |> redirect(to: ~p"/")
  end

  def check_topic_owner(conn, _params) do
    %{params: %{"id" => topic_id}} = conn

    if Discussion.get_topic!(topic_id).user_id == conn.assigns.current_user.id do
      conn
    else
      conn
      |> put_flash(:error, "You cannot edit that")
      |> redirect(to: ~p"/")
      |> halt()
    end
  end
end
