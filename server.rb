require "redis"
require "sinatra"
require "sinatra/reloader" if development?
require "json"

enable :sessions

$pages_db = Redis.new

def get_pages
  pages = []
  $pages_db.hkeys("pagehash").each do |page_title|
    pages << $pages_db.hget("pagehash", page_title)
  end

  return pages
end

get "/" do
  pages = get_pages()
  erb :home,
    locals: {pages: pages}
end

get "/add_entry" do
  erb :add_entry
end

post "/add_entry" do
  if $pages_db.hkeys("pagehash").include?(params["title"]) # ensures pages with same title
    redirect to "/"                                        # are not added
  else
    page = {title: params["title"],
            author: params["author"],
            body: params["body"],
            date_added: Time.now,
            date_modified: nil,
            last_modified_by: nil}
    $pages_db.hset("pagehash", params["title"], page.to_json)
    redirect to "/"
  end
end

get "/view/:title" do
  page = $pages_db.hget("pagehash", params[:title])
  erb :view_entry,
    locals: {p: page}
end

get "/edit/:title" do
  page = $pages_db.hget("pagehash", params[:title])
  erb :add_entry,
    locals: {p: page}
end

post "/edit_entry" do
  page = JSON.parse($pages_db.hget("pagehash", params["title"]))
  page["body"] = params["body"]
  page["date_modified"] = Time.now
  page["last_modified_by"] = params["author"]
  $pages_db.hset("pagehash", page["title"], page.to_json)
  redirect to "/"
end

# user login stuff

get "/login" do
  erb :login
end

post "/login" do
  if $login_db.get("#{params["username"]}") == params["password"]
    session["logged_in"] = true
    session["username"] = params["username"]
    redirect to "/special"
  else
    redirect to "/login"
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
