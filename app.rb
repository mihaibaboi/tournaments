require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'
require 'data_mapper'
require File.dirname(__FILE__) + '/models/model.rb'

STATUS_SUCCESS = 'success'
STATUS_FAILED = 'failed'
STATUS_CREATED = 'created'

before do
	if request.post? || request.put?
	  request.body.rewind
	  @request_payload = JSON.parse request.body.read
	end
end

show_users = lambda do
  users = User.all
  users.to_json
end

find_by_username = lambda do
  users = User.all(:username.like => "%#{params[:username]}%")
  users.to_json
end

show_user_detail = lambda do
  user = User.get(params[:id])
  user.to_json
end

create_user = lambda do
  user = User.new
  user.username = @request_payload['username']
  user.first_name = @request_payload['first_name'] if @request_payload.has_key?('first_name')
  user.last_name = @request_payload['last_name'] if @request_payload.has_key?('last_name')

  result = process_save(user)
  result.to_json
end

add_players_in_tournament = lambda do
  tournament = Tournament.get(@request_payload['tournament_id'])

  users = @request_payload['users']

  users.each do |user_id|
    if Player.unique?(params[:id], user_id)
      user = User.get(user_id)
      tournament.users << user
    end
  end

  if tournament.save
    status 201
    resource = { :tournament => tournament, :players => tournament.users }
    result = { :status => STATUS_CREATED, :resource => resource }
  else
    status 500
    result = { :status => STATUS_FAILED, :message => tournament.errors.to_hash }
  end
  result.to_json
end

show_players_in_tournament = lambda do
  tournament = Tournament.get(params[:id])

  resource = { :tournament => tournament, :players => tournament.users }

  resource.to_json
end

show_matches_in_tournament = lambda do
  tournament = Tournament.get(params[:id])

  resource = get_tournament_scores(tournament)
  resource.to_json
end

log_match_in_tournament = lambda do
  tournament = Tournament.get(@request_payload['tournament_id'])

  if tournament.players.empty?
    return { :status => 'error', :message => 'Tournament has no players' }
  end

  unless @request_payload.has_key?('scores')
    status 400
    return { :status => 'error', :message => 'Payload should contain the :scores key' }
  end

  match = Match.new

  if @request_payload['scheduled_at']
    match.scheduled_at = @request_payload['scheduled_at']
  end

  scores = @request_payload['scores']
  sorted = scores.sort_by { | score_hashes | score_hashes['games_won'] }

  points = 0
  users = []
  sorted.each do | result |

    users << result['user_id']

    score = Score.new
    score.user_id = result['user_id']
    score.games_won = result['games_won']
    score.points = points
    points += 1

    match.scores << score
  end

  if validate_match(tournament, users)
    tournament.matches << match
    if tournament.save
      status 201
      result = get_tournament_scores(tournament)
    else
      status 400
      result = { :status => 'error', :message => tournament.errors.to_hash }
    end
  else
    status 400
    result = { :status => 'error', :message => 'Match already exists' }
  end

  result.to_json
end

create_tournament = lambda do
  tournament = Tournament.new
  tournament.name = @request_payload['name']

  if @request_payload.has_key?('users')
    users = @request_payload['users']

    users.each do |user_id|
      user = User.get(user_id)
      tournament.users << user
    end
  end

  result = process_save(tournament)
  result.to_json
end

show_tournaments = lambda do
  tournaments = Tournament.all
  tournaments.to_json
end

update_scores = lambda do
  match = Match.get(params[:id])

  unless match.kind_of?(Match)
    status 404
    return { status: 'error', message: 'This match is not in the database' }.to_json
  end

  if @request_payload.has_key?('scores')
    @request_payload['scores'].each do |input_score|
      score = match.scores.first(:user_id => input_score['user_id'])

      unless score.kind_of?(Score)
        status 404
        return { status: 'error', message: 'Could not find the given user in this match' }.to_json
      end

      score.games_won = input_score['games_won']
      match.scores << score
    end
  else
    status 400
    return { :status => 'error', :message => 'Request body is invalid' }
  end

  if match.save
    status 201
    result = { :match => match, :scores => match.scores }.to_json
  else
    status 500
    result = { :status => 'error', :message => match.errors.to_hash }
  end

  result
end

delete_user = lambda do
  user = User.get(params[:id])
  result = process_delete user
  result.to_json
end

delete_tournament = lambda do
  tournament = Tournament.get(params[:id])

  result = process_delete tournament
  result.to_json
end

delete_match = lambda do
  match = Match.get(params[:id])

  result = process_delete match
  result.to_json
end

delete_score = lambda do
  score = Score.get(params[:id])

  result = process_delete score
  result.to_json
end

delete_player = lambda do
  player = Player.get(params[:id])

  result = process_delete player
  result.to_json
end

update_match = lambda do

  match = Match.get(params[:id])

  unless match.kind_of?(Match)
    status 404
    return { status: 'error', message: 'This match is not in the database' }.to_json
  end

  if @request_payload.has_key? 'match'
    match.attributes = @request_payload['match']
  end

  result = process_save(match)
  result.to_json
end

get    '/users',                    &show_users
get    '/users/:id',                &show_user_detail
get    '/users/search/:username',   &find_by_username
post   '/users',                    &create_user
delete '/users/:id',                &delete_user

get    '/tournaments/:id/players',  &show_players_in_tournament
post   '/players',                  &add_players_in_tournament
delete '/players/:id',              &delete_player

get    '/tournaments/:id/matches',  &show_matches_in_tournament
post   '/matches',                  &log_match_in_tournament
put    '/matches/:id',              &update_match
delete '/matches/:id',              &delete_match

get    '/tournaments',              &show_tournaments
post   '/tournaments',              &create_tournament
delete '/tournaments/:id',          &delete_tournament

put    '/matches/:id/scores',       &update_scores
delete '/scores',                   &delete_score

# Generic method for processing simple save actions
# @param resource Model - de model that needs to be saved
# @return result Hash - the message that will be displayed to the user
def process_save(resource)
	if resource.save
    status 201
		{:status => STATUS_CREATED, :resource => resource}
	else
		{:status => STATUS_FAILED, :errors => resource.errors.to_hash}
	end
end

# Validates that the match between the two user hasn't been saved before
# @param tournament Model - the tournament where the match takes place
# @param users Array - the two players in the match
# @return Boolean - true if the match doesn't exist, false otherwise
def validate_match(tournament, users)
	tournament.matches.each do | existing_match |
		scores = existing_match.scores.all(:user_id => users)

		if scores.count == 2
			return false
		end
	end
	return true
end

# This method is used to keep the code DRY
# @param tournament Model - the tournament for which we are gettting all the data
# @return resource Hash - the complete resource with tournament, matches and scores
def get_tournament_scores(tournament)
	matches = []
	tournament.matches.each do |result|
		match = { :match => result, :scores => result.scores }
		matches << match
	end

	resource = { :tournament => tournament, :matches => matches }
end

def process_delete(resource)
  if resource.destroy
    status 204
    result = {}
  else
    status 500
    result = { status: 'error', message: resource.errors.to_hash }
  end

  result
end