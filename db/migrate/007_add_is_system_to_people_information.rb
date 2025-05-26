# class AddIsSystemToPeopleInformation < ActiveRecord::Migration
class AddIsSystemToPeopleInformation < ActiveRecord::Migration[4.2]    

  def self.up
    add_column :people_information, :is_system, :boolean, :default => false
  end

  def self.down
    remove_column :people_information, :is_system
  end

end
