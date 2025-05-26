

# class AddManagerToPeopleInformation < ActiveRecord::Migration

class AddManagerToPeopleInformation < ActiveRecord::Migration[4.2]     

  def self.up
    add_column :people_information, :manager_id, :integer
  end

  def self.down
    remove_column :people_information, :manager_id
  end

end
