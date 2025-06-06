# encoding: utf-8


require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')

class RedminePeople::TestCase
  include ActionDispatch::TestProcess

  module TestHelper
    def with_people_settings(options, &block)
      saved_settings = options.keys.inject({}) do |h, k|
        h[k] = case Setting.plugin_redmine_people[k]
          when Symbol, false, true, nil, Fixnum
            Setting.plugin_redmine_people[k]
          else
            Setting.plugin_redmine_people[k].dup
          end
        h
      end
      settings = Setting.plugin_redmine_people
      Setting.plugin_redmine_people = settings.merge(options)
      yield
    ensure
      saved_settings.each {|k, v| Setting.plugin_redmine_people[k] = v} if saved_settings
    end

    def people_uploaded_file(filename, mime)
      fixture_file_upload("../../plugins/redmine_people/test/fixtures/files/#{filename}", mime, true)
    end
  end

  def self.create_fixtures(fixtures_directory, table_names, class_names = {})
    if ActiveRecord::VERSION::MAJOR >= 4
      ActiveRecord::FixtureSet.create_fixtures(fixtures_directory, table_names, class_names = {})
    else
      ActiveRecord::Fixtures.create_fixtures(fixtures_directory, table_names, class_names = {})
    end
  end  

end
