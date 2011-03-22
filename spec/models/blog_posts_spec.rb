require 'spec_helper'
Dir[File.expand_path('../../../features/support/factories/*.rb', __FILE__)].each{|factory| require factory}

describe BlogPost do
  describe "validations" do
    before(:each) do
      @attr = { :title => "RefineryCMS", :body => "Some random text ..." }
    end

    it "requires title" do
      BlogPost.new(@attr.merge(:title => "")).should_not be_valid
    end

    it "won't allow duplicate titles" do
      BlogPost.create!(@attr)
      BlogPost.new(@attr).should_not be_valid
    end

    it "requires body" do
      BlogPost.new(@attr.merge(:body => nil)).should_not be_valid
    end
  end

  describe "comments association" do
    before(:each) do
      @blog_post = Factory(:blog_post)
    end

    it "have a comments attribute" do
      @blog_post.should respond_to(:blog_comments)
    end

    it "destroys associated comments" do
      @blog_post.blog_comments.create Factory.attributes_for(:blog_comment)
      @blog_post.destroy
      BlogComment.find_by_blog_post_id(@blog_post.id).first.should be_nil
    end
  end

  describe "categories association" do
    before(:each) do
      @blog_post = Factory(:blog_post)
    end

    it "have categories attribute" do
      @blog_post.should respond_to(:blog_categories)
    end
  end

  describe "tags" do
    it "acts as taggable" do
      (post = Factory(:blog_post)).should respond_to(:tags)
      post.tags_array.should include("chicago")
    end
  end

  describe "authors" do
    it "are authored" do
      BlogPost.new.should respond_to(:administrator)
    end
  end

  describe "by_archive scope" do
    it "returns all posts from specified month" do
      blog_post1 = Factory(:blog_post, :published_at => Time.now.advance(:minutes => -2))
      blog_post2 = Factory(:blog_post, :published_at => Time.now.advance(:minutes => -1))
      Factory(:blog_post, :published_at => Time.now - 2.months)
      date = "#{Time.now.month}/#{Time.now.year}"
      BlogPost.by_archive(Time.parse(date)).count.should == 2
      BlogPost.by_archive(Time.parse(date)).should == [blog_post2, blog_post1]
    end
  end

  describe "all_previous scope" do
    it "returns all posts from previous months" do
      blog_post1 = Factory(:blog_post, :published_at => Time.now.advance(:months => -2))
      blog_post2 = Factory(:blog_post, :published_at => Time.now.advance(:months => -1))
      Factory(:blog_post, :published_at => Time.now)
      BlogPost.all_previous.count.should == 2
      BlogPost.all_previous.first.should == blog_post2
      BlogPost.all_previous.last.should == blog_post1
    end
  end

  describe "live scope" do
    it "returns all posts which aren't in draft and pub date isn't in future" do
      blog_post1 = Factory(:blog_post, :published_at => Time.now.advance(:minutes => -2))
      blog_post2 = Factory(:blog_post, :published_at => Time.now.advance(:minutes => -1))
      Factory(:blog_post, :draft => true)
      Factory(:blog_post, :published_at => Time.now + 1.minute)
      BlogPost.live.count.should == 2
      BlogPost.live.should == [blog_post2, blog_post1]
    end
  end

  describe "next scope" do
    it "returns next article based on given article" do
      blog_post1 = Factory(:blog_post)
      blog_post2 = Factory(:blog_post, :published_at => Time.now.advance(:minutes => -1))
      BlogPost.next(blog_post2).first.id.should == blog_post1.id
    end
  end

  describe "previous scope" do
    it "returns previous article based on given article" do
      blog_post1 = Factory(:blog_post)
      blog_post2 = Factory(:blog_post, :published_at => Time.now.advance(:minutes => -1))
      BlogPost.previous(blog_post1).first.id.should == blog_post2.id
    end
  end

  describe "uncategorized scope" do
    it "returns uncategorized posts if they exist" do
      uncategorized_blog_post = Factory(:blog_post)
      categorized_blog_post = Factory(:blog_post)

      categorized_blog_post.blog_categories << Factory(:blog_category)

      BlogPost.uncategorized.should include uncategorized_blog_post
      BlogPost.uncategorized.should_not include categorized_blog_post
    end
  end

  describe "#live?" do
    it "returns true if post is not in draft and it's published" do
      Factory(:blog_post).live?.should be_true
    end

    it "returns false if post is in draft" do
      Factory(:blog_post, :draft => true).live?.should be_false
    end

    it "returns false if post pub date is in future" do
      Factory(:blog_post, :published_at => Time.now.advance(:minutes => 10)).live?.should be_false
    end
  end

  describe "#next" do
    it "returns next article when called on current article" do
      Factory(:blog_post, :published_at => Time.now.advance(:minutes => -1))
      blog_post = Factory(:blog_post)
      blog_posts = BlogPost.all
      blog_posts.last.next.should == blog_post
    end
  end

  describe "#prev" do
    it "returns previous article when called on current article" do
      Factory(:blog_post)
      blog_post = Factory(:blog_post, :published_at => Time.now.advance(:minutes => -1))
      blog_posts = BlogPost.all
      blog_posts.first.prev.should == blog_post
    end
  end

  describe "#category_ids=" do
    before(:each) do
      @blog_post = Factory(:blog_post)
      @cat1 = Factory(:blog_category)
      @cat2 = Factory(:blog_category)
      @cat3 = Factory(:blog_category)
      @blog_post.blog_categories << @cat1
      @blog_post.blog_categories << @cat2
      @blog_post.blog_categories << @cat3
    end

    it "rejects blank category ids" do
      @blog_post.blog_categories.count.should == 3
    end

    it "returns array of categories based on given ids" do
      @blog_post.blog_categories.include?(@cat1).should == true
      @blog_post.blog_categories.include?(@cat2).should == true
      @blog_post.blog_categories.include?(@cat3).should == true
    end
  end

  describe ".comments_allowed?" do
    it "returns true if comments_allowed setting is set to true" do
      BlogPost.comments_allowed?.should be_true
    end

    it "returns false if comments_allowed setting is set to false" do
      RefinerySetting.set(:comments_allowed, {:scoping => 'blog', :value => false})
      BlogPost.comments_allowed?.should be_false
    end
  end

  describe "editor date field parameters" do
    before(:each) do
      @attrs = {
        "title"=>"Here we go",
        "body"=>"<p>yes</p>",
        "draft"=>"0",
        "published_at(1i)"=>"2011",
        "published_at(2i)"=>"3",
        "published_at(3i)"=>"6",
        "published_at(4i)"=>"22",
        "published_at(5i)"=>"44"
      }
    end

    it "should save with date_time form field attributes" do
      @post = BlogPost.create(@attrs)
      @post.new_record?.should be_false
    end
  end

end

