# execute like this:
# ruby main.rb

require 'dotenv/load' # loads the .env file it finds

database = ENV['DATABASE_NAME']
username = ENV['DATABASE_USERNAME']
password = ENV['DATABASE_PASSWORD']
hostname = ENV['DATABASE_HOSTNAME']
output_filename = ENV['OUTPUT_FILENAME']
# For temp db to search and replace stuff:
localdb_user = ENV['LOCAL_DATABASE_USERNAME']
localdb_pass = ENV['LOCAL_DATABASE_PASSWORD']

result = `mysqldump -u #{username} --password=#{password} #{database} -h #{hostname} --ssl-mode=disabled > #{output_filename}`

time = Time.now.strftime("%Y%m%d_%H%M")
tmp_dbname = "tmp_db_#{time}"

res = `mysql -u #{localdb_user} --password=#{localdb_pass} -e "CREATE DATABASE #{tmp_dbname}"`


