# encoding: utf-8

require File.expand_path('../../test_helper', __FILE__)

class UserPatchTest < ActiveSupport::TestCase

  fixtures :users, :projects, :roles, :members, :member_roles
  fixtures :email_addresses if ActiveRecord::VERSION::MAJOR >= 4

  def setup
    Setting.plugin_redmine_people = {}

    @params =  { 'firstname' => 'newName', 'lastname' => 'lastname', 'mail' => 'mail@mail.com', 'language' => 'ru'}
    @user = User.find(4)
    User.current = @user
  end
  
  def test_create_by_anonumys_self_registration_off
    Setting.self_registration = '0'
    User.current = nil

    user = User.new
    user.safe_attributes = @params
    user.login = 'login'
    user.password, @user.password_confirmation = 'password','password'

    assert (not user.save)
  end

  def test_create_by_anonumys_self_registration_on
    Setting.self_registration = '1'
    User.current = nil

    user = User.new
    user.safe_attributes = @params
    user.login = 'login'
    user.password, @user.password_confirmation = 'password','password'

    assert user.save
  end

  def test_save_without_own_data_access
    @user.safe_attributes = @params
    @user.save!
    @user.reload
    assert_not_equal 'newName', @user.firstname
    assert_equal 'ru', @user.language
  end

  def test_save_with_own_data_access
    Setting.plugin_redmine_people['edit_own_data'] = '1'
    @user.safe_attributes = @params
    @user.save!
    @user.reload
    assert_equal 'newName', @user.firstname
  end

  def test_allowed_people_to_for_edit_subordinates
    manager = Person.find(3)
    subordinate = Person.find(4)

    # Without permission
    assert (not manager.allowed_people_to?(:edit_people, subordinate) )
    
    # Adds permission
    PeopleAcl.create(3, ['edit_subordinates'])
    assert manager.allowed_people_to?(:edit_people, subordinate)
  end

end
