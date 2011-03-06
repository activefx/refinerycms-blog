class Blog::CategoriesController < BlogController

  def show
    @category = BlogCategory.find_by_slug(params[:id])
  end

end

