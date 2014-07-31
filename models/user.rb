DataMapper.setup(:default, 'mysql://root:pass21@localhost/tournaments')

class User

	include DataMapper::Resource

	property :id, 				Serial
	property :username, 		String, :required => true, :length => 0..24
	property :hashed_password, 	String, :required => true
	property :email, 			String
	property :first_name, 		String, :length => 0..32
	property :last_name, 		String, :length => 0..32
	property :created_at, 		DateTime
	property :updated_at,		DateTime

	# has n, :tasks
end

DataMapper.auto_upgrade!