module ActiveAclPlus #:nodoc:
  module Acts #:nodoc:
    module AccessObject #:nodoc:
      
      # handels grouped objects
      # the group is a nested_set
      class ObjectHandler #:nodoc:
        attr_reader :klass,:group_class_name,:join_table,:group_table_name,
        :foreign_key,:association_foreign_key,:group_handler
        def initialize(klass,options={})
          @klass = klass
          if options[:grouped_by]
            @group_class_name = options[:grouped_by].to_s.classify
            @group_handler=ActiveAclPlus.group_handler(@group_class_name.constantize)
            @group_table_name=@group_class_name.constantize.table_name
            @join_table = options[:join_table] || [klass.name.pluralize.underscore.gsub(/\//,'_'), group_class_name.pluralize.underscore.gsub(/\//,'_')].sort.join('_')  
            @foreign_key = options[:foreign_key] || "#{klass.name.demodulize.underscore}_id" 
            @association_foreign_key = options[:association_foreign_key] || "#{group_class_name.demodulize.underscore}_id"
            @habtm = options[:habtm] || (options[:grouped_by].to_s.demodulize.singularize != options[:grouped_by].to_s.demodulize)
          end
          
          logger=Rails.logger
          logger.debug "ActiveAcl: registered ObjectHandler for #{klass}"
          logger.debug "grouped: #{self.grouped?}, habtm: #{habtm?}"
          #set the SQL fragments
          prepare_requester_sql
          prepare_target_sql
        end
        def habtm?
          @habtm
        end
        def grouped?
          !!@group_class_name
        end
        
        def klass_name 
          klass.base_class.name
        end

        def accessible_by(target,user, privilege)

          requester_group_class = group_class_name._as_class
          max_length_of_requester_group_rgt_value = requester_group_class.root.rgt.to_s.length

          target_handler = ActiveAclPlus.object_handler(target)
          target_group_class = target_handler.group_class_name._as_class
          max_length_of_target_group_rgt_value = target_group_class.root.rgt.to_s.length


          requester_sql_details = prepare_accessible_requester_sql target_group_class, requester_group_class, target, user.class, user
          target_sql_details = prepare_accessible_target_sql target, target_group_class, target_handler

          vars={'requester_id' => user.id}
          vars['requester_group_id'] = user.send(association_foreign_key) if !self.habtm? && self.grouped?
          #vars['target_group_id'] = target.send(t_handler.association_foreign_key) unless t_handler.habtm?
          sql = ''
          sql << requester_sql_details[:select]


          sql << target_sql_details[:select]
          sql << "\n WHERE "
          sql << requester_sql_details[:where]
          sql << target_sql_details[:where]

          vars['privilege_id'] = privilege.id
          vars['target_type'] = target.name

          #replacing the vars in the SQL
          sql=sql.gsub(/%\{[^\}]+\}/) do |var|
            vars[var[2..-2]] || var
          end

          multiplier_size = 0

          v5_multiplier = "1#{"0"*(max_length_of_target_group_rgt_value)}"
          v5_normalizer = "1#{"0"*(max_length_of_target_group_rgt_value)}"
          multiplier_size = v5_multiplier.length

          v4_multiplier = "1#{"0"*(multiplier_size)}"
          multiplier_size = v4_multiplier.length() -1 + 2

          v3_multiplier = "1#{"0"*(multiplier_size)}"
          v3_normalizer = "1#{"0"*(max_length_of_requester_group_rgt_value)}"
          multiplier_size = v3_multiplier.length() -1 + max_length_of_requester_group_rgt_value

          v2_multiplier = "1#{"0"*(multiplier_size)}"



          sort_field_unified_query = "select (10+v2)*#{v2_multiplier}+(#{v3_normalizer} - v3)*#{v3_multiplier}+(10+v4)*#{v4_multiplier}+(#{v5_normalizer} - v5) sort_order, allow, id  from (#{sql}) as the_query order by id asc, sort_order asc"

          valid_id_query = "select valid_id from (select the_left.id valid_id, the_left.allow, the_right.id from (#{sort_field_unified_query}) as the_left left join (select id, min(sort_order) min_sort_order from (#{sort_field_unified_query})as y group by(id)) as the_right on the_left.id=the_right.id and the_left.sort_order = the_right.min_sort_order where the_right.id>0 and the_left.allow = 't') as valids"

          results = ActiveRecord::Base.connection.select_all(valid_id_query) #get the query from the db
          #value=set_cached(requester,privilege,target,results)
          return results
        end

        
        #checks the privilege of a requester on a target (optional)
        def has_privilege?(requester,privilege,target=nil)
          value = get_cached(requester,privilege,target)
          
          return value unless value.nil? #got the cached and return
          #todo check cash l2
          
          vars={'requester_id' => requester.id}
          vars['requester_group_id'] = requester.send(association_foreign_key) if !self.habtm? && self.grouped?
          sql = ''
          sql << query_r_select
          if target
            t_handler=target.active_acl_handler
            
            sql << t_handler.query_t_select
            sql << "\n WHERE "
            sql << query_r_where_3d
            sql << t_handler.query_t_where
            sql << "\n ORDER BY "
            
            #TODO: ordering is a mess (use an array?)
            order = (grouped? ? order_by_3d.dup : [])
            if t_handler.grouped? 
              order << "(CASE WHEN t_g_links.acl_id IS NULL THEN 0 ELSE 1 END) ASC"
              order << t_handler.group_handler.order_by(target,true)
              vars['target_group_id'] = target.send(t_handler.association_foreign_key) unless t_handler.habtm?
            end
            order << 'acls.updated_at DESC'
            sql << order.join(',')
            
            sql << " LIMIT 1"
            vars['privilege_id'] = privilege.id
            vars['target_id'] = target.id
            vars['target_type'] = target.class.base_class.name
          else
            sql << " WHERE "
            sql << query_r_where_2d
            sql << "\n ORDER BY "
            sql << order_by_2d
          end
          
          #replacing the vars in the SQL
          sql=sql.gsub(/%\{[^\}]+\}/) do |var|
            vars[var[2..-2]] || var
          end
          
          results = ActiveRecord::Base.connection.select_all(sql) #get the query from the db
          value=set_cached(requester,privilege,target,results)
          return value
        end
        #gets the instance cache from the background store or a hash
        def get_instance_cache(requester)
          {}
        end
        #destroy the 2nd level cache
        def delete_cached(requester)
          #cache.delete(requester_cache_id(requester))
        end
        
        attr_reader :query_t_select,:query_t_where
        
        #Things go private from here ----------------
        private
        def cache
          @cache ||= {}
        end
        
        #builds a instance_cache key for a query
        def query_id(requester,privilege,target)
          privilege_id = (privilege.kind_of?(ActiveAclPlus::Privilege) ? privilege.id : privilege)
          [privilege_id, klass.base_class.name, requester.id, (target ? target.class.base_class.name : ''), (target ? target.id.to_s : '')].join('-')
        end
        
        #builds the cache key for a requester for beackground cache
        def requester_cache_id(requester)
          'active_acl_instance-' + klass.base_class.name + '-' + requester.id.to_s
        end
        
        # Caching is done on different levels:
        # Requesting a 2d privilege should fill the instance cache with all 2d privileges
        # Requesting a 3d should be stored in the instance cache
        # changing the instance cache stores it to the backstore (if any exists) 
        def get_cached(requester,privilege,target)
          
          instance_cache=requester.active_acl_instance_cache          
          q_id=query_id(requester,privilege,target)
          # try to get from instance cache
          if (value=instance_cache[q_id]).nil? #cache miss?
            if target.nil? && requester.active_acl_cached_2d?
              Rails.logger.debug 'ACTIVE_ACL::INSTANCE_CACHE::DENY ' + q_id
              return false #it should be cached but it's not there: DENY
            else
              return nil #we don't cache all 3d acl: DB LOOKUP
            end
          else #found in cache: return the results
            Rails.logger.debug 'ACTIVE_ACL::INSTANCE_CACHE::' + (value ? 'GRANT ' : 'DENY ') + q_id 
            return value 
          end
          nil
        end
        
        def set_cached(requester,privilege,target,results)
          
          this_query_id=query_id(requester,privilege,target)
          instance_cache=requester.active_acl_instance_cache
          
          if target.nil? #no target? then results are all 2d privileges of the requester
            last_privilege_value = nil
            results.each do |row|
              if row['privilege_id'] != last_privilege_value
                last_privilege_value = row['privilege_id']
                q_id=query_id(requester,last_privilege_value,nil)
                #TODO: put the true comparison into the db handler
                v=((row['allow'] == '1') or (row['allow'] == 't'))
                instance_cache[q_id] = v
              end
            end
            requester.active_acl_cached_2d! #mark the cache as filled (at least 2d)
            # the result should be in the cache now or we return false 
            value=instance_cache[this_query_id] || false
          else #3d request?
            if results.empty?
              value=false
              instance_cache[this_query_id] = value
            else #3d and a hit
              value = ((results[0]['allow'].to_s == '1') or (results[0]['allow'].to_s == 't'))
              instance_cache[this_query_id] = value
            end
          end
          raise "something went realy wrong!" if value.nil?
          
          #cache the whole instance cache
          #cache.set(requester_cache_id(requester),instance_cache,ActiveAclPlus.cache_privilege_timeout)
          
          value
        end
        
        # build ACL query strings once, 
        # so we don't need to do this on every request
        # SQL: 
        # we always need acl,and privileges, and requester_links
        # we need the target_links if its a 3d query
        # we need the target_groups if the it's a 3d query and the target is grouped
        # we need the requester_groups if the requester is grouped
        # the ordering depens on 2d/3d
        # We'll build the SQL on demand and cache it so it'll 
        # be a function of: requester,target,privilege 
        attr_reader :query_r_select, :query_r_where_2d, :query_r_where_3d, :order_by_3d,:order_by_2d
        def prepare_requester_sql
          @query_r_select = <<-QUERY
            SELECT acls.id, acls.allow, privileges.id AS privilege_id FROM #{ActiveAclPlus.acls_table} acls
            LEFT JOIN #{ActiveAclPlus.acls_privileges_table} acls_privileges ON acls_privileges.acl_id=acls.id
            LEFT JOIN #{ActiveAclPlus.privileges_table} privileges ON privileges.id = acls_privileges.privilege_id
            LEFT JOIN #{ActiveAclPlus.requester_links_table} r_links ON r_links.acl_id=acls.id
            QUERY
          if grouped?
            requester_groups_table = group_class_name.constantize.table_name
            requester_group_type = group_class_name.constantize.name
            
            @query_r_select << "
            LEFT JOIN #{ActiveAclPlus.requester_group_links_table} r_g_links ON acls.id = r_g_links.acl_id AND r_g_links.requester_group_type = '#{requester_group_type}'
            LEFT JOIN #{requester_groups_table} r_groups ON r_g_links.requester_group_id = r_groups.id
            "
          end
          
          @query_r_where_3d = "acls.enabled = #{klass.connection.quote(true)} AND (privileges.id = %{privilege_id}) "
          @query_r_where_2d = "acls.enabled = #{klass.connection.quote(true)}"
          query = " AND ((r_links.requester_id=%{requester_id}  
          AND r_links.requester_type='#{klass.base_class.name}')"
          if grouped?
            
            query << " OR (r_g_links.requester_group_id IN #{group_handler.group_sql(self)})) "
          else
            query << ")" 
          end
          @query_r_where_3d << query
          @query_r_where_2d << query
          
          
          #@query_r_where_2d << '(t_g_links.acl_id IS NULL)) '
          @order_by_3d = []
          @order_by_3d << "(CASE WHEN r_g_links.acl_id IS NULL THEN 0 ELSE 1 END) ASC"
          @order_by_3d << group_handler.order_by(self) if grouped?
          
           
          
          #TODO ordering of groups
          @order_by_2d = 'privileges.id,'
          @order_by_2d << "(CASE WHEN r_g_links.acl_id IS NULL THEN 0 ELSE 1 END) ASC," if grouped?
          @order_by_2d << "acls.updated_at DESC"
        end
        
        def prepare_target_sql
          @query_t_select = " LEFT JOIN #{ActiveAclPlus.target_links_table} t_links ON t_links.acl_id=acls.id"
          if grouped?
            target_groups_table = @group_class_name.constantize.table_name
            target_group_type = @group_class_name.constantize.name
            
            @query_t_select << " LEFT JOIN #{ActiveAclPlus.target_group_links_table} t_g_links ON t_g_links.acl_id=acls.id
                                AND t_g_links.target_group_type = '#{target_group_type}'
                                LEFT JOIN #{target_groups_table} t_groups ON t_groups.id=t_g_links.target_group_id"
          end 
          @query_t_where = " AND ((t_links.target_id=%{target_id}
                             AND t_links.target_type = '%{target_type}' )"
          if grouped?
            @query_t_where << " OR t_g_links.target_group_id IN #{group_handler.group_sql(self,true)})"
          else
            @query_t_where << ")"
          end
        end


        ##########################

        def prepare_accessible_requester_sql target_group_class, requester_group_class, target_class, requester_class, requester
          accessible_query_r_select = ""
          accessible_query_r_select = <<-QUERY
            SELECT  the_target.id as v1, (CASE WHEN r_g_links.acl_id IS NULL THEN 0 ELSE 1 END) as v2,(CASE WHEN (r_groups.rgt - r_groups.lft) IS NULL THEN 0 ELSE (r_groups.rgt - r_groups.lft) END) as v3,(CASE WHEN t_g_links.acl_id IS NULL THEN 0 ELSE 1 END) as v4,(CASE WHEN (t_groups.rgt - t_groups.lft) IS NULL THEN 0 ELSE (t_groups.rgt - t_groups.lft) END) as v5, acls.allow, the_target.id FROM #{ActiveAclPlus.acls_table} acls
            LEFT JOIN #{ActiveAclPlus.acls_privileges_table} acls_privileges ON acls_privileges.acl_id=acls.id
            LEFT JOIN #{ActiveAclPlus.privileges_table} privileges ON privileges.id = acls_privileges.privilege_id
            LEFT JOIN #{ActiveAclPlus.requester_links_table} r_links ON r_links.acl_id=acls.id
          QUERY

          requester_groups_table = requester_group_class.table_name
          requester_group_type = requester_group_class.name

          accessible_query_r_select << "
          LEFT JOIN #{ActiveAclPlus.requester_group_links_table} r_g_links ON acls.id = r_g_links.acl_id AND r_g_links.requester_group_type = '#{requester_group_type}'
          LEFT JOIN #{requester_groups_table} r_groups ON r_g_links.requester_group_id = r_groups.id
          "

          accessible_query_r_where_3d = "acls.enabled = #{klass.connection.quote(true)} AND (privileges.id = %{privilege_id}) "
          query = " AND ((r_links.requester_id=%{requester_id}
          AND r_links.requester_type='#{klass.base_class.name}')"


          query << " OR (r_g_links.requester_group_id IN #{group_handler.group_sql(self)})) "

          accessible_query_r_where_3d << query

          {
              :select => accessible_query_r_select,
              :where => accessible_query_r_where_3d
          }

        end


        def prepare_accessible_target_sql target_class, target_group_class, target_handler
          accessibe_query_t_select = " LEFT JOIN #{ActiveAclPlus.target_links_table} t_links ON t_links.acl_id=acls.id"
          target_groups_table = target_group_class.table_name
          target_group_type = target_group_class.name

          accessibe_query_t_select << " LEFT JOIN #{ActiveAclPlus.target_group_links_table} t_g_links ON t_g_links.acl_id=acls.id
                                AND t_g_links.target_group_type = '#{target_group_type}'
                                LEFT JOIN #{target_class.table_name} the_target ON the_target.id = t_links.target_id OR t_g_links.target_group_id=the_target.category_id
                                LEFT JOIN #{target_groups_table} t_groups ON t_groups.id=t_g_links.target_group_id"
          accessibe_query_t_where = " AND ((t_links.target_type = '%{target_type}' )"
          accessibe_query_t_where << " OR t_g_links.target_group_id IN #{target_handler.group_handler.accessible_group_sql(target_handler,true)})"

          {
              :select => accessibe_query_t_select,
              :where => accessibe_query_t_where
          }
        end


      end
    end
  end
end
