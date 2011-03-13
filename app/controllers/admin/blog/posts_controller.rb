class Admin::Blog::PostsController < Admin::BaseController

  crudify :blog_post,
          :title_attribute => :title,
          :order => 'published_at DESC'

  def uncategorized
    @blog_posts = BlogPost.uncategorized.paginate({
      :page => params[:page],
      :per_page => BlogPost.per_page
    })
  end

  before_filter :find_all_categories,
                :only => [:new, :edit, :create, :update]

protected

  def find_blog_post
    @blog_post = BlogPost.find_by_slug(params[:id])
    @blog_post = @blog_post.nil? ? BlogPost.find(params[:id]) : @blog_post
  end

  def find_all_categories
    @blog_categories = BlogCategory.find(:all)
  end
end

