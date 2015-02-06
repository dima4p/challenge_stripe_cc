require 'rails_helper'

RSpec.describe CreditCard, :type => :model do

  subject {create :credit_card}

  it {should be_valid}
  it {should validate_presence_of :customer}

  describe '#number' do
    subject {build :credit_card}

    describe 'setter' do
      it 'leaves only numbers in :number' do
        subject.number = 'ab c42 42 - 1243+6578   9042 dkmj '
        expect(subject.instance_variable_get(:@number)).to eq '4242124365789042'
      end
    end
  end   # describe '#number'

  describe '#cardholder_name' do
    subject {build :credit_card}

    describe 'getter' do
      it 'returns :cardholder_name' do
        subject.save
        expect(subject.cardholder_name).to eq subject.stripe_object[:name]
      end
    end

    describe 'setter' do
      it 'stores upcase stipped name in :cardholder_name' do
        subject.cardholder_name = '  john  daLe '
        expect(subject.instance_variable_get(:@cardholder_name)).to eq 'JOHN DALE'
      end
    end
  end   # describe '#cardholder_name'

  describe '#exp_month' do
    subject {build :credit_card}

    describe 'getter' do
      it 'returns :exp_month' do
        subject.save
        expect(subject.exp_month).to eq subject.stripe_object[:exp_month]
      end
    end

    describe 'setter' do
      it 'leaves only numbers in :exp_month' do
        subject.exp_month = 'ab c12 '
        expect(subject.instance_variable_get(:@exp_month)).to eq '12'
      end
    end
  end   # describe '#exp_month'

  describe '#exp_year' do
    subject {build :credit_card}

    describe 'getter' do
      it 'returns :exp_year' do
        subject.save
        expect(subject.exp_year).to eq subject.stripe_object[:exp_year]
      end
    end

    describe 'setter' do
      it 'leaves only numbers in :exp_year' do
        subject.exp_year = 'ab 20c12 '
        expect(subject.instance_variable_get(:@exp_year)).to eq '2012'
      end
    end
  end   # describe '#exp_year'

  describe '#cvc' do
    subject {build :credit_card}

    describe 'setter' do
      it 'leaves only numbers in :cvc' do
        subject.cvc = 'ab 0c12 '
        expect(subject.instance_variable_get(:@cvc)).to eq '012'
      end
    end
  end   # describe '#cvc'

  describe '#token' do
    subject {build :credit_card}

    describe 'setter' do
      it 'stores the value in :token' do
        subject.token = 'ab 0c12 '
        expect(subject.instance_variable_get(:@token)).to eq 'ab 0c12 '
      end
    end
  end   # describe '#token'

  describe 'on Stripe server' do
    context 'at creation' do
      it 'adds a new Card' do
        customer = create :customer
        expect {create :credit_card, customer: customer}.to change {customer.stripe_object.cards.all(include: ['total_count'])['total_count']}.by(1)
      end

      it 'assigns to the newly created CreditCard the stripe_id' do
        expect(subject.stripe_id).to eq subject.customer.stripe_object.cards.all(limit: 1).first.id
      end

      it 'assigns the Stripe object to #stripe_object' do
        expect(subject.stripe_object.class).to be Stripe::Card
        expect(subject.stripe_object.to_hash).to eq subject.customer.stripe_object.cards.all(limit: 1).first.to_hash
      end
    end

    context 'with a wrong data' do
      let(:customer) {create :customer}

      it 'does not create a Card' do
        subject = build :credit_card, customer: customer, exp_year: 1.year.ago.year.to_s
        expect {subject.save}.not_to change {customer.stripe_object.cards.all(include: ['total_count'])['total_count']}
      end

      it 'adds an error to the #errors' do
        subject = build :credit_card, customer: customer, exp_year: 1.year.ago.year.to_s
        subject.save
        expect(subject.errors.keys).to include(:exp_year)
      end
    end

    context 'at deletion' do

      it 'removes the Card from Stripe' do
        subject
        expect {subject.destroy}.to change {subject.customer.stripe_object.cards.all(include: ['total_count'])['total_count']}.by(-1)
      end
    end
  end   # describe 'on Stripe server'

  describe '#stripe_object' do
    it 'fetches the corresponding Stripe::Card' do
      expect(CreditCard.find(subject.id).stripe_object).to be
    end
  end

  describe 'updating' do
    it 'changes the name on Stripe if cardholder_name is changed' do
      subject.update(cardholder_name: 'New Name')
      expect(subject.stripe_object[:name]).to eq 'NEW NAME'
    end

    it 'changes the exp_month on Stripe if exp_month is changed' do
      subject.update(exp_month: '12')
      expect(subject.stripe_object[:exp_month]).to eq 12
    end

    it 'changes the exp_year on Stripe if exp_year is changed' do
      subject.update exp_year: (Date.current.year + 2).to_s
      expect(subject.stripe_object[:exp_year]).to eq (Date.current.year + 2)
    end
  end

  describe '#default!' do
    it 'makes this card to be default' do
      customer = create :customer
      card1 = create :credit_card, customer: customer
      card2 = create :credit_card, customer: customer
      expect{card2.default!}.to change{customer.stripe_object[:default_card]}.from(card1.stripe_object.id).to(card2.stripe_object.id)
  end

  end

end
