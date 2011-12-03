Sequel.migration do
  up do
    alter_table(:pushes) do
      rename_column(:exit_status, :exit)
    end
  end

  down do
    alter_table(:pushes) do
      rename_column(:exit, :exit_status)
    end
  end
end