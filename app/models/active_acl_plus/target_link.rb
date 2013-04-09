module ActiveAclPlus
  class TargetLink < ActiveRecord::Base
    set_table_name ActiveAclPlus.target_links_table

    attr_accessible :acl_id, :target_id, :target_type, :target

    belongs_to :acl, :class_name => "ActiveAclPlus::Acl"
    belongs_to :target, :polymorphic => true

    def self.reloadable? #:nodoc:
      return false
    end
  end
end