

class PeopleQuery < Query
  self.queried_class = Principal

  VISIBILITY_PRIVATE = 0
  VISIBILITY_ROLES   = 1
  VISIBILITY_PUBLIC  = 2

  self.available_columns = [
    QueryColumn.new(:id, :sortable => "#{Person.table_name}.id", :default_order => 'desc', :caption => '#', :frozen => true, :inline => false),
    QueryColumn.new(:name, :sortable => lambda {Person.fields_for_order_statement}, :caption => :field_person_full_name),
    QueryColumn.new(:firstname, :sortable => "#{Person.table_name}.firstname", :caption => :field_firstname),
    QueryColumn.new(:lastname, :sortable => "#{Person.table_name}.lastname", :caption => :field_lastname),
    QueryColumn.new(:middlename, :sortable => "#{PeopleInformation.table_name}.middlename", :caption => :label_people_middlename),
    QueryColumn.new(:gender, :sortable => "#{PeopleInformation.table_name}.gender", :groupable => "#{PeopleInformation.table_name}.gender", :caption => :label_people_gender),
    QueryColumn.new(:email, :sortable => Redmine::VERSION.to_s >= '3.0' ? "email_addresses.address" : "#{Person.table_name}.mail", :caption => :field_mail),
    QueryColumn.new(:address, :sortable => "#{PeopleInformation.table_name}.address", :caption => :label_people_address),
    QueryColumn.new(:phone, :sortable => "#{PeopleInformation.table_name}.phone", :caption => :label_people_phone),
    QueryColumn.new(:skype, :sortable => "#{PeopleInformation.table_name}.skype", :caption => :label_people_skype ),
    QueryColumn.new(:twitter, :sortable => "#{PeopleInformation.table_name}.twitter", :caption => :label_people_twitter),
    QueryColumn.new(:facebook, :sortable => "#{PeopleInformation.table_name}.facebook", :caption => :label_people_facebook),
    QueryColumn.new(:linkedin, :sortable => "#{PeopleInformation.table_name}.linkedin", :caption => :label_people_linkedin),
    QueryColumn.new(:birthday, :sortable => "#{PeopleInformation.table_name}.birthday", :caption => :label_people_birthday),
    QueryColumn.new(:job_title, :sortable => "#{PeopleInformation.table_name}.job_title", :groupable => "#{PeopleInformation.table_name}.job_title", :caption => :label_people_job_title),
    QueryColumn.new(:background, :sortable => "#{PeopleInformation.table_name}.background", :caption => :label_people_background),
    QueryColumn.new(:appearance_date, :sortable => "#{PeopleInformation.table_name}.appearance_date", :caption => :label_people_appearance_date),
    QueryColumn.new(:last_login_on, :sortable => "#{Person.table_name}.last_login_on", :caption => :field_last_login_on),
    QueryColumn.new(:department_id, :sortable => "#{Department.table_name}.name", :groupable => "#{PeopleInformation.table_name}.department_id", :caption => :label_people_department),
    QueryColumn.new(:manager_id, :sortable => "#{Person.table_name}.firstname", :caption => :label_people_manager , :groupable => "#{PeopleInformation.table_name}.manager_id"),
    QueryColumn.new(:is_system, :sortable => "#{PeopleInformation.table_name}.is_system", :caption => :label_people_is_system),
    QueryColumn.new(:status, :sortable => "#{Person.table_name}.status", :caption => :field_status),
    QueryColumn.new(:tags, :caption => :label_people_tags_plural)
  ]

  scope :visible, lambda {|*args|
    user = args.shift || User.current

    if Redmine::VERSION.to_s < '2.4'
      field = 'is_public'
      public_value = true
      private_value = false
    else
      field = 'visibility'
      public_value = VISIBILITY_PUBLIC
      private_value = VISIBILITY_PRIVATE
    end

    if user.admin?
      where("#{table_name}.#{field} <> ? OR #{table_name}.user_id = ?", private_value, user.id)
    elsif user.logged?
      where("#{table_name}.#{field} = ? OR #{table_name}.user_id = ?", public_value, user.id)
    else
      where("#{table_name}.#{field} = ?", public_value)
    end
  }

  def visible?(user=User.current)
    return true if user.admin?
    case visibility
    when VISIBILITY_PUBLIC
      true
    else
      user.respond_to?(:id) && user.id == user_id
    end
  end

  def is_private?
    visibility == VISIBILITY_PRIVATE
  end

  def is_public?
    !is_private?
  end

  def visibility=(value)
    if Redmine::VERSION.to_s < '2.4'
      self.is_public = value.to_i == VISIBILITY_PUBLIC
    else
      self[:visibility] = value
    end
  end

  def visibility
    if Redmine::VERSION.to_s < '2.4'
      self.is_public ? VISIBILITY_PUBLIC : VISIBILITY_PRIVATE
    else
      self[:visibility]
    end
  end

  def editable_by?(user)
    return false unless user
    # Admin can edit them all and regular users can edit their private queries
    return true if user.admin? || (self.user_id == user.id)
    # Members can not edit public queries that are for all project (only admin is allowed to)
    is_public? && user.allowed_people_to?(:manage_public_people_queries)
  end

  def initialize(attributes=nil, *args)
    super attributes
    self.filters ||= { 'status' => {:operator => "=", :values => ['1']} }
  end

  def initialize_available_filters
    departments = []
    Department.department_tree(Department.order(:lft)) do |department, level|
      name_prefix = (level > 0 ? '-' * 2 * level + ' ' : '') #'&nbsp;'
      departments << [(name_prefix + department.name).html_safe, department.id.to_s]
    end
    add_available_filter("department_id", :type => :list_optional, :name => l(:label_people_department), :order => 18,
      :values => departments
    ) if departments.any?

    @available_filters ||= {}
  end

  def default_columns_names
    @default_columns_names ||= [:id, :name, :email, :phone]
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = self.class.available_columns.dup

    @available_columns += CustomField.where(:type => 'UserCustomField').all.collect {|cf| QueryCustomFieldColumn.new(cf) }
    @available_columns
  end

  def objects_scope(options={})
    scope = Person.where(:type => 'User').logged
    scope = scope.visible if Person.respond_to?(:visible)

    options[:search].split(' ').collect{ |search_string| scope = scope.seach_by_name(search_string) } if options[:search].present?

    includes =  (options[:include] || [] ) + [:department]
    includes << :email_address if Redmine::VERSION.to_s >= '3.0'

    scope = scope.eager_load(:information).includes( includes.uniq)

    unless self.filters['is_system']
      scope = scope.where("#{PeopleInformation.table_name}.is_system IS NULL OR #{PeopleInformation.table_name}.is_system = ?", ActiveRecord::Base.connection.quoted_false.gsub(/'/, ''))
    end

    scope = scope.where(statement).
      where(options[:conditions])

    scope
  end

  def object_count
    objects_scope.count
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def object_count_by_group
    r = nil
    if grouped?
      begin
        # Rails3 will raise an (unexpected) RecordNotFound if there's only a nil group value
        r = objects_scope.
          joins(joins_for_order_statement(group_by_statement)).
          group(group_by_statement).count
      rescue ActiveRecord::RecordNotFound
        r = {nil => object_count}
      end
      c = group_by_column
      if c.is_a?(QueryCustomFieldColumn)
        r = r.keys.inject({}) {|h, k| h[c.custom_field.cast_value(k)] = r[k]; h}
      end
    end
    r
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def results_scope(options={})
    order_option = [group_by_sort_order, options[:order]].flatten.reject(&:blank?)

    objects_scope(options).
      order(order_option).
      joins(joins_for_order_statement(order_option.join(','))).
      limit(options[:limit]).
      offset(options[:offset])
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def sql_for_department_id_field(field, operator, value)
    department_ids = value
    department_ids += Department.where(:id => value).map(&:descendants).flatten.collect{|c| c.id.to_s}.uniq
    sql_for_field(field, operator, department_ids, PeopleInformation.table_name, 'department_id')
  end

end
