# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Client, type: :model do
  subject { build(:client) }

  it { should be_valid }

  describe 'validations' do
    it { should validate_presence_of(:key) }
    it { should validate_presence_of(:name) }
    it { should belong_to(:user) }
    it { should have_many(:projects).dependent(:nullify) }

    describe 'key validation' do
      it { should validate_length_of(:key).is_at_least(2).is_at_most(50) }

      it 'validates format of key' do
        valid_keys = %w[client1 acme_corp my-company test_client client123]
        invalid_keys = %w[Client Invalid! @client# Client123! a!b c$d e%f g^h i&j k*l m(n) n+o o=p q[r s]t t}u v|w x y z A B C D E F G H I J K L M N O P Q R S T U V W X Y Z]

        valid_keys.each do |key|
          client = build(:client, key: key)
          client.valid?
          expect(client.errors[:key]).to be_empty, "Expected #{key} to be valid"
        end

        invalid_keys.each do |key|
          client = build(:client, key: key)
          client.valid?
          expect(client.errors[:key]).not_to be_empty, "Expected #{key} to be invalid: #{client.errors[:key].join(', ')}"
        end
      end

      it 'validates uniqueness of key scoped to user' do
        user = create(:user)
        create(:client, user: user, key: 'test_client')

        client_with_same_key = build(:client, user: user, key: 'test_client')
        client_with_same_key.valid?
        expect(client_with_same_key.errors[:key]).to include(I18n.t('errors.messages.taken'))

        # Different user can have same key
        other_user = create(:user)
        client_for_other_user = build(:client, user: other_user, key: 'test_client')
        expect(client_for_other_user).to be_valid
      end
    end

    describe 'name validation' do
      it { should validate_length_of(:name).is_at_most(255) }

      it 'allows blank name to be invalid' do
        client = build(:client, name: '')
        client.valid?
        expect(client.errors[:name]).to include(I18n.t('errors.messages.blank'))
      end

      it 'allows valid names' do
        valid_names = [
          'ООО "Ромашка"',
          'Acme Corporation',
          'ИП Иванов И.И.',
          'Test Company LLC'
        ]

        valid_names.each do |name|
          client = build(:client, name: name)
          expect(client).to be_valid, "Expected name '#{name}' to be valid"
        end
      end
    end
  end

  describe 'associations' do
    let(:user) { create(:user) }
    let(:client) { create(:client, user: user) }

    it 'belongs to user' do
      expect(client.user).to eq(user)
    end

    it 'has many projects' do
      project1 = create(:project, client: client)
      project2 = create(:project, client: client)

      expect(client.projects).to contain_exactly(project1, project2)
    end

    it 'destroys projects as nullify on client deletion' do
      project = create(:project, client: client)
      client_id = project.client_id

      client.destroy
      project.reload

      expect(project.client_id).to be_nil
      expect(project.client).to be_nil
    end
  end

  describe 'methods' do
    let(:client) { create(:client) }

    describe '#to_param' do
      it 'returns the key' do
        expect(client.to_param).to eq(client.key)
      end
    end

    describe '#projects_count' do
      it 'returns the number of associated projects' do
        expect(client.projects_count).to eq(0)

        create(:project, client: client)
        expect(client.projects_count).to eq(1)

        create(:project, client: client)
        expect(client.projects_count).to eq(2)
      end
    end
  end

  describe 'scopes and queries' do
    let(:user) { create(:user) }

    it 'can find clients by user' do
      client1 = create(:client, user: user)
      client2 = create(:client, user: user)
      other_client = create(:client, user: create(:user))

      expect(user.clients).to contain_exactly(client1, client2)
      expect(user.clients).not_to include(other_client)
    end

    it 'can find client by key within user scope' do
      client = create(:client, user: user, key: 'test_client')
      other_client = create(:client, user: create(:user), key: 'test_client')

      found_client = user.clients.find_by(key: 'test_client')
      expect(found_client).to eq(client)
      expect(found_client).not_to eq(other_client)
    end
  end
end