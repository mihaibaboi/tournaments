DataMapper.setup(:default, 'mysql://root:pass21@localhost/tournaments')

class Tournament

	include DataMapper::Resource

	property :id, 				Serial
	property :name, 			String
	property :created_at, 		DateTime
	property :updated_at,		DateTime

	# has n, :tasks
end

DataMapper.auto_upgrade!