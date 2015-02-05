require 'rails_helper'

RSpec.describe Customer, :type => :model do

  subject {create :customer}

  it {should be_valid}
  it {should validate_presence_of :name}
  it {should validate_presence_of :email}

end
