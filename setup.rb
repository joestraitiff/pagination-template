# create and seed the database
#
require 'sequel'

DB = Sequel.connect(ENV["DATABASE_URL"])

# create a table to hold the apps
DB.create_table :apps do
  primary_key :id
  String :name
end

apps = DB[:apps]

# seed a bunch of apps
(1..99).each do |num|
  apps.insert(name: 'my-app-%03i' % num)
end

puts "Created #{apps.count} apps."
