module ActiveAclPlus
  module Acts 
    module Grant 
      # grant_privilege!(Blog::DELETE,
      # :on => blog,
      # :section => 'blogging' or a Hash or an ActiveAclPlus::AclSection
      # :acl => 'blogging_of_admins' or a hash or an ActiveAvl::Acl
      # :target_as_object => true/false target is treated as access_object         
      def grant_privilege!(privilege,options={})
        section = options[:section] || 'generic'
        target = options[:on]
        acl = options[:acl] || "#{privilege.active_acl_description}"
        ActiveAclPlus::Acl.transaction do
          unless acl.kind_of?(ActiveAclPlus::Acl)
            case section
              when String
              section = ActiveAclPlus::AclSection.find_or_create_by_iname(section)
              when Hash
              section = ActiveAclPlus::AclSection.create(section)
              #else section should be an ActiveAclPlus::AclSection
            end
            section.save! if section.new_record?
          end
          
          case acl
            when String
            acl=ActiveAclPlus::Acl.find_or_create_by_iname(acl)
            acl.section=section unless acl.section
            when Hash
            acl=ActiveAclPlus::Acl.create(acl.merge({:section => section}))
          end
          acl.save! if acl.new_record?
           
          acl.privileges << privilege
          if ActiveAclPlus.is_access_group?(self.class)
            acl.requester_groups << self unless acl.requester_groups.include?(self)
          else
            acl.requesters << self unless acl.requesters.include?(self)
          end
          if target
            if ActiveAclPlus.is_access_group?(target.class) && !options[:target_as_object]
              acl.target_groups << target unless acl.target_groups.include?(target)
            else
              acl.targets << target unless acl.targets.include?(target)
            end 
          end
          active_acl_clear_cache! if ActiveAclPlus.is_access_object?(self.class)
        end
        acl
      end
    end #module
  end
end
