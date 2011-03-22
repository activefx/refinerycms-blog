require 'mongoid_taggable_with_context'

class BlogPost
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Search
  include Mongoid::Slug
  include Mongoid::TaggableWithContext
  include Mongoid::TaggableWithContext::AggregationStrategy::RealTime
  include Mongoid::MultiParameterAttributes

  field :title, :type => String
  field :body, :type => String
  field :draft, :type => Boolean
  field :published_at, :type => DateTime

  default_scope desc(:published_at)
  #.first & .last will be reversed -- consider a with_exclusive_scope on these?

  referenced_in :administrator

  references_many :blog_comments, :dependent => :destroy, :inverse_of => :blog_post

  #has_many :categorizations
  #has_many :categories, :through => :categorizations, :source => :blog_category
  references_and_referenced_in_many :blog_categories

  taggable :separator => ','
  #after_save :set_category_relationship

  #acts_as_indexed :fields => [:title, :body]
  search_in :title, :body

  validates :title, :presence => true, :uniqueness => true
  validates :body,  :presence => true

  #has_friendly_id :title, :use_slug => true
  slug :title, :index => true

  scope :by_archive, lambda { |archive_date|
    #where(['published_at between ? and ?', archive_date.beginning_of_month, archive_date.end_of_month])
    where(:published_at.gt => archive_date.beginning_of_month).and(:published_at.lt => archive_date.end_of_month)
  }

  scope :by_year, lambda { |archive_year|
    #where(['published_at between ? and ?', archive_year.beginning_of_year, archive_year.end_of_year])
    where(:published_at.gt => archive_date.beginning_of_year).and(:published_at.lt => archive_date.end_of_year)
  }

  scope :all_previous, lambda { where(:published_at.lte => self.time_now_helper.beginning_of_month) }

  #scope :live, lambda { where( "published_at <= ? and draft = ?", Time.now, false) }
  # time comparisons are off
  scope :live, lambda { where(:published_at.lte => self.time_now_helper).and(:draft => false) }
  #scope :live, where(:draft => false)

  #scope :previous, lambda { |i| where(["published_at < ? and draft = ?", i.published_at, false]).limit(1) }
  scope :previous, lambda { |i| where(:published_at.lt => i.published_at).and(:draft => false).limit(1) }
  # next is now in << self

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

  def self.per_page
    15
  end

  # Time comparisons are off by four hours
  # not sure what's causing it yet
  def self.time_now_helper
    Time.now + 4.hours
  end

  def next
    BlogPost.next(self).first
  end

  def prev
    BlogPost.previous(self).first
  end

  def live?
    return true if published_at.nil? and !draft
    !draft and published_at <= self.class.time_now_helper
  end

#  def category_ids=(ids)
#    self.categories = ids.reject{|id| id.blank?}.collect {|c_id|
#      BlogCategory.find(c_id.to_i) rescue nil
#    }.compact
#  end

  def category_ids=(ids)
    ids.each do |category_id|
      blog_categories << BlogCategory.find(category_id)
    end
  end

  def category_ids
    blog_category_ids
  end

  class << self
#    def with_exclusive_scope(query)
#      query = where(query) if query.is_a?(Hash)
#      yield query
#    end

    def next current_record
      #where(["published_at > ? and draft = ?", current_record.published_at, false]).order("published_at ASC")
      unscoped.where(:published_at.gt => current_record.published_at).and(:draft => false).asc(:published_at)
    end

    def comments_allowed?
      RefinerySetting.find_or_set(:comments_allowed, true, {
        :scoping => 'blog'
      })
    end

    def uncategorized
      BlogPost.live.reject { |p| p.blog_categories.any? }
    end
  end

  module ShareThis
    DEFAULT_KEY = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

    class << self
      def key
        RefinerySetting.find_or_set(:share_this_key, BlogPost::ShareThis::DEFAULT_KEY, {
          :scoping => 'blog'
        })
      end

      def enabled?
        key = BlogPost::ShareThis.key
        key.present? and key != BlogPost::ShareThis::DEFAULT_KEY
      end
    end
  end

end

