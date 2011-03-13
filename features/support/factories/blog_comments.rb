require 'factory_girl'

Factory.sequence :email do |n|
  "person#{n}@example.com"
end

Factory.define(:blog_comment) do |f|
  f.name "Joe Commenter"
  f.email { Factory.next(:email) }
  f.body "Which one is the best for picking up new shoes?"
  f.association :blog_post
end

