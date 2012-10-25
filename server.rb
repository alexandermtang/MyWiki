require "sinatra"
require "sinatra/reloader" if development?
require "redis"

enable :sessions
$login_db = Redis.new

get "/" do
  erb :login
end

post "/login" do
  if $login_db.get("#{params["username"]}") == params["password"]
    session["logged_in"] = true
    session["username"] = params["username"]
    redirect to "/special"
  else
    redirect to "/"
  end
end

get "/logout" do
  session["logged_in"] = false
  session["username"] = ""
  redirect "/"
end

before "/special" do
  redirect to "/" unless session["logged_in"]
end

get "/special" do
  erb :logout,
    locals: {username: session["username"]}
end

get "/register" do
  erb :register
end

post "/register" do
  $login_db.set(params["username"], params["password"])
  redirect to "/special"
end
