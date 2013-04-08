# This model is used for grouping ActiveAclPlus::ControllerAction models.
class ActiveAclPlus::ControllerGroup < ActiveRecord::Base
  set_table_name ActiveAclPlus.controller_groups_table
  acts_as_nested_set
  has_many :controller_actions,:class_name => 'ActiveAclPlus::ControllerAction'
  acts_as_access_group :type => ActiveAclPlus::Acts::AccessGroup::NestedSet

   validates_presence_of :description
   
  # Returns the instance representation in the admin screens. 
  def active_acl_description
    return description
  end

  # Returns the class representation in the admin screens.  
  def self.active_acl_description
    return 'ControllerGroup'
  end
  

end