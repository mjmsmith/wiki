require 'rubygems'
require 'dm-core'
require 'rdiscount'

class Page
  include DataMapper::Resource

  storage_names[:default] = 'page'

  property :id,         Serial
  property :name,       String
  property :parent,     String
  property :text,       String
  property :time_stamp, DateTime
  
  before :save do
    self.text.gsub! "\r\n", "\n"
    self.time_stamp = Time.now
  end
  
  def self.all_names
    repository(:default).adapter.select('select distinct name from page')
  end
  
  def html
    markdown = self.text.gsub /\[\[(.*?)\]\]/, '<a href="/name/\1">\1</a>'

    RDiscount.new(markdown).to_html
  end

  def prev
    Page.first(:name => self.name, :id.lt => self.id, :order => :id.desc)
  end
  
  def next
    Page.first(:name => self.name, :id.gt => self.id, :order => :id.asc)
  end
end
