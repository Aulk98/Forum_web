defmodule ForumWeb.TopicLive.CommentComponent do
  use ForumWeb, :live_component

  alias Forum.Discussion

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage comment records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="comment-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:content]} type="textarea" label="Content" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Comment</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{comment: comment} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Discussion.change_comment(comment))
     end)}
  end

  @impl true
  def handle_event("validate", %{"comment" => comment_params}, socket) do
    changeset = Discussion.change_comment(socket.assigns.comment, comment_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"comment" => comment_params}, socket) do
    save_comment(socket, socket.assigns.action, comment_params)
  end

  defp save_comment(socket, :edit_comment, comment_params) do
    case Discussion.update_comment(socket.assigns.comment, comment_params) do
      {:ok, comment} ->
        ForumWeb.Endpoint.broadcast("Topic-#{comment.topic_id}", "edited_comment", %{
          comment: comment
        })

        {:noreply,
         socket
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_comment(socket, :new_comment, comment_params) do
    case Discussion.create_comment(socket.assigns.user, socket.assigns.topic, comment_params) do
      {:ok, comment} ->
        ForumWeb.Endpoint.broadcast("Topic-#{comment.topic_id}", "new_comment", %{
          comment: comment
        })

        {:noreply,
         socket
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  # defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
