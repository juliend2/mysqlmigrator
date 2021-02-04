# Execute like this:
#
# bundle exec ruby main.rb

require 'dotenv/load'


TIMESTRING = Time.now.strftime("%Y%m%d_%H%M")
LOCAL_DB_NAME = "tmp_db_#{TIMESTRING}"
LOCAL_DB_HOST = "localhost"
TMP_FILENAME = "tmp/#{TIMESTRING}"

def tmp_filename
  create_tmp_dir
  "#{TMP_FILENAME}.sql"
end

module Executable
  def execute(command_str)
    puts "Going to execute:"
    puts command_str
    `#{command_str}`
  end
end

class Replacer
  include Executable

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

class Dump
  include Executable

  def initialize(file_path)
    @file_path = file_path
  end

  def to_s
    @file_path
  end

  def <<(db)
    case db
    when Database then
      puts "Importing Database into dump..."
      execute("mysqldump -u #{db.username} --password=#{db.password} #{db.name} -h #{db.hostname} > #{@file_path}")
    else
      raise "Unsupported type"
    end
  end
end

class Database
  include Executable

  def initialize(opts={})
    @config = DBConfig.new(opts)
  end

  def name
    @config.name
  end

  def username
    @config.username
  end

  def password
    @config.password
  end

  def hostname
    @config.hostname
  end

  def <<(db_or_dump)
    case db_or_dump
    when Database then import_db(db_or_dump)
    when Dump then import_dump(db_or_dump)
    else raise "Unsupported type"
    end
  end

  def >>(db_or_dump)
    case db_or_dump
    when String then export_to_dump(Dump.new(db_or_dump))
    else raise "Unsupported type"
    end
  end

  def replace!(from, to)
    replacer = Replacer.new(@config)
    replacer.proceed(from, to)
  end

  protected
  
  def import_db(db)
    puts "importing db..."
    puts db.inspect
  end

  def import_dump(dump)
    puts "importing dump..."
    execute("mysql -u #{self.username} --password=#{self.password} -h #{self.hostname} #{self.name} < #{dump}")
  end

  def export_to_dump(dump)
    dump << self
  end
end

class TmpDatabase < Database
  def initialize(opts={})
    opts[:name] = LOCAL_DB_NAME
    opts[:hostname] = LOCAL_DB_HOST
    super(opts)
  end

  def import_dump(dump)
    puts "Creating the tmp DB"
    execute("mysql -u #{self.username} --password=#{self.password} -e 'CREATE DATABASE #{self.name}'")
    super(dump)
  end

end

# sourcedb = Database.new(
#   name: ENV['SOURCE_DATABASE_NAME'],
#   hostname: ENV['SOURCE_DATABASE_HOSTNAME'],
#   username: ENV['SOURCE_DATABASE_USERNAME'],
#   password: ENV['SOURCE_DATABASE_PASSWORD'],
# )


localdb = TmpDatabase.new(
  username: ENV['LOCAL_DATABASE_USERNAME'],
  password: ENV['LOCAL_DATABASE_PASSWORD'],
)

# destdb = Database.new(
#   name: ENV['DEST_DATABASE_NAME'],
#   hostname: ENV['DEST_DATABASE_HOSTNAME'],
#   username: ENV['DEST_DATABASE_USERNAME'],
#   password: ENV['DEST_DATABASE_PASSWORD'],
# )

dump = Dump.new('djalbert_wpdb1.sql')

localdb << dump

localdb.replace! "davidjalbert.com", "staging.davidjalbert.com"

localdb >> "djalbert_staging.sql"
