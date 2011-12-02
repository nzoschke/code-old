require "sequel"
Sequel.connect(ENV["DATABASE_URL"] || raise("no DATABASE_URL set"))

module Code
  module Models
    class Push < Sequel::Model
      plugin :json_serializer
      plugin :timestamps

      set_dataset order(:created_at)
    end
  end
end