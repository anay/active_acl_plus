class ActiveAclPlusTables < ActiveRecord::Migration
  def self.up
    create_table :<%= ActiveAclPlus.acls_table %> do |t|
      t.integer :section_id
      t.string :iname,       :null => false
      t.boolean :allow,      :null => false, :default => true
      t.boolean :enabled,    :null => false, :default => true
      t.text :description,   :null => true
      t.datetime :updated_at,:null => false
    end

    add_index :<%= ActiveAclPlus.acls_table %>, :enabled
    add_index :<%= ActiveAclPlus.acls_table %>, :section_id
    add_index :<%= ActiveAclPlus.acls_table %>, :updated_at
    add_index :<%= ActiveAclPlus.acls_table %>, :iname, :unique


    create_table :<%= ActiveAclPlus.acl_sections_table %> do |t|
      t.string :iname,      :null => false
      t.text :description,  :null => true
    end

    add_index :<%= ActiveAclPlus.acl_sections_table %>, :iname, :unique

    create_table :<%= ActiveAclPlus.privileges_table %> do |t|
      t.string :section,        :limit => 230, :null => false
      t.string :value,          :limit => 230, :null => false
      t.string :description,    :limit => 230, :null => true
    end

    add_index :<%= ActiveAclPlus.privileges_table %>, [:section, :value], :unique

    create_table :<%= ActiveAclPlus.acls_privileges_table %>, :id => false do |t|
      t.integer :acl_id, :null => false
      t.integer :privilege_id, :null => false
    end

    add_index :<%= ActiveAclPlus.acls_privileges_table %>, [:acl_id, :privilege_id], :unique

    create_table :<%= ActiveAclPlus.requester_links_table %> do |t|
      t.integer :acl_id,  :null => false
      t.integer :requester_id,  :null => false
      t.string :requester_type,  :null => false
    end

    add_index :<%= ActiveAclPlus.requester_links_table %>, [:acl_id, :requester_id, :requester_type], :unique => true, :name => 'requester_links_join_index_1'
    add_index :<%= ActiveAclPlus.requester_links_table %>, [:requester_type, :requester_id], :name => 'requester_links_join_index_2'
    add_index :<%= ActiveAclPlus.requester_links_table %>, [:requester_id]

    create_table :<%= ActiveAclPlus.requester_group_links_table %> do |t|
      t.integer :acl_id,  :null => false
      t.integer :requester_group_id,  :null => false
      t.string :requester_group_type,  :null => false
    end

    add_index :<%= ActiveAclPlus.requester_group_links_table %>, [:acl_id, :requester_group_id, :requester_group_type], :unique => true, :name => 'requester_group_links_join_index_1'
    add_index :<%= ActiveAclPlus.requester_group_links_table %>, [:requester_group_type, :requester_group_id], :name => 'requester_group_links_join_index2'

    create_table :<%= ActiveAclPlus.target_group_links_table %> do |t|
      t.integer :acl_id,  :null => false
      t.integer :target_group_id,  :null => false
      t.string :target_group_type,  :null => false
    end

    add_index :<%= ActiveAclPlus.target_group_links_table %>, [:acl_id, :target_group_id, :target_group_type], :unique => true, :name => 'target_group_links_join_index_1'
    add_index :<%= ActiveAclPlus.target_group_links_table %>, [:target_group_type, :target_group_id], :name => 'target_group_links_join_index_2'

    create_table :<%= ActiveAclPlus.target_links_table %> do |t|
      t.integer :acl_id,  :null => false
      t.integer :target_id,  :null => false
      t.string :target_type,  :null => false
    end

    add_index :<%= ActiveAclPlus.target_links_table %>, [:acl_id, :target_id, :target_type], :unique => true, :name => 'target_links_join_index_1'
    add_index :<%= ActiveAclPlus.target_links_table %>, [:target_type, :target_id], :name => 'target_links_join_index_2'
    add_index :<%= ActiveAclPlus.target_links_table %>, [:target_id]

    create_table :<%= ActiveAclPlus.controller_actions_table %> do |t|
      t.string :controller, :null => false
      t.string :action,  :null => false
      t.integer :controller_group_id,  :null => false
    end

    add_index :<%= ActiveAclPlus.controller_actions_table %>, [:controller, :action], :unique

    create_table :<%= ActiveAclPlus.controller_groups_table %> do |t|
      t.string :description, :null => false
      t.integer :lft
      t.integer :rgt
      t.integer :parent_id
    end

    add_index :<%= ActiveAclPlus.controller_groups_table %>, :description
    add_index :<%= ActiveAclPlus.controller_groups_table %>, :lft
    add_index :<%= ActiveAclPlus.controller_groups_table %>, :rgt
    add_index :<%= ActiveAclPlus.controller_groups_table %>, :parent_id

    # create root node
    execute("INSERT INTO <%= ActiveAclPlus.controller_groups_table %>(description, lft, rgt) VALUES ('controllers', 1, 2)")
  end

  def self.down
    drop_table :<%= ActiveAclPlus.acls_table %>
    drop_table :<%= ActiveAclPlus.acl_sections_table %>
    drop_table :<%= ActiveAclPlus.privileges_table %>
    drop_table :<%= ActiveAclPlus.acls_privileges_table %>
    drop_table :<%= ActiveAclPlus.requester_links_table %>
    drop_table :<%= ActiveAclPlus.target_links_table %>
    drop_table :<%= ActiveAclPlus.requester_group_links_table %>
    drop_table :<%= ActiveAclPlus.target_group_links_table %>
    drop_table :<%= ActiveAclPlus.controller_actions_table %>
    drop_table :<%= ActiveAclPlus.controller_groups_table %>
  end
end