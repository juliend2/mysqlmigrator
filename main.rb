# Execute like this:
#
# bundle exec ruby main.rb

require 'forwardable'

TIMESTRING = Time.now.strftime("%Y%m%d_%H%M%S")
LOCAL_DB_NAME = "tmp_db_#{TIMESTRING}"
TMP_FILENAME = "tmp/#{TIMESTRING}"

def tmp_filename
  create_tmp_dir
  "#{TMP_FILENAME}.sql"
end

module Syscalls
  def execute(command)
    puts "Command will be executed:"
    puts command
    `#{command}`
  end
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

class Dump
  include Syscalls

  def initialize(file_path)
    @file_path = file_path
  end

  def to_s
    @file_path
  end
end

class DB
  include Syscalls
  extend Forwardable

  def initialize(opts={})
    @config = DBConfig.new opts
    @tmp_filename = "#{srand}.sql"
    @tmp_filepath = "tmp/#{@tmp_filename}"
  end

  def_delegators :@config, :name, :username, :password, :hostname

  def <<(db_or_dump)
    if db_or_dump.is_a?(Dump)
      import_dump(db_or_dump)
    elsif db_or_dump.is_a?(DB)
      import_db(db_or_dump)
    else
      raise "Unknown data type to import."
    end
  end

  def dump(file_name)
    d = Dump.new(file_name)
  end

  private

  # Imports the Dump object into the current DB
  #
  # dump - behaves like a String in a string context
  def import_dump(dump)
    execute("mysql -u #{self.username} --password=#{self.password} #{self.name} -h #{self.hostname} < #{dump}")
  end

  def import_db(db)
    # In two steps, to be able to debug more easily:
    execute("mysqldump -u #{db.username} --password=#{db.password} #{db.name} -h #{db.hostname} --ssl-mode=disabled > #{@tmp_filepath}")
    execute("mysql -u #{self.username} --password=#{self.password} #{self.name} -h #{self.hostname} < #{@tmp_filepath}")
  end
end


class TmpDB < DB
  def initialize(opts={})
    opts[:name] = opts.fetch(:name, LOCAL_DB_NAME)
    opts[:hostname] = opts.fetch(:hostname, 'localhost')
    super(opts)
    execute("mysql -u #{self.username} --password=#{self.password} -h #{self.hostname} -e 'CREATE DATABASE #{self.name}'")
  end
end


class DBController
  def initialize(sourcedb, localdb)
    @sourcedb = sourcedb
    @localdb = localdb
    @replacer = Replacer.new(@localdb)
  end

  def import_remote_to_tmp(filename=nil)
    if filename.nil?
      filename = tmp_filename
    end
    execute("mysqldump -u #{@sourcedb.username} --password=#{@sourcedb.password} #{@sourcedb.name} -h #{@sourcedb.hostname} --ssl-mode=disabled > #{filename}")
    execute("mysql -u #{@localdb.username} --password=#{@localdb.password} -e 'CREATE DATABASE #{@localdb.name}'")
    execute("mysql -u #{@localdb.username} --password=#{@localdb.password} #{@localdb.name} < #{filename}")
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
