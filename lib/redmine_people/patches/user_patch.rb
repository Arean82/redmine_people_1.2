
require_dependency 'project'
require_dependency 'principal'
require_dependency 'user'

module RedminePeople
  module Patches
    module UserPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          
          alias_method :'allowed_to?_without_people', :allowed_to?
          alias_method :allowed_to?, :'allowed_to?_with_people'

          has_one :avatar, lambda { where("#{Attachment.table_name}.description = 'avatar'") }, :class_name => 'Attachment', :as => :container, :dependent => :destroy
          acts_as_attachable_global

          def self.clear_safe_attributes
            @safe_attributes.collect! do |attrs, options|
              if attrs.collect!(&:to_s).include?('firstname')
                [attrs - ['firstname', 'lastname', 'mail', 'custom_field_values', 'custom_fields'], options]
              else
                [attrs, options]
              end
            end
          end
          self.clear_safe_attributes

          safe_attributes 'firstname', 'lastname', 'mail', 'custom_field_values', 'custom_fields',
          :if => lambda { |user, current_user| current_user.allowed_people_to?(:edit_people, user) || (user.new_record? && current_user.anonymous? && Setting.self_registration?) }
        end
      end

      module InstanceMethods
        # include ContactsHelper

        def project
          @project ||= Project.new
        end

        def allowed_people_to?(permission, person = nil)
          unless RedminePeople.available_permissions.include?(permission)
            raise "The permission #{permission} does not exist"
          end

          return true if admin?

          if respond_to?(:"check_permission_#{permission.to_s}", true)
            send("check_permission_#{permission}".to_sym, person)
          else
            has_permission?(permission)
          end
        end

        define_method 'allowed_to?_with_people' do |action, context, options={}, &block|
          return allowed_people_to?(action) if !action.is_a?(Hash) && RedminePeople.available_permissions.include?(action)

          public_send('allowed_to?_without_people', action, context, options, &block)
        end

        def has_permission?(permission)
          (groups + [self]).map { |principal| PeopleAcl.allowed_to?(principal, permission) }.inject { |memo, allowed| memo || allowed }
        end

        protected

        def check_permission_view_people(person)
          if person && person.is_a?(User) && person.id == id
            return true
          elsif is_a?(User) && !anonymous? && Setting.plugin_redmine_people['visibility'].to_i > 0
            return true
          end
          has_permission?(:view_people)
        end

        def check_permission_edit_people(person)
          if person && person.is_a?(User)
            # Check to edit himself
            if person.id == id && Setting.plugin_redmine_people['edit_own_data'].to_i > 0
              return true
            end

            # Check to edit subordinates.
            # Works only for persons.
            if person.respond_to?(:manager_id) && has_permission?(:edit_subordinates) && id == person.manager_id
              return true
            end
          end

          has_permission?(:edit_people)
        end

        def check_permission_view_performance(person)
          (person.is_a?(User) && person.id == self.id) || has_permission?(:view_performance)
        end
      end
    end
  end
end

unless User.included_modules.include?(RedminePeople::Patches::UserPatch)
  User.send(:include, RedminePeople::Patches::UserPatch)
end
