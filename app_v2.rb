require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'
require 'data_mapper'
require File.dirname(__FILE__) + '/models/model.rb'

before do
	if request.post? || request.put?
	  request.body.rewind
	  @request_payload = JSON.parse request.body.read
	end
end

namespace '/v2' do
  # Users
  get     '/users',                   &show_users
  get     '/users/:id',               &show_user_detail
  get     '/users/search/:username',  &find_user_by_username
  post    '/users',                   &create_user
  put     '/users/:id',               &update_user
  delete  '/users/:id',               &delete_user
  
  # Tournaments
  get     '/tournaments',       &show_tournaments
  get     '/tournaments/:id',   &show_tournament_detail
  post    '/tournaments',       &create_tournament
  put     '/tournaments/:id',   &uptade_tournament
  delete  '/tournaments/:id',   &delete_tournament
  
  # Players
  get     '/players',       &show_players
  get     '/players/:id',   &show_player_detail
  post    '/players',       &create_player
  put     '/players/:id',   &uptade_player
  delete  '/players/:id',   &delete_player
  
  # Matches
  get     '/matches',       &show_matches
  get     '/matches/:id',   &show_match_detail
  post    '/matches',       &create_match
  put     '/matches/:id',   &uptade_match
  delete  '/matches/:id',   &delete_match
  
  # Scores
  get     '/scores',       &show_scores
  get     '/scores/:id',   &show_score_detail
  post    '/scores',       &create_score
  put     '/scores/:id',   &uptade_score
  delete  '/scores/:id',   &delete_score
end