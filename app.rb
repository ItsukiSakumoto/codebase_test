require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/cookies'
require 'pg'
require 'date'

# require 'Fileutils'
require 'pry'
enable :sessions


client = PG::connect(
  :host => "localhost",
  :user => 'codebase', :password => 'pass',
  :dbname => "postgres")


get '/form' do
    erb :form
end

post '/form_output' do
    @name = params[:name]
    @email = params[:email]
    @content = params[:content]

    erb :form_output
end






get "/" do

  if session[:id] == nil
    redirect to('login')
  end


  @posts = client.exec_params('SELECT * FROM accounts INNER JOIN posts ON posts.account_id = accounts.id ORDER BY posts.id DESC;')


  @likes = client.exec_params('select post_id From likes where account_id=$1;', [session[:id]]).map{ |i| i['post_id'].to_i }

  # sql = "SELECT count(*) from likes where post_id = $1;"
  # results = client.exec_params(sql, [paramas['id']])
  # @like_count = results[0]

    erb :home
end


post "/like" do
  @post_id = params[:id].to_i
  @account_id = session[:id]

  client.exec_params('INSERT INTO likes(post_id, account_id)
  VALUES($1, $2)', [@post_id, @account_id])

  redirect to('/')

end


post "/dislike" do
  @post_id = params[:id].to_i
  @account_id = session[:id]

  client.exec_params('delete from likes where post_id = $1 and account_id=$2; ', [@post_id, @account_id])

  redirect to('/')

end




get '/login' do
  # session[:id] = nil
  # @message = session[:message]
  # session[:message] = nil
  erb :login
end
# ログインデータ照合
post '/login' do
  @name = params[:name]
  @password = params[:password]
  sql = "select * from accounts where name = $1 and password = $2;"
  user = client.exec_params(sql,[@name, @password]).first
  if user
      session[:id] = user['id']
      session[:message] = "ログインしました"
      redirect to('/')
  else
      session[:id] = nil
      redirect to('/login')
  end
end


get "/signup" do
    erb :signup
end


post '/signup' do

  @name = params[:name]
  @email = params[:email]
  @password = params[:password]
  @icon = Time.now.to_s + '_' + params[:icon][:filename]

  client.exec_params('INSERT INTO accounts(name,email,password,icon)
  VALUES($1,$2,$3,$4)',[@name,@email,@password,@icon])

  FileUtils.mv(params[:icon][:tempfile], "./public/img/icons/#{@icon}")  #画像保存


  redirect to('/login')
end



get "/new_warn" do

  if session[:id] == nil
    redirect to('login')
  end

  erb :new_warn
end


post "/new_warn" do

    @point = params[:point]
    @reason = params[:reason]

    client.exec_params('INSERT INTO warnings(point, reason)
    VALUES($1, $2)', [@point, @reason])

    redirect to ('/warnings')
end


get "/warnings" do


    if session[:id] == nil
      redirect to('login')
    end

    @warnings = client.exec_params('SELECT * FROM warnings ORDER BY point ASC;')
    # @warn_counts = client.exec_params('SELECT count* FROM warnings
    # GROUP BY point;')

    @warn_counts = client.exec_params('SELECT point, COUNT(point) FROM warnings GROUP BY point ORDER BY COUNT(*) DESC;')

    erb :warnings
end


get "/new" do


  if session[:id] == nil
    redirect to('login')
  end

    erb :new
end


post "/new" do

  if session[:id] == nil
    redirect to('login')
  end

  @account_id = session[:id]
  @hunt_img = Time.now.to_s + '_' + params[:hunt_img][:filename]
  @kind = params[:kind]
  @length = params[:length]
  @weight = params[:weight]
  @point = params[:point]
  @detail = params[:detail]

  client.exec_params('INSERT INTO posts(account_id,hunt_img, kind, length, weight, point, detail)
  VALUES($1,$2,$3,$4,$5,$6,$7)', [@account_id, @hunt_img, @kind, @length, @weight, @point, @detail])

  client.exec_params('INSERT INTO points(point, kind) VALUES($1, $2)',[@point, @kind])

  FileUtils.mv(params[:hunt_img][:tempfile], "./public/img/posts_img/#{@hunt_img}")  #画像保存

  redirect to ('/')
end

get "/points" do


  if session[:id] == nil
    redirect to('login')
  end

  @points = client.exec_params('SELECT DISTINCT(point) FROM points INNER JOIN posts USING(point) GROUP BY point, points.kind, posts.kind ORDER BY point ASC;')
  # @kind_points = client.exec_params('SELECT kind FROM posts GROUP BY point, kind;')

  @kinds = client.exec_params('SELECT DISTINCT(point), kind FROM posts GROUP BY point, kind;')
  # puts "==============="
  erb :points
end

get '/search_word' do
  @searches = client.exec_params("SELECT * FROM accounts
    INNER JOIN posts ON posts.account_id = accounts.id where point like '%"+ params['search'] +"%' OR kind like '%"+ params['search'] +"%' OR name like '%"+ params['search'] +"%' OR detail like '%"+ params['search'] +"%' order by posts.id desc;")

    puts "==============="
    erb :search_word
end

get '/place_search' do
  @place_searches = client.exec_params("SELECT * FROM posts where point like '%"+ params['search'] +"%';")



    erb :place_search
end

get '/individual/:id' do

    # @post = params[:id]

    sql = "SELECT * FROM posts INNER JOIN accounts ON posts.account_id = accounts.id WHERE posts.id = $1;"

    results = client.exec_params(sql, [params['id']])

    @post = results[0]

    p "------"
    p @post["id"]
    p "------"

    erb :individual
end

get "/ranking" do

    @ranks = client.exec_params('SELECT * FROM posts INNER JOIN accounts ON posts.account_id = accounts.id GROUP BY accounts.id, posts.id, point;')


    # ORDER BY length DESC LIMIT 3

    erb :ranking
end


# get "/like/:id" do

#   sql = "SELECT * FROM posts INNER JOIN accounts ON posts.account_id = accounts.id WHERE posts.id = $1;"

#   results = client.exec_params(sql, [params['id']])

#   @post = results[0]


#   erb :like

# end

