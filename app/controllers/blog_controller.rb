class BlogController < ApplicationController

  helper :blog_posts
  before_filter :find_page, :find_all_blog_categories

protected

  def find_page
    @page = Page.where(:link_url => "/blog").first
  end

  def find_all_blog_categories
    @blog_categories = BlogCategory.all
  end

end

