class Customer < ActiveRecord::Base

  validates :name, presence: true
  validates :email, presence: true

  before_create :add_to_stripe
  before_destroy :remove_from_stripe
  after_rollback :remove_from_stripe

  def stripe_object
    @stripe_object ||= Stripe::Customer.retrieve stripe_id
  end

  private

  def add_to_stripe
    @stripe_object = Stripe::Customer.create email: email, metadata: {name: name}
    self.stripe_id = @stripe_object.id
  rescue
    # TODO: add error to #errors
    false
  end

  def remove_from_stripe
    stripe_object.delete
  rescue
    true
  end

end
