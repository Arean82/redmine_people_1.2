require File.dirname(__FILE__) + '/lib/acts_as_attachable_global'

 
unless ActiveRecord::Base.included_modules.include?( Redmine::Acts::AttachableGlobal)
  ActiveRecord::Base.send(:include,  Redmine::Acts::AttachableGlobal)  
end
