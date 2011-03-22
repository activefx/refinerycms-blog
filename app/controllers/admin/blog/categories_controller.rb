class Admin::Blog::CategoriesController < Admin::BaseController

  crudify :blog_category,
          :title_attribute => :title,
          :order => 'title ASC'

  protected

  def find_blog_category
    @blog_category = BlogCategory.find_by_slug(params[:id])
    @blog_category = @blog_category.nil? ? BlogPost.find(params[:id]) : @blog_category
  end


end

