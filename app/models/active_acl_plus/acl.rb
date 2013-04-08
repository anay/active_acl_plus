# This model is the "glue" :-). Every permission assignment uses an Acl 
# model object, assigns objects, groups and privileges and setting   
# 'allow' to "true" or "false" to grant or deny access.

# These methods are added by the acts_as_access_object/group:
# requesters
# targets
# requester_groups
# target_groups

module ActiveAclPlus
  class Acl < ActiveRecord::Base
    set_table_name ActiveAclPlus.acls_table

    attr_accessible :section, :iname


    belongs_to :section, :class_name => 'ActiveAclPlus::AclSection', :foreign_key => 'section_id'
    has_and_belongs_to_many :privileges, :uniq => true, :join_table => ActiveAclPlus.acls_privileges_table, :class_name => 'ActiveAclPlus::Privilege'
    
    has_many :target_links, :dependent => :delete_all, :class_name => 'ActiveAclPlus::TargetLink'
    has_many :requester_links, :dependent => :delete_all,:class_name => 'ActiveAclPlus::RequesterLink'

    has_many :requester_group_links, :dependent => :delete_all,:class_name => 'ActiveAclPlus::RequesterGroupLink'
    has_many :target_group_links, :dependent => :delete_all,:class_name => 'ActiveAclPlus::TargetGroupLink'

    validates_uniqueness_of :iname
    validates_presence_of :iname
    
    def self.reloadable? #:nodoc:
      return false
    end
    
    # used as instance description in admin screen
    def active_acl_description
      if iname
        if section
        '/' + section.description + '/' + iname
        else
          return iname
        end
      else
        return nil
      end
    end
  end
end