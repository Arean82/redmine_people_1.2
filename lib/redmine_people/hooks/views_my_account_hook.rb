
module RedminePeople
  module Hooks
    class ViewsMyAccountHook < Redmine::Hook::ViewListener
      render_on :view_my_account, :partial => 'my/disabled_fields'
    end
  end
end
