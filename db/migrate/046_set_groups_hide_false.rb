class SetGroupsHideFalse < ActiveRecord::Migration
  def self.up
    begin
      execute "UPDATE groups SET hide = false"
    rescue
      true
    end
  end
  
  def self.down
    # Don't look back
    raise ActiveRecord::IrreversibleMigration
  end
end