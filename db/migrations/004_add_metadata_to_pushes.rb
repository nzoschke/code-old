Sequel.migration do
  up do
    alter_table(:pushes) do
      add_column(:metadata, String)
    end
  end

  down do
    alter_table(:pushes) do
      remove_column(:metadata, String)
    end
  end
end