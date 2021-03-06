require 'test_helper'

class UsersSignupTest < ActionDispatch::IntegrationTest
  test 'invalid signup information' do
    get signup_path
    assert_no_difference 'User.count' do
      post users_path, params: { user: { email: 'user@invalid',
                                         password: 'foo',
                                         password_confirmation: 'bar' } }
    end
    assert_template 'users/new'
    assert_select 'div#error_explanation'
    assert_select 'div.field_with_errors'
  end

  test 'illegal j-scorer email address' do
    get signup_path
    assert_no_difference 'User.count' do
      post users_path, params: { user: { email: 'someone@j-scorer.com',
                                         password: 'password',
                                         password_confirmation: 'password' } }
    end
    assert_template 'users/new'
    assert_select 'div#error_explanation'
    assert_select 'div.field_with_errors'
  end

  test 'valid signup information' do
    get signup_path
    assert_difference 'User.count', 1 do
      post users_path,
           params: { user: { email: 'user@example.com',
                             password: 'password',
                             password_confirmation: 'password' } }
      follow_redirect!
    end
    assert_template 'pages/home'
    assert logged_in_here?
    assert_not flash.empty?
  end
end
