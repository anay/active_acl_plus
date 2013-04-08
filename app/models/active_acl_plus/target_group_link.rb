module ActiveAclPlus
  class TargetGroupLink < ActiveRecord::Base
    set_table_name ActiveAclPlus.target_group_links_table

    attr_accessible :acl_id, :target_group_id, :target_group_type, :target_group
    
    belongs_to :acl, :class_name => "ActiveAclPlus::Acl"
    belongs_to :target_group, :polymorphic => true
    
    def self.reloadable? #:nodoc:
      return false
    end
  end
end