require 'rails/generators/active_record'

module ActiveAclPlus
  module Generators
    class MigrationsGenerator < Rails::Generators::Base

      include Rails::Generators::Migration
      extend ActiveRecord::Generators::Migration

      source_root File.expand_path("../../templates", __FILE__)

      def copy_devise_migration
        migration_template "migration_template.rb", "db/migrate/active_acl_plus_tables"
      end

      # Set the current directory as base for the inherited generators.
      def self.base_root
        File.dirname(__FILE__)
      end

      # Implement the required interface for Rails::Generators::Migration.
      def self.next_migration_number(dirname) #:nodoc:
        next_migration_number = current_migration_number(dirname) + 1
        ActiveRecord::Migration.next_migration_number(next_migration_number)
      end

    end
  end
end
