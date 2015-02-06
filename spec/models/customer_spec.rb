require 'rails_helper'

RSpec.describe Customer, :type => :model do

  subject {create :customer}

  it {should be_valid}
  it {should validate_presence_of :name}
  it {should validate_presence_of :email}
  it {should have_many(:credit_cards).dependent(:destroy)}

  describe 'on Stripe server' do
    context 'at creation' do
      it 'adds a new Customer on Stripe' do
        expect {create :customer}.to change {Stripe::Customer.all(include: ['total_count'])['total_count']}.by(1)
      end

      it 'assigns to the newly created customer the stripe_id' do
        expect(subject.stripe_id).to eq Stripe::Customer.all(limit: 1).first.id
      end

      it 'assigns the Stripe object to #stripe_object' do
        expect(subject.stripe_object.class).to be Stripe::Customer
        expect(subject.stripe_object.to_hash).to eq Stripe::Customer.all(limit: 1).first.to_hash
      end

      it "assigns name to the stripe object's metadata" do
        expect(subject.stripe_object['metadata']['name']).to eq subject.name
      end

      it 'assigns email to the stripe object' do
        expect(subject.stripe_object['email']).to eq subject.email
      end
    end

    context 'at deletion' do

      it 'removes the Customer from Stripe' do
        subject
        expect {subject.destroy}.to change {Stripe::Customer.all(include: ['total_count'])['total_count']}.by(-1)
      end
    end
  end   # describe 'on Stripe server'

  describe '#stripe_object' do
    it 'fetches the corresponding Stripe::Customer' do
      expect(Customer.find(subject.id).stripe_object).to be
    end

    it 'refetches the corresponding Stripe::Customer if parameter true is given' do
      old = subject.stripe_object
      expect(subject.stripe_object true).not_to equal old
    end
  end

end
