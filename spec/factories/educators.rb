require "#{Rails.root}/spec/support/fake_names"

FactoryBot.define do

  sequence(:staff_local_id) { |n| "000#{n}" }

  factory :educator do
    full_name do
      first_name = FakeNames.deterministic_sample(FakeNames::FIRST_NAMES)
      last_name = FakeNames.deterministic_sample(FakeNames::LAST_NAMES)
      "#{last_name}, #{first_name}"
    end
    email do
      last_name, first_name = full_name.split(', ')
      domain = PerDistrict.new.email_domain_for_test_pals
      "#{first_name}.#{last_name}@#{domain}"
    end
    login_name do
      last_name, first_name = full_name.split(', ')
      "#{first_name}#{last_name}"
    end
    local_id { FactoryBot.generate(:staff_local_id) }
    association :school

    trait :admin do
      admin { true }
      schoolwide_access { true }
      restricted_to_sped_students { false }
      restricted_to_english_language_learners { false }
    end

    factory :educator_with_homeroom do
      after(:create) do |educator|
        create(:homeroom, educator: educator, school: educator.school)
      end
    end

  end
end
