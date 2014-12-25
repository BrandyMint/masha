require 'spec_helper'

describe Invite do

  let(:invite) {create :invite}

  it 'Если мы созадем инвайт с уже существуюим емайлом в другом проекте, мы не получаем ошибок' do
    expect{ create :invite, email :invite.email }.to_not raise_error
  end

end
