class PeopleInformation < ActiveRecord::Base
  include Redmine::SafeAttributes

  self.table_name = "people_information"
  self.primary_key = 'user_id'

  belongs_to :person, foreign_key: :user_id
  belongs_to :department

  validate :validate_manager

  belongs_to :manager, class_name: 'Person'

  safe_attributes 'phone', 'address', 'skype', 'birthday', 'job_title', 'company', 'middlename', 'gender',
                  'twitter', 'facebook', 'linkedin', 'department_id', 'background', 'appearance_date',
                  'is_system', 'manager_id'

  def self.reject_information(attributes)
    exists = attributes['id'].present?

    if exists && !modified_system_fields?(Person.find_by_id(attributes['id']))
      attributes.delete('is_system')
    end

    empty = PeopleInformation.accessible_attributes.to_a.map { |name| attributes[name].blank? }.all?
    attributes.merge!({:_destroy => 1}) if exists and empty
    false
  end

  def self.modified_system_fields?(person)
    return false unless User.current.logged?

    if person.is_a?(User)
      User.current.admin? || (User.current.id == person.manager_id) || User.current.allowed_people_to?(:edit_people)
    else
      false
    end
  end

  private

  def validate_manager
    if manager_id_changed? && !manager_id.nil?
      if manager.nil? || (!self.new_record? && manager.manager_id == self.id) || (manager_id == id)
        errors.add(:manager_id, :invalid)
      end
    end
  end
end
