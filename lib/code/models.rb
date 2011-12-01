require "sequel"
Sequel.connect(ENV["DATABASE_URL"] || raise("no DATABASE_URL set"))

module Code
  module Models
    class Push < Sequel::Model
    end
  end
end