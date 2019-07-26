# typed: false
FactoryBot.define do

  factory :student_assessment do
    date_taken DateTime.new(2015, 6, 19)
    association :student
    association :assessment

    factory :mcas_assessment do
      factory :mcas_math_assessment do
        association :assessment, subject: "Mathematics", family: "MCAS"
        factory :mcas_math_warning_assessment do
          performance_level "W"
        end
        factory :mcas_math_advanced_assessment do
          performance_level "A"
        end
        factory :mcas_math_student_assessment_score_240 do
          scale_score 240
        end
        factory :mcas_math_student_assessment_score_280 do
          scale_score 280
        end
      end
      factory :next_gen_mcas_math_assessment do
        association :assessment, subject: "Mathematics", family: "Next Gen MCAS"
        factory :next_gen_mcas_math_exceeds_expectations_assessment do
          performance_level "EE"
        end
      end
      factory :mcas_ela_assessment do
        association :assessment, subject: "ELA", family: "MCAS"
        factory :mcas_ela_student_assessment_score_250 do
          scale_score 250
        end
        factory :mcas_ela_student_assessment_score_290 do
          scale_score 290
        end
      end
    end
    factory :access do
      association :assessment, family: "ACCESS"
    end
  end
end
