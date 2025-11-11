# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Client, type: :model do
  subject { clients(:client1) }

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
        invalid_keys = %w[Client Invalid! @client# Client123! a!b c$d e%f g^h i&j k*l m(n) n+o o=p q[r s]t t}u v|w x y z A B C D E F G H I
                          J K L M N O P Q R S T U V W X Y Z]

        valid_keys.each do |key|
          client = Client.new(name: 'Test Client', key: key, user: users(:admin))
          client.valid?
          expect(client.errors[:key]).to be_empty, "Expected #{key} to be valid"
        end

        invalid_keys.each do |key|
          client = Client.new(name: 'Test Client', key: key, user: users(:admin))
          client.valid?
          expect(client.errors[:key]).not_to be_empty, "Expected #{key} to be invalid: #{client.errors[:key].join(', ')}"
        end
      end

      it 'validates uniqueness of key scoped to user' do
        user = users(:regular_user)
        # Используем существующий client1 для пользователя regular_user
        client1 = clients(:client1)
        client1.update!(user: user, key: 'test_client')

        client_with_same_key = Client.new(name: 'Another Client', key: 'test_client', user: user)
        client_with_same_key.valid?
        expect(client_with_same_key.errors[:key]).to include(I18n.t('errors.messages.taken'))

        # Different user can have same key
        other_user = users(:admin)
        client_for_other_user = Client.new(name: 'Other Client', key: 'test_client', user: other_user)
        expect(client_for_other_user).to be_valid
      end
    end

    describe 'name validation' do
      it { should validate_length_of(:name).is_at_most(255) }

      it 'allows blank name to be invalid' do
        client = Client.new(name: '', key: 'test_key', user: users(:admin))
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
          client = Client.new(name: name, key: 'test_key', user: users(:admin))
          expect(client).to be_valid, "Expected name '#{name}' to be valid"
        end
      end
    end
  end

  describe 'associations' do
    let(:user) { users(:user_with_telegram) }
    let(:client) { clients(:client1) }

    it 'belongs to user' do
      expect(client.user).to eq(user)
    end

    it 'has many projects' do
      # Используем существующие проекты с уже настроенными клиентами
      project1 = projects(:project_with_client1)
      project2 = projects(:project_with_client2)

      expect(client.projects.reload).to include(project1)
    end

    it 'destroys projects as nullify on client deletion' do
      # Используем существующий проект с клиентом
      project = projects(:project_with_client1)

      # Проверяем что проект действительно связан с клиентом
      expect(project.client).not_to be_nil

      client.destroy
      project.reload

      expect(project.client_id).to be_nil
      expect(project.client).to be_nil
    end
  end

  describe 'methods' do
    let(:client) { clients(:client1) }

    describe '#to_param' do
      it 'returns the key' do
        expect(client.to_param).to eq(client.key)
      end
    end

    describe '#projects_count' do
      it 'returns the number of associated projects' do
        # Используем существующие проекты с клиентами
        client1 = clients(:client1)
        project1 = projects(:project_with_client1)

        expect(client1.projects_count).to be >= 1
        expect(client1.projects).to include(project1)
      end
    end
  end

  describe 'scopes and queries' do
    let(:user) { users(:regular_user) }

    it 'can find clients by user' do
      # Используем существующих клиентов, которые уже принадлежат нужным пользователям
      client1 = clients(:other_client)  # принадлежит regular_user

      # Проверяем что клиент принадлежит правильному пользователю
      expect(client1.user).to eq(user)

      # regular_user имеет как минимум одного клиента
      expect(user.clients.reload).to include(client1)
    end

    it 'can find client by key within user scope' do
      # Используем существующий client1 для пользователя regular_user
      test_client = clients(:client1)
      test_client.update!(user: user, key: 'test_client')

      # Используем существующий work_client для admin
      other_client = clients(:work_client)
      other_client.update!(user: users(:admin), key: 'test_client')

      found_client = user.clients.find_by(key: 'test_client')
      expect(found_client).to eq(test_client)
      expect(found_client).not_to eq(other_client)
    end
  end
end
