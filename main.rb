# execute like this:
# ruby main.rb

require 'dotenv/load' # loads the .env file it finds

database = ENV['DATABASE_NAME']
username = ENV['DATABASE_NAME']
password = ENV['DATABASE_PASSWORD']
hostname = ENV['DATABASE_HOSTNAME']
output_filename = ENV['OUTPUT_FILENAME']

result = `mysqldump -u #{username} --password=#{password} #{database} -h #{hostname} --ssl-mode=disabled > #{output_filename}`

