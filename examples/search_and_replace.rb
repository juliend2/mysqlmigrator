sourcedb = DBConfig.new(
  name: ENV['SOURCE_DATABASE_NAME'],
  hostname: ENV['SOURCE_DATABASE_HOSTNAME'],
  username: ENV['SOURCE_DATABASE_USERNAME'],
  password: ENV['SOURCE_DATABASE_PASSWORD'],
)


localdb = DBConfig.new(
  name: LOCAL_DB_NAME,
  hostname: 'localhost',
  username: ENV['LOCAL_DATABASE_USERNAME'],
  password: ENV['LOCAL_DATABASE_PASSWORD'],
)


db = DB.new(
  sourcedb,
  localdb
)

db.import_remote_to_tmp()

db.search_and_replace("https:\/\/www.example.com", "http:\/\/dev.example.tk")
db.search_and_replace("https://www.example.com", "http://dev.example.tk")
db.search_and_replace("www.example.com", "dev.example.tk")

db.dump("example.dev.sql")

