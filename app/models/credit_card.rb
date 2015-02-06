class CreditCard < ActiveRecord::Base

  belongs_to :customer, inverse_of: :credit_cards

  attr_writer :token

  define_attribute_method 'cardholder_name'
  define_attribute_method 'exp_month'
  define_attribute_method 'exp_year'

  validates :customer, presence: true

  before_create :add_to_stripe
  before_update :update_on_stripe
  before_destroy :remove_from_stripe
  after_rollback :remove_from_stripe

  def number=(value)
    @number = value.gsub(/[^0-9]/, '')
  end

  def cardholder_name=(value)
    @cardholder_name = value.squish.upcase
  end

  def cardholder_name
    stripe_object[:name]
  end

  def exp_month=(value)
    @exp_month = value.to_s.gsub(/[^0-9]/, '')
  end

  def exp_month
    stripe_object[:exp_month]
  end

  def exp_year=(value)
    @exp_year = value.to_s.gsub(/[^0-9]/, '')
  end

  def exp_year
    stripe_object[:exp_year]
  end

  def cvc=(value)
    @cvc = value.to_s.gsub(/[^0-9]/, '')
  end

  def stripe_object
    @stripe_object ||= customer.stripe_object.cards.retrieve stripe_id
  end

  def default!
    customer.stripe_object.default_card = stripe_object.id
    customer.stripe_object.save
  end

  private

  def add_to_stripe
    card = @token || {
      name: @cardholder_name,
      number: @number,
      exp_month: @exp_month,
      exp_year: @exp_year,
      cvc: @cvc
    }.stringify_keys
    @stripe_object = customer.stripe_object.cards.create card: card
    customer.stripe_object true
    self.stripe_id = @stripe_object.id
  rescue Stripe::CardError => e
    # TODO: add error to #errors
    body = e.json_body
    error = body[:error]
    param = error[:param]
    param = 'cardholder_name' if param == 'name'
    errors.add param, error[:code]
    logger.debug "CreditCard@#{__LINE__}#add_to_stripe Code is: #{error[:code]} Param is: #{error[:param]} Message is: #{error[:message]}" if logger.debug?
    false
  end

  def update_on_stripe
    updated = false
    %w[cardholder_name exp_month exp_year].each do |attribute|
      attr = attribute
      attr = 'name' if attr == 'cardholder_name'
      value = instance_variable_get("@#{attribute}")
      if value and value != stripe_object[attr.to_sym]
        stripe_object.send "#{attr}=", value
        updated = true
      end
    end
    updated ? stripe_object.save : true
  end

  def remove_from_stripe
    stripe_object.delete
  rescue
    true
  end

end
