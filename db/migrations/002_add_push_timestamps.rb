Sequel.migration do
  up do
    alter_table(:pushes) do
      add_column :created_at, DateTime
      add_column :updated_at, DateTime
    end
  end

  down do
    alter_table(:pushes) do
      drop_column :created_at
      drop_column :updated_at
    end
  end
end