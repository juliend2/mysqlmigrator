# execute like this:
# ruby main.rb

require 'dotenv/load' # loads the .env file it finds

database = ENV['SOURCE_DATABASE_NAME']
username = ENV['SOURCE_DATABASE_USERNAME']
password = ENV['SOURCE_DATABASE_PASSWORD']
hostname = ENV['SOURCE_DATABASE_HOSTNAME']
output_filename = ENV['OUTPUT_FILENAME']
# For temp db to search and replace stuff:
localdb_user = ENV['LOCAL_DATABASE_USERNAME']
localdb_pass = ENV['LOCAL_DATABASE_PASSWORD']

time = Time.now.strftime("%Y%m%d_%H%M")
tmp_dbname = "tmp_db_#{time}"


def execute(command)
  puts "Command will be executed:"
  puts command
  `#{command}`
end

# do the things:
result = execute("mysqldump -u #{username} --password=#{password} #{database} -h #{hostname} --ssl-mode=disabled > #{output_filename}")

res = execute("mysql -u #{localdb_user} --password=#{localdb_pass} -e 'CREATE DATABASE #{tmp_dbname}'")

res = execute("mysql -u #{localdb_user} --password=#{localdb_pass} #{tmp_dbname} < #{output_filename}")
