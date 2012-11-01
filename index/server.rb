require "redis"
require "sinatra"
require "sinatra/reloader" if development?
require "json"

$pages_db = Redis.new()
#set :erb, layout: :layout

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
