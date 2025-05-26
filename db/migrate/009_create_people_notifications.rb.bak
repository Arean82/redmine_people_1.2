

class CreatePeopleNotifications < ActiveRecord::Migration
class CreatePeopleNotifications < ActiveRecord::Migration[4.2]      
  def change
    create_table :people_notifications do |t|
      t.string :description
      t.date :start_date
      t.date :end_date
      t.string :frequency
      t.string :kind
      t.boolean :active, :default => false
      t.timestamps :null => false
    end
  end
end
