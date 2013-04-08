require 'active_record'

module ActiveAclPlus #:nodoc:
  module Acts #:nodoc:
    module AccessGroup #:nodoc:
      
      def self.included(base)    
        base.extend(ClassMethods)
      end
      
      module ClassMethods
        # Extend self with access group capabilites.
        # Options can be: 
        # type:: is mandatory and is one of the group handler classes 
        # left_column:: for ActiveAclPlus::Acts::AccessGroup::NestedSet grouped objects
        # right_column:: for ActiveAclPlus::Acts::AccessGroup::NestedSet grouped objects
        
        def acts_as_access_group(options = {})
          type=options.delete(:type) || ActiveAclPlus::Acts::AccessGroup::NestedSet
          ActiveAclPlus.register_group(self,type.new(options))

          include ActiveAclPlus::Acts::Grant
          include InstanceMethods
          extend SingletonMethods                         
          
          ActiveAclPlus::Acl.instance_eval do
            has_many_polymorphs :requester_groups, {:from => ActiveAclPlus.from_group_classes,
              :through => :"active_acl_plus/requester_group_links",
              :rename_individual_collections => true}
            
            has_many_polymorphs :target_groups, {:from => ActiveAclPlus.from_group_classes,
              :through => :"active_acl_plus/target_group_links",
              :rename_individual_collections => true}
          end
          
        end
      end
      
      module SingletonMethods
        # class description in engine interface
        def active_acl_description
          name
        end
      end
      
      module InstanceMethods
        # override this to customize the description in the interface
        def active_acl_description
          to_s
        end              
      end
      
    end    
  end
end

