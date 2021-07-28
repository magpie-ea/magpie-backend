defmodule Magpie.Repo.Migrations.RenameIsComplexToIsDynamic do
  use Ecto.Migration

  def change do
    rename table(:experiments), :is_complex, to: :is_dynamic
  end
end
