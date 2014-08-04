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

    get "/users/search/#{user.username}"
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

    payload = { :tournament_id => tournament.id, :users => users }

    post '/players', payload.to_json, 'CONTENT_TYPE' => 'application/json'
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

  def test_log_match_in_tournament

    # Create new tournament
    tournament = Tournament.create(:name => "Test tournament #{Time.now}")

    # Add existing users to tournament
    users = User.all(:limit => 2).collect(&:id)
    players_payload = { :tournament_id => tournament.id, :users => users }

    post '/players', players_payload.to_json, 'CONTENT_TYPE' => 'application/json'
    players_result = JSON.parse(last_response.body)

    # Prepare payload for the Match POST
    scores = []

    games_won = 3
    players_result['resource']['players'].each do |player|
      score = { :user_id => player['id'], :games_won => games_won }
      scores << score
      games_won -= 1
    end

    match_payload = { :tournament_id => tournament.id, :scores => scores }

    post '/matches', match_payload.to_json, 'CONTENT_TYPE' => 'application/json'
    matches_result = JSON.parse(last_response.body)

    assert_equal(201, last_response.status, 'Status must be 201 Created')

    matches_result['matches'].each do |match|
      assert_equal(2, match['scores'].to_a.count, 'Match should have two score entries')
    end

    # Cleanup data from the bottom up
    created_tournament = Tournament.get(matches_result['tournament']['id'])

    created_tournament.matches.scores.each do |score|
      score.destroy
    end

    created_tournament.reload
    created_tournament.matches.each do |match|
      match.destroy
    end

    created_tournament.reload
    created_tournament.players.each do |player|
      player.destroy
    end

    created_tournament.reload
    created_tournament.destroy
  end
end