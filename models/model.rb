DataMapper.setup(:default, 'mysql://tournament:pass21@localhost/tournaments')

class User

	include DataMapper::Resource

	property :id, 				Serial
	property :username, 		String, :required => true, :length => 0..24
	property :hashed_password, 	String
	property :email, 			String
	property :first_name, 		String, :length => 0..32
	property :last_name, 		String, :length => 0..32
	property :created_at, 		DateTime
	property :updated_at,		DateTime

	has n, :players
	has n, :tournaments, :through => :players
end

class Tournament

	include DataMapper::Resource

	property :id, 			Serial
	property :name, 		String
	property :created_at, 	DateTime
	property :updated_at,	DateTime

	has n, :players
	has n, :users, :through => :players
	has n, :matches
  has n, :scores, :through => :matches
end

class Player

	include DataMapper::Resource

	property :id, 				Serial
	property :tournament_id, 	Integer
	property :user_id, 			Integer

	belongs_to :user, :key => true
	belongs_to :tournament, :key => true

	def self.unique?(tournament_id, user_id)
		player = Player.all(:tournament_id => tournament_id, :user_id => user_id)
		player.empty?
	end

end

class Match

	include DataMapper::Resource

	property :id, 				Serial
	property :tournament_id, 	Integer
	property :created_at, 		DateTime
	property :updated_at, 		DateTime

	has n, :scores
	belongs_to :tournament
end

class Score

	include DataMapper::Resource

	property :id, 			Serial
	property :match_id, 	Integer
	property :user_id, 		Integer
	property :games_won,	Integer
	property :points, 		Integer
	property :created_at, 	DateTime
	property :updated_at, 	DateTime

	belongs_to :match
	belongs_to :user
  has 1, :tournament, :through => :match

	def self.unique? (match_id, user_id)
		score = Score.all(:match_id => match_id, :user_id => user_id)
		score.empty?
	end
end


DataMapper.auto_upgrade!
