
class DepartmentsController < ApplicationController
  unloadable

  before_action :find_department, except: [:index, :create, :new]
  before_action :require_admin, only: [:destroy, :new, :create]
  before_action :authorize_people, only: [:update, :edit, :add_people, :remove_person]
  before_action :load_department_events, :load_department_attachments, only: [:show, :load_tab]

  helper :attachments

  def index
    @departments = Department.all
  end

  def edit
  end

  def new
    @department = Department.new
  end

  def show
    @department_tabs = helpers.department_tabs
  end

  def update
    @department.safe_attributes = params[:department]

    if @department.save
      attachments = Attachment.attach_files(@department, params[:attachments])
      render_attachment_warning_if_needed(@department)

      respond_to do |format| 
        format.html { redirect_to :action => "show", :id => @department } 
        format.api  { head :ok }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
        format.api  { render_validation_errors(@department) }
      end      
    end    
  end  

  def destroy  
    if @department.destroy
      flash[:notice] = l(:notice_successful_delete)
      respond_to do |format|
        format.html { redirect_to :controller => "people_settings", :action => "index", :tab => "departments" } 
        format.api { render_api_ok }
      end      
    else
      flash[:error] = l(:notice_unsuccessful_save)
    end

  end  

  def create
    @department = Department.new
    @department.safe_attributes = params[:department]

    if @department.save 
      respond_to do |format| 
        format.html { redirect_to :action => "show", :id => @department } 
        # format.html { redirect_to :controller => "people_settings", :action => "index", :tab => "departments" } 
        format.api  { head :ok }
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
        format.api  { render_validation_errors(@department) }
      end
    end
  end

  def add_people
    @people = PeopleInformation.where(:user_id => params[:person_id] || params[:person_ids])
    @department.people_information << @people if request.post?
    respond_to do |format|
      format.html { redirect_to :controller => 'departments', :action => 'edit', :id => @department, :tab => 'people' }
      format.js
      format.api { render_api_ok }
    end
  end

  def remove_person
    @department.people_information.delete(PeopleInformation.find(params[:person_id])) if request.delete?
    respond_to do |format|
      format.html { redirect_to :controller => 'departments', :action => 'edit', :id => @department, :tab => 'people' }
      format.js
      format.api { render_api_ok }
    end
  end


  def autocomplete_for_person
    @people = Person.active.where(:type => 'User').not_in_department(@department).like(params[:q]).limit(100)
    render :layout => false
  end

  def load_tab

  end

private
  def find_department
    @department = Department.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def authorize_people
    allowed = case params[:action].to_s
      when "create", "new"
        User.current.allowed_people_to?(:add_departments, @person)
      when "update", "edit", "add_people", "remove_person"
        User.current.allowed_people_to?(:edit_departments, @person)
      when "delete"
        User.current.allowed_people_to?(:delete_departments, @person)
      when "index", "show"
        User.current.allowed_people_to?(:view_departments, @person)
      else
        false
      end    

    if allowed
      true
    else  
      deny_access  
    end
  end  

  def load_department_attachments
    @department_attachments = @department.attachments
  end

  def load_department_events
    events = Redmine::Activity::CrmFetcher.new(User.current, :author => @department.people_of_branch_department).events(nil, nil, :limit => 10)
    @events_by_day = events.group_by(&:event_date)
  end

end
