require 'active_acl_plus'

ActiveAclPlus.setup do |config|


  config.acl_sections_table = 'acl_sections'
  config.acls_privileges_table = 'acls_privileges'
  config.acls_table = 'acls'
  config.privileges_table = 'privileges'
  config.requester_links_table = 'requester_links'
  config.target_links_table = 'target_links'
  config.requester_group_links_table = 'requester_group_links'
  config.target_group_links_table = 'target_group_links'
  config.controller_actions_table = 'controller_actions'
  config.controller_groups_table = 'controller_groups'

  config.controllers_group_name = 'unassigned_controller_actions'
  config.controller_group_name_suffix = '_controller'

  config.cache_privilege_timeout = 10


  config.default_selector_controller = 'selector'
  config.default_selector_action = 'show_members'

  config.default_group_selector_controller = 'selector'
  config.default_group_selector_action = 'show_group_members'


end