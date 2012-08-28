
FactoryGirl.define do

  factory :user do
    sequence(:login) { |n| "user#{n}" }
    email            { "#{login}@example.org" }
    name               'John Doe'

    after(:create) do |user|
      FactoryGirl.create(:identity, user: user)
    end
  end

  factory :admin, parent: :user do
    admin true
  end

  factory :developer, parent: :user do
    developer true
  end

  factory :identity do
    association :user

    sequence(:uid) { |n| n.to_s.hash.to_s.gsub(/\D/, '') }
    provider         'twitter'
    token            'apiTocken'
  end

  factory :application, class: 'Doorkeeper::Application' do
    sequence(:name)         { |n| "OAuth2 Client ##{n}" }
    sequence(:redirect_uri) { |n| "http://test.host/c#{n}/cb" }
  end

  factory :canteen do
    sequence(:name) { |n| "Mensa ##{n}"}
    address         "Marble Street, 12345 City"
    url             "http://example.com/canteen_feed.xml"

    sequence(:latitude)  { |n| (n % 180) - 90 }
    sequence(:longitude) { |n| (n % 360) - 180 }

    association :user
  end

  factory :canteen_with_meals, parent: :canteen do
    after(:create) do |canteen|
      FactoryGirl.create(:meal, day: FactoryGirl.create(:yesterday, canteen: canteen))
      FactoryGirl.create(:meal, day: FactoryGirl.create(:yesterday, canteen: canteen))
      FactoryGirl.create(:meal, day: FactoryGirl.create(:today, canteen: canteen))
      FactoryGirl.create(:meal, day: FactoryGirl.create(:today, canteen: canteen))
      FactoryGirl.create(:meal, day: FactoryGirl.create(:tomorrow, canteen: canteen))
      FactoryGirl.create(:meal, day: FactoryGirl.create(:tomorrow, canteen: canteen))
    end
  end

  factory :day do
    date                { Time.zone.now }

    association :canteen
  end
  factory :yesterday, parent: :day do
    date                { Time.zone.now - 1.day }
  end
  factory :today, parent: :day do
    date                { Time.zone.now }
  end
  factory :tomorrow, parent: :day do
    date                { Time.zone.now + 1.day }
  end

  factory :meal do
    sequence(:category) { |n| "Meal ##{n}" }
    name                { "The name of #{category}." }

    association :day
  end
end
