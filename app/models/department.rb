class Department < ActiveRecord::Base
  include Redmine::SafeAttributes
  acts_as_attachable
  unloadable
  belongs_to :head, :class_name => 'Person', :foreign_key => 'head_id'

  has_many :people_information, :class_name => "PeopleInformation", :dependent => :nullify

  if ActiveRecord::VERSION::MAJOR >= 4
    has_many :people, lambda { uniq }, :class_name => 'Person', :through => :people_information
  else
    has_many :people, :class_name => 'Person', :through => :people_information, :uniq => true
  end

  if Redmine::VERSION.to_s < '3.0'
    acts_as_nested_set :order => 'name', :dependent => :destroy
  else
    include DepartmentNestedSet
  end

  # Removed acts_as_attachable_global as it causes error

  validates_presence_of :name 
  validates_uniqueness_of :name 

  safe_attributes 'name',
    'background',
    'parent_id',
    'head_id'

  def to_s
    name
  end

  def all_childs
    Department.where("lft > ? AND rgt < ?", lft, rgt).order('lft')
  end

  # Yields the given block for each department with its level in the tree
  def self.department_tree(departments, &block)
    ancestors = []
    departments.sort_by(&:lft).each do |department|
      while (ancestors.any? && !department.is_descendant_of?(ancestors.last))
        ancestors.pop
      end
      yield department, ancestors.size
      ancestors << department
    end
  end  

  def css_classes
    s = 'project'
    s << ' root' if root?
    s << ' child' if child?
    s << (leaf? ? ' leaf' : ' parent')
    s
  end

  def project
    @project ||= Project.new
  end

  def allowed_parents
    return @allowed_parents if @allowed_parents
    @allowed_parents = Department.all - self_and_descendants - [self]
    @allowed_parents << nil
  end

  def people_of_branch_department
    department_ids = (self.all_childs + [self]).map(&:id)
    Person.joins(:information).where("#{PeopleInformation.table_name}.department_id" => department_ids)
  end

  def attachments_visible?(user=User.current)
    (respond_to?(:visible?) ? visible?(user) : true) &&
    (user.allowed_people_to?(:edit_departments) || PeopleInformation.find_by_user_id(user.id).try(:department_id) == self.id)
  end

  def attachments_editable?(user=User.current)
    (respond_to?(:visible?) ? visible?(user) : true) &&
      user.allowed_people_to?(:edit_departments)
  end

  def attachments_deletable?(user=User.current)
    (respond_to?(:visible?) ? visible?(user) : true) &&
      user.allowed_people_to?(:edit_departments)
  end

end
