module ActiveAclPlus
  class RequesterGroupLink < ActiveRecord::Base
    set_table_name ActiveAclPlus.requester_group_links_table

    attr_accessible :acl_id, :requester_group_id, :requester_group_type, :requester_group
    
    belongs_to :acl, :class_name => "ActiveAclPlus::Acl"
    belongs_to :requester_group, :polymorphic => true
    
    def self.reloadable? #:nodoc:
      return false
    end
  end
end