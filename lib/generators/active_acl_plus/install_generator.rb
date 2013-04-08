module ActiveAclPlus
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("../../templates", __FILE__)

      desc "Creates a ActiveAclPlus initializer."

      def copy_initializer
        template "active_acl_plus.rb", "config/initializers/active_acl_plus.rb"
      end

    end
  end
end
