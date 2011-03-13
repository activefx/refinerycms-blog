class BlogCategory
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug
  include Mongoid::Search

  field :title, :type => String

  #has_many :categorizations
  #has_many :posts, :through => :categorizations, :source => :blog_post
  references_and_referenced_in_many :blog_posts #, :default_order => :published_at.desc

  #acts_as_indexed :fields => [:title]
  search_in :title

  validates :title, :presence => true, :uniqueness => true

  #has_friendly_id :title, :use_slug => true
  slug :title, :index => true

  def post_count
    blog_posts.select(&:live?).count
  end

  def latest_blog_posts
    blog_posts.desc(:published_at)
  end

  # Extractable Methods

  def self.table_exists?
    included_modules.include? Mongoid::Document
  end

  def self.column_names
    fields
  end

  def self.base_class
    self
  end

end

