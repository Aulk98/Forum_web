defmodule ForumWeb.TopicLive.Show do
  use ForumWeb, :live_view

  alias Forum.Discussion.Comment
  alias Forum.Discussion

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    if connected?(socket), do: ForumWeb.Endpoint.subscribe("Topic-#{id}")

    topic = Discussion.get_topic_with_comments(id)

    socket =
      socket
      |> assign(:topic, topic)
      |> stream(:comments, topic.comments)

    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, _params) do
    socket
    |> assign(:page_title, "Show Topic")
  end

  defp apply_action(socket, :new_comment, _params) do
    socket
    |> assign(:page_title, "New Comment")
    |> assign(:comment, %Comment{})
  end

  defp apply_action(socket, action, params)
       when action in [:edit, :edit_comment] do
    current_user = socket.assigns.current_user
    topic = socket.assigns.topic
    comment = if params["comment_id"], do: Discussion.get_comment!(params["comment_id"])

    cond do
      action == :edit && current_user.id == topic.user_id ->
        socket
        |> assign(:page_title, "Edit Topic")

      action == :edit_comment && current_user.id == comment.user_id ->
        socket
        |> assign(:page_title, "Edit Comment")
        |> assign(:comment, comment)

      true ->
        socket
        |> put_flash(:error, "You are not authorized to perform this action.")
        |> push_navigate(to: ~p"/topics/#{params["id"]}")
    end
  end

  @impl true
  def handle_info(%{event: "edited_comment", payload: %{comment: comment}}, socket) do
    {:noreply, stream_insert(socket, :comments, Discussion.load_comment_user(comment), at: -1)}
  end

  def handle_info(%{event: "new_comment", payload: %{comment: comment}}, socket) do
    {:noreply, stream_insert(socket, :comments, comment)}
  end

  @impl true
  def handle_event("delete", %{"comment_id" => id}, socket) do
    comment = Discussion.get_comment!(id)
    {:ok, _} = Discussion.delete_comment(comment)

    {:noreply, stream_delete(socket, :comments, comment)}
  end
end
