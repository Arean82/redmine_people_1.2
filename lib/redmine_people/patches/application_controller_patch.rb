
module RedminePeople
  module Patches
    module ApplicationControllerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
        end
      end

      module InstanceMethods
        private

        def set_person
          @person = Person.find(params[:person_id])
        rescue ActiveRecord::RecordNotFound
          render_404
        end
      end
    end
  end
end

unless ApplicationController.included_modules.include?(RedminePeople::Patches::ApplicationControllerPatch)
  ApplicationController.send(:include, RedminePeople::Patches::ApplicationControllerPatch)
end
