ENV['RACK_ENV'] = 'test'

require File.dirname(__FILE__) + '/../app'
require 'test/unit'
require 'rack/test'
require 'json'

class Regression < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_show_users

    get '/users'
    result = JSON.parse(last_response.body)

    assert_kind_of(Array, result, 'Response is not an array of objects')

    result.each do |user|
      assert_not_nil(user['username'], 'Username must not be null')
    end
  end

  def test_find_by_username
    user = User.first

    get "/users/#{user.username}"
    result = JSON.parse(last_response.body)

    assert_equal(1, result.count, 'User not found')
  end

  def test_create_user

    test_user = { :username => 'johndoe', :first_name => 'John', :last_name => 'Doe' }
    post '/users', test_user.to_json, 'CONTENT_TYPE' => 'application/json'
    result = JSON.parse(last_response.body)

    assert_equal(201, last_response.status, 'Status must be 201 Created')
    assert_equal(test_user[:username], result['resource']['username'], 'Username does not match')
    assert_equal(test_user[:first_name], result['resource']['first_name'], 'First name does not match')
    assert_equal(test_user[:last_name], result['resource']['last_name'], 'Last name does not match')

    created_user = User.get(result['resource']['id'])
    created_user.destroy
  end

  def test_add_players_in_tournament

    tournament = Tournament.create(:name => "Test tournament #{Time.now}")
    users = User.all(:limit => 3).collect(&:id)

    payload = { :users => users }

    post "/tournaments/#{tournament.id}/players", payload.to_json, 'CONTENT_TYPE' => 'application/json'
    result = JSON.parse(last_response.body)

    assert_equal(201, last_response.status, 'Status must be 201 Created')
    assert_equal(users.count, result['resource']['players'].count)

    Tournament.get(result['resource']['tournament']['id']).players.each do |player|
      player.destroy
    end

    # Query the database twice, because the dependency does not refresh
    # after destroying the players associated with the Tournament
    Tournament.get(result['resource']['tournament']['id']).destroy
  end

  def test_show_user_detail
    sample_user = User.first

    get "/users/#{sample_user.id}"
    result = JSON.parse(last_response.body)

    assert_equal(200, last_response.status, 'Status must be 200 OK')
    assert_equal(sample_user.id, result['id'], 'Resource ID must match sample_user')
    assert_equal(sample_user.username, result['username'], 'Resource username must match sample_user')
  end

end