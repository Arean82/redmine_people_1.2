requires_redmine_crm version_or_higher: '0.0.19' rescue raise("\n\033[31mRedmine requires newer redmine_crm gem version.\nPlease update with 'bundle update redmine_crm'.\033[0m")

# Add plugin's lib folder to the load path to find redmine_people.rb
$LOAD_PATH.unshift(File.expand_path('lib', __dir__))

require 'redmine_people'

PEOPLE_VERSION_NUMBER = '1.2.0'
PEOPLE_VERSION_TYPE = "Light version"

QUOTED_TRUE = ActiveRecord::Base.connection.quoted_true.gsub(/'/, '')
QUOTED_FALSE = ActiveRecord::Base.connection.quoted_false.gsub(/'/, '')

Redmine::Plugin.register :redmine_people do
  name "Redmine People plugin (#{PEOPLE_VERSION_TYPE})"
  author 'RedmineCRM'
  description 'This is a plugin for managing Redmine users'
  version PEOPLE_VERSION_NUMBER
  url 'http://redminecrm.com/projects/people'
  author_url 'mailto:support@redminecrm.com'

  requires_redmine version_or_higher: '5.0.0'

  settings default: {
    users_acl: {},
    visibility: '',
    hide_age: '0',
    edit_own_data: '1',
  }

  menu :top_menu, :people, {controller: 'people', action: 'index', project_id: nil}, caption: :label_people, if: Proc.new {
    User.current.allowed_people_to?(:view_people)
  }

  menu :admin_menu, :people, {controller: 'people_settings', action: 'index'}, caption: :label_people
end
