# encoding: UTF-8

require 'spec_helper'

describe ArelHelpers do
  describe "#join_association" do
    it "should work for a directly associated model" do
      Post.joins(ArelHelpers.join_association(Post, :comments)).to_sql.should ==
        'SELECT "posts".* FROM "posts" INNER JOIN "comments" ON "comments"."post_id" = "posts"."id"'
    end

    it "should work for polymorphic associations" do
      Author.joins_type(:registration_fee, Arel::Nodes::InnerJoin).to_sql.should ==
        "SELECT \"authors\".* FROM \"authors\" INNER JOIN \"fees\" ON \"fees\".\"billable_id\" = \"authors\".\"id\" AND \"fees\".\"billable_type\" = 'Author'"

      Author.outer_joins(:registration_fee).to_sql.should ==
        "SELECT \"authors\".* FROM \"authors\" LEFT OUTER JOIN \"fees\" ON \"fees\".\"billable_id\" = \"authors\".\"id\" AND \"fees\".\"billable_type\" = 'Author'"
    end

    it "should work with an outer join" do
      Post.joins(ArelHelpers.join_association(Post, :comments, Arel::Nodes::OuterJoin)).to_sql.should ==
        'SELECT "posts".* FROM "posts" LEFT OUTER JOIN "comments" ON "comments"."post_id" = "posts"."id"'
    end

    it "should allow adding additional join conditions" do
      Post.joins(ArelHelpers.join_association(Post, :comments) do |assoc_name, join_conditions|
        join_conditions.and(Comment[:id].eq(10))
      end).to_sql.should ==
        'SELECT "posts".* FROM "posts" INNER JOIN "comments" ON "comments"."post_id" = "posts"."id" AND "comments"."id" = 10'
    end

    it "should work for two models, one directly associated and the other indirectly" do
      Post
        .joins(ArelHelpers.join_association(Post, :comments))
        .joins(ArelHelpers.join_association(Comment, :author))
        .to_sql.should ==
          'SELECT "posts".* FROM "posts" INNER JOIN "comments" ON "comments"."post_id" = "posts"."id" INNER JOIN "authors" ON "authors"."id" = "comments"."author_id"'
    end

    it "should be able to handle multiple associations" do
      Post.joins(ArelHelpers.join_association(Post, [:comments, :favorites])).to_sql.should ==
        'SELECT "posts".* FROM "posts" INNER JOIN "comments" ON "comments"."post_id" = "posts"."id" INNER JOIN "favorites" ON "favorites"."post_id" = "posts"."id"'
    end

    it "should yield once for each association" do
      Post.joins(ArelHelpers.join_association(Post, [:comments, :favorites]) do |assoc_name, join_conditions|
        case assoc_name
          when :favorites
            join_conditions.or(Favorite[:amount].eq("lots"))
          when :comments
            join_conditions.and(Comment[:text].eq("Awesome post!"))
        end
      end).to_sql.should ==
        'SELECT "posts".* FROM "posts" INNER JOIN "comments" ON "comments"."post_id" = "posts"."id" AND "comments"."text" = \'Awesome post!\' INNER JOIN "favorites" (ON "favorites"."post_id" = "posts"."id" OR "favorites"."amount" = \'lots\')'
    end

    it 'should be able to handle has_and_belongs_to_many associations' do
      CollabPost.joins(ArelHelpers.join_association(CollabPost, :authors)).to_sql.should ==
        'SELECT "collab_posts".* FROM "collab_posts" INNER JOIN "authors_collab_posts" ON "authors_collab_posts"."collab_post_id" = "collab_posts"."id" INNER JOIN "authors" ON "authors"."id" = "authors_collab_posts"."author_id"'
    end
  end
end

describe ArelHelpers::JoinAssociation do
  class AssocPost < Post
    include ArelHelpers::JoinAssociation
  end

  it "should provide the join_association method and use the parent class as the model to join on" do
    AssocPost.joins(AssocPost.join_association(:comments)).to_sql.should ==
      'SELECT "posts".* FROM "posts" INNER JOIN "comments" ON "comments"."post_id" = "posts"."id"'
  end
end
