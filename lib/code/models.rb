require "sequel"
require "./lib/code"

Sequel.connect(ENV["DATABASE_URL"] || raise("no DATABASE_URL set"))

module Code
  module Models
    class Push < Sequel::Model
      db.create_table? :pushes do
        primary_key :id

        Integer   :app_id
        String    :app_name
        String    :user_email

        String    :stack
        String    :flags
        String    :heroku_host

        String    :buildpack_url
        String    :framework      # output of `detect`
        String    :compile        # output of `compile`
        String    :release        # output of `release`
        String    :debug_log      # stderr or debug statements from slug-compiler, and detect/compile/release
        Integer   :exit_status    # $? of `compile`

        DateTime  :started_at
        DateTime  :finished_at
      end
    end
  end
end