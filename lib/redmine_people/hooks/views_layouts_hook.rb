
module RedminePeople
  module Hooks
    class ViewsLayoutsHook < Redmine::Hook::ViewListener
      def view_layouts_base_html_head(_context = {})
        stylesheet_link_tag(:redmine_people, plugin: 'redmine_people')
      end

      render_on :view_layouts_base_body_bottom, :partial => 'common/layout_bottom'
    end
  end
end
