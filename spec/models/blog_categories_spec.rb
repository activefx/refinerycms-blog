require 'spec_helper'
Dir[File.expand_path('../../../features/support/factories/*.rb', __FILE__)].each{|factory| require factory}

describe BlogCategory do
  before(:each) do
    @attr = { :title => "RefineryCMS" }
  end

  describe "validations" do
    it "requires title" do
      BlogCategory.new(@attr.merge(:title => "")).should_not be_valid
    end

    it "won't allow duplicate titles" do
      BlogCategory.create!(@attr)
      BlogCategory.new(@attr).should_not be_valid
    end
  end

  describe "blog posts association" do
    it "has a posts attribute" do
      BlogCategory.new.should respond_to(:blog_posts)
    end

    it "returns posts by published_at date in descending order" do
      @category = BlogCategory.create!(@attr)
      @first_post = @category.blog_posts.create!({ :title => "Breaking News: Joe Sak is hot stuff you guys!!", :body => "True story.", :published_at => Time.now.yesterday })
      @latest_post = @category.blog_posts.create!({ :title => "pardnt is p. okay", :body => "For a kiwi.", :published_at => Time.now })
      #workaround - Mongoid issue #587
      @category.latest_blog_posts.first.should == @latest_post
    end

  end

  describe "#post_count" do
    it "returns post count in category" do
      category = Factory(:blog_category)
      category.blog_posts << Factory(:blog_post)
      category.blog_posts.create(Factory.attributes_for(:blog_post))
      BlogCategory.first.post_count.should == 3
    end
  end
end

