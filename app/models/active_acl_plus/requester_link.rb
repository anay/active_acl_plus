module ActiveAclPlus
  class RequesterLink < ActiveRecord::Base
    set_table_name ActiveAclPlus.requester_links_table
    
    belongs_to :acl, :class_name => "ActiveAclPlus::Acl"
    belongs_to :requester, :polymorphic => true
    
    def self.reloadable? #:nodoc:
      return false
    end
  end
end