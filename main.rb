# execute like this:
# ruby main.rb

TIMESTRING = Time.now.strftime("%Y%m%d_%H%M")
LOCAL_DB_NAME = "tmp_db_#{TIMESTRING}"
TMP_FILENAME = "tmp/#{TIMESTRING}"

def tmp_filename
  create_tmp_dir
  "#{TMP_FILENAME}.sql"
end

def execute(command)
  puts "Command will be executed:"
  puts command
  `#{command}`
end

class Replacer
  def initialize(host, dbname, user, pass)
    @localdb_host = host
    @localdb_name = dbname
    @localdb_user = user
    @localdb_pass = pass
  end

  def proceed(from, to)
    execute("./bin/srdb.cli.php --host=#{@localdb_host} --name=#{@localdb_name} --user=#{@localdb_user} --pass=#{@localdb_pass} --search='#{from}' --replace='#{to}'")
  end
end

def create_tmp_dir
  unless File.exists?('tmp')
    Dir.mkdir 'tmp'
  end
end

class DB
  def initialize(source_opts={}, local_opts={})
    @source_dbname = source_opts.fetch(:dbname)
    @source_hostname = source_opts.fetch(:hostname)
    @source_username = source_opts.fetch(:username)
    @source_password = source_opts.fetch(:password)

    @tmp_hostname = "localhost"
    @tmp_dbname = LOCAL_DB_NAME
    @tmp_dbuser = local_opts.fetch(:username)
    @tmp_dbpass = local_opts.fetch(:password)

    @replacer = Replacer.new(@tmp_hostname, @tmp_dbname, @tmp_dbuser, @tmp_dbpass)
  end

  def import_remote_to_tmp(filename=nil)
    if filename.nil?
      filename = tmp_filename
    end
    execute("mysqldump -u #{@source_username} --password=#{@source_password} #{@source_dbname} -h #{@source_hostname} --ssl-mode=disabled > #{filename}")
    execute("mysql -u #{@tmp_dbuser} --password=#{@tmp_dbpass} -e 'CREATE DATABASE #{@tmp_dbname}'")
    execute("mysql -u #{@tmp_dbuser} --password=#{@tmp_dbpass} #{@tmp_dbname} < #{filename}")
  end

  def dump(export_name=nil)
    if export_name.nil?
      export_name = "export.#{Time.now.strftime("%Y%m%d_%H%M")}.sql"
    end
    execute("mysqldump -u #{@tmp_dbuser} --password=#{@tmp_dbpass} #{@tmp_dbname} -h #{@tmp_hostname} > #{export_name}")
  end

  def search_and_replace(from, to)
    @replacer.proceed(from, to)
  end
end

require 'dotenv/load' # loads the .env file it finds

source_database = ENV['SOURCE_DATABASE_NAME']
source_username = ENV['SOURCE_DATABASE_USERNAME']
source_password = ENV['SOURCE_DATABASE_PASSWORD']
source_hostname = ENV['SOURCE_DATABASE_HOSTNAME']
# For temp db to search and replace stuff:
localdb_user = ENV['LOCAL_DATABASE_USERNAME']
localdb_pass = ENV['LOCAL_DATABASE_PASSWORD']
localdb_host = 'localhost'
# For destination db into which we will import the db:
dest_database = ENV['DEST_DATABASE_NAME']
dest_username = ENV['DEST_DATABASE_USERNAME']
dest_password = ENV['DEST_DATABASE_PASSWORD']
dest_hostname = ENV['DEST_DATABASE_HOSTNAME']

db = DB.new(
  {dbname: source_database, hostname: source_hostname, username: source_username, password: source_password},
  {username: localdb_user, password: localdb_pass}
)

res = execute("mysql -u #{localdb_user} --password=#{localdb_pass} -e 'CREATE DATABASE #{tmp_dbname}'")

db.dump("tythonic.sql")
