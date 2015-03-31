# encoding: UTF-8

class Post < ActiveRecord::Base
  include ArelHelpers::ArelTable
  has_many :comments
  has_many :favorites
end

class Fee < ActiveRecord::Base
  include ArelHelpers::ArelTable
end

class RegistrationFee < Fee
  belongs_to :billable, :polymorphic => true, :inverse_of => :registration_fee
end

class Comment < ActiveRecord::Base
  include ArelHelpers::ArelTable
  belongs_to :post
  belongs_to :author
end

class Author < ActiveRecord::Base
  include ArelHelpers::ArelTable
  include ArelHelpers::JoinAssociation
  has_one :comment
  has_and_belongs_to_many :collab_posts

  has_one :registration_fee,
    :inverse_of => :billable,
    :as => :billable
end

class Favorite < ActiveRecord::Base
  include ArelHelpers::ArelTable
  belongs_to :post
end

class CollabPost < ActiveRecord::Base
  include ArelHelpers::ArelTable
  has_and_belongs_to_many :authors
end
