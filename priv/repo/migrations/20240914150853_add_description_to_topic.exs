defmodule Forum.Repo.Migrations.AddDescriptionToTopic do
  use Ecto.Migration

  def change do
    alter table(:topics) do
      add :description, :string
    end
  end
end
