require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'
require 'data_mapper'
require File.dirname(__FILE__) + '/models/model.rb'

STATUS_SUCCESS = 'success'
STATUS_FAILED = 'failed'

before do
	if request.post? || request.put?
	  request.body.rewind
	  @request_payload = JSON.parse request.body.read
	end
end

# Users

get '/users' do
	@users = User.all
	@users.to_json
end

get '/users/:username' do
	@users = User.all(:username.like => "%#{params[:username]}%")
	@users.to_json
end

post '/users' do

	@user = User.new
	@user.username = @request_payload['username']
	@user.first_name = @request_payload['first_name'] if @request_payload.has_key?('first_name')
	@user.last_name = @request_payload['last_name'] if @request_payload.has_key?('last_name')

	result = process_save(@user)
	result.to_json

end

post '/tournaments/:id/players' do
	@tournament = Tournament.get(params[:id])

	users = @request_payload['users']

	users.each do |user_id|
		if Player.unique? params[:id], user_id
			user = User.get(user_id)
			@tournament.users << user
		end
	end

	result = process_save(@tournament)
	result.to_json	
end

get '/tournaments/:id/players' do
	tournament = Tournament.get(params[:id])

	resource = { :tournament => tournament, :players => tournament.users }

	resource.to_json
end

get '/tournaments/:id/matches' do
	tournament = Tournament.get(params[:id])

	resource = get_tournament_scores(tournament)
	resource.to_json
end

post '/tournaments/:id/matches' do
	@tournament = Tournament.get(params[:id])
	
	if @tournament.players.empty?
		return { :status => 'error', :message => 'Tournament has no players' }
	end

	if @request_payload.has_key?('scores')

		@match = Match.new

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

			@match.scores << score
		end

		@tournament.matches << @match
	end

	if validate_match(@tournament, users)
		if @tournament.save
			result = get_tournament_scores @tournament
		else
			result = { :status => 'error', :message => @tournament.errors.to_hash }
		end
	else
		result = { :status => 'error', :message => 'Match already exists' }
	end

	result.to_json
end

post '/tournaments' do
	@tournament = Tournament.new
	@tournament.name = @request_payload['name']

	if @request_payload.has_key?('users')
		users = @request_payload['users']

		users.each do |user_id|
			user = User.get(user_id)
			@tournament.users << user
		end
	end

	result = process_save @tournament
	result.to_json
end

get '/tournaments' do
  tournaments = Tournament.all
  tournaments.to_json
end

# Generic method for processing simple save actions
# @param resource Model - de model that needs to be saved
# @return result Hash - the message that will be displayed to the user
def process_save(resource)
	if resource.save
		{:status => STATUS_SUCCESS, :resource => resource}
	else
		{:status => STATUS_FAILED, :errors => resource.errors.to_hash}
	end
end

# Validates that the match between the two user hasn't been saved before
# @param tournament Model - the tournament where the match takes place
# @param users Array - the two players in the match
# @return Boolean - true if the match doesn't exist, false otherwise
def validate_match(tournament, users)
	tournament.matches.each do | match |
		scores = match.scores.all(:user_id => users)
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