class Project < ActiveRecord::Base
extend FriendlyId
  resourcify

  friendly_id :name, use: :slugged

  belongs_to :owner

  has_many :time_shifts

  scope :ordered, order(:name)

  validates :name, :presence => true, :uniqueness => true
  #validates :slug, :presence => true, :uniqueness => true


  def to_s
    name
  end
end
