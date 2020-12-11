# Execute like this:
#
# bundle exec ruby main.rb

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
  def initialize(dbconfig)
    @dbconfig = dbconfig
  end

  def proceed(from, to)
    execute("./bin/srdb.cli.php --host=#{@dbconfig.hostname} --name=#{@dbconfig.name} --user=#{@dbconfig.username} --pass=#{@dbconfig.password} --search='#{from}' --replace='#{to}'")
  end
end

def create_tmp_dir
  unless File.exists?('tmp')
    Dir.mkdir 'tmp'
  end
end

class DBConfig
  def initialize(opts={})
    @name = opts.fetch(:name)
    @hostname = opts.fetch(:hostname)
    @username = opts.fetch(:username)
    @password = opts.fetch(:password)
  end

  attr_reader :name, :hostname, :username, :password
end

class DB
  def initialize(sourcedb, localdb)
    @sourcedb = sourcedb
    @localdb = localdb
    @replacer = Replacer.new(@localdb)
  end

  def import_remote_to_tmp()
		filename = tmp_filename
    execute("mysqldump -u #{@sourcedb.username} --password=#{@sourcedb.password} #{@sourcedb.name} -h #{@sourcedb.hostname} --ssl-mode=disabled > #{filename}")
    execute("mysql -u #{@localdb.username} --password=#{@localdb.password} -e 'CREATE DATABASE #{@localdb.name}'")
		#self.search_replace_in_file('utf8mb4_0900_ai_ci', 'utf8mb4_general_ci')
    execute("mysql -u #{@localdb.username} --password=#{@localdb.password} #{@localdb.name} < #{filename}")
  end

  def search_replace_in_file(search, replace)
    filename = tmp_filename
    outdata = File.read(filename).gsub(search, replace)

    File.open(filename, 'w') do |out|
      out << outdata
    end
  end

  def dump(export_name=nil)
    if export_name.nil?
      export_name = "export.#{Time.now.strftime("%Y%m%d_%H%M")}.sql"
    end
    execute("mysqldump -u #{@localdb.username} --password=#{@localdb.password} #{@localdb.name} -h #{@localdb.hostname} > #{export_name}")
  end

  def search_and_replace(from, to)
    @replacer.proceed(from, to)
  end

  def import(dump, opts={})
    destdb = opts.fetch(:to)
    execute("mysql -u #{destdb.username} --password=#{destdb.password} -h #{destdb.hostname} #{destdb.name} < #{dump}")
  end
end

require 'dotenv/load' # loads the .env file it finds

sourcedb = DB.new(
  name: ENV['SOURCE_DATABASE_NAME'],
  hostname: ENV['SOURCE_DATABASE_HOSTNAME'],
  username: ENV['SOURCE_DATABASE_USERNAME'],
  password: ENV['SOURCE_DATABASE_PASSWORD'],
)

localdb = TmpDB.new(
  username: ENV['LOCAL_DATABASE_USERNAME'],
  password: ENV['LOCAL_DATABASE_PASSWORD'],
)

destdb = DB.new(
  name: ENV['DEST_DATABASE_NAME'],
  hostname: ENV['DEST_DATABASE_HOSTNAME'],
  username: ENV['DEST_DATABASE_USERNAME'],
  password: ENV['DEST_DATABASE_PASSWORD'],
)

# db = DBController.new(
#   sourcedb,
#   localdb
# )
# 
# db.import_remote_to_tmp()
# 
# db.search_and_replace("https:\/\/www.tythonic.com", "http:\/\/ttthhnncc.tk")
# db.search_and_replace("https://www.tythonic.com", "http://ttthhnncc.tk")
# db.search_and_replace("www.tythonic.com", "ttthhnncc.tk")
# 
# db.dump("tythonic.sql")
# 
# db.import("tythonic.sql", to: destdb)

localdb << sourcedb
