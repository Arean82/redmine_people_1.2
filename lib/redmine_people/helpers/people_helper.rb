# encoding: utf-8

module RedminePeople
  module Helper
    module PeopleHelper

      def department_tree_tag(person, options={})
        return "" if person.department.blank?
        person.department.self_and_ancestors.map do |department|
          link_to department.name, department_path(department.id, options)
        end.join(' &#187; ').html_safe
      end
    end
  end
end

ActionView::Base.send :include, RedminePeople::Helper
