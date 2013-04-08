require 'has_many_polymorphs'

require 'active_acl_plus/base'

require 'active_acl_plus/load_controller_actions'
require 'active_acl_plus/load_files_from'
require 'active_acl_plus/privilege_const_set'

require 'active_acl_plus/acts/access_group/acts_as_access_group'
require 'active_acl_plus/acts/access_group/nested_set'

require 'active_acl_plus/acts/access_object/acts_as_access_object'
require 'active_acl_plus/acts/access_object/object_handler'

require 'active_acl_plus/acts/grant/grant'

module ActiveAclPlus


  mattr_accessor :acl_sections_table
  @@acl_sections_table = 'acl_sections'
  mattr_accessor :acls_privileges_table
  @@acls_privileges_table = 'acls_privileges'
  mattr_accessor :acls_table
  @@acls_table = 'acls'
  mattr_accessor :privileges_table
  @@privileges_table = 'privileges'
  mattr_accessor :requester_links_table
  @@requester_links_table = 'requester_links'
  mattr_accessor :target_links_table
  @@target_links_table = 'target_links'
  mattr_accessor :requester_group_links_table
  @@requester_group_links_table = 'requester_group_links'
  mattr_accessor :target_group_links_table
  @@target_group_links_table = 'target_group_links'
  mattr_accessor :controller_actions_table
  @@controller_actions_table = 'controller_actions'
  mattr_accessor :controller_groups_table
  @@controller_groups_table = 'controller_groups'

  mattr_accessor :controllers_group_name
  @@controllers_group_name = 'unassigned_controller_actions'
  mattr_accessor :controller_group_name_suffix
  @@controller_group_name_suffix = '_controller'

  mattr_accessor :cache_privilege_timeout
  @@cache_privilege_timeout = 10


  mattr_accessor :default_selector_controller
  @@default_selector_controller = 'selector'
  mattr_accessor :default_selector_action
  @@default_selector_action = 'show_members'

  mattr_accessor :default_group_selector_controller
  @@default_group_selector_controller = 'selector'
  mattr_accessor :default_group_selector_action
  @@default_group_selector_action = 'show_group_members'

  def self.setup
    yield self
  end

end

ActiveRecord::Base.send(:include, ActiveAclPlus::Acts::AccessGroup)

ActiveRecord::Base.send(:include, ActiveAclPlus::Acts::AccessObject)

$:.unshift File.join(File.dirname(__FILE__),'../app/models/')

begin
  ['privilege','acl_section','privilege','requester_link','target_link',
   'acl_section','requester_group_link','target_group_link','acl',
   'controller_group','controller_action'].each do |model|
    require "active_acl_plus/#{model}"
  end
rescue StandardError => e
  puts "[ERROR] ActiveAclPlus:  #{e.backtrace}. Migrating?"
end

$:.shift
