require 'rubygems'
require 'dm-core'
require 'haml'
require 'sass'
require 'sinatra'

require './models/page'

DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, "mysql://#{ENV['MYSQL_USER']}:#{ENV['MYSQL_PASSWORD']}@localhost/wiki")

class App < Sinatra::Base
  
  configure do
    enable :static
    set :public_folder, 'public'
    set :raise_errors, false 
    set :show_exceptions, true if development?
  end

  if ENV['WIKI_USER'] && ENV['WIKI_PASSWORD']
    use Rack::Auth::Basic do |username, password|
      [username, password] == [ENV['WIKI_USER'], ENV['WIKI_PASSWORD']]
    end
  end

  get '/css/:name.css' do
    content_type :css
    sass params[:name].to_sym
  end

  get '/' do
    redirect '/name/Home'
  end

  get '/all' do
    haml :all,
         :locals => {
           :title => 'All Pages',
           :pages => Page.all
         }
  end

  get '/new' do
    haml :new,
         :locals => {
           :title => 'New Page',
           :name => ''
         }
  end

  get '/new/:name' do
    haml :new,
         :locals => {
           :title => 'New Page',
           :name => params[:name]
         }
  end

  post '/new' do
    page = Page.new
    page.name = params[:name]
    page.parent = params[:parent]
    page.text = params[:text]
    page.save

    redirect "/name/#{page.name}"
  end

  get '/edit/:id' do
    haml :edit,
         :locals => {
           :title => 'Edit Page',
           :page => Page.get(params[:id].to_i)
         }
  end

  post '/delete/:id' do
    Page.get(params[:id].to_i).destroy!

    redirect '/'
  end

  get '/page/:id' do
    page = Page.get params[:id].to_i
    redirect '/' if !page

    haml :page,
         :locals => {
           :title => page.name,
           :page => page,
           :prev_page => page.prev,
           :next_page => page.next
         }
  end

  get '/name/:name' do
    page = Page.first(:name => params[:name], :order => :id.desc)
    redirect "/new/#{params[:name]}" if !page

    haml :page,
         :locals => {
           :title => page.name,
           :page => page,
           :prev_page => page.prev,
           :next_page => page.next
         }
  end

  helpers do
    include Rack::Utils
    alias_method :html, :escape_html
  end
end
