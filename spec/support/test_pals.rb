# This class defines a set of users, schools, homerooms and students
# that can be used for testing authorization rules.
#
# These can be re-used for any other test code, but changes here will impact
# many tests, so the intention is that these should not change frequently.
# If new attributes are added to models, update the factories instead.
class TestPals
  def self.create!(options = {})
    pals = TestPals.new
    pals.create!(options)
    pals
  end

  # This uses the YAML config
  def self.seed_somerville_schools_for_test!
    per_district = PerDistrict.new(district_key: PerDistrict::SOMERVILLE)
    school_definitions = per_district.school_definitions_for_import
    School.create!(school_definitions)
  end

  # schools
  attr_reader :healey
  attr_reader :shs
  attr_reader :west

  # students
  attr_reader :healey_kindergarten_student
  attr_reader :west_eighth_ryan
  attr_reader :shs_freshman_mari
  attr_reader :shs_freshman_amir
  attr_reader :shs_senior_kylo

  # educators
  attr_reader :uri
  attr_reader :rich_districtwide
  attr_reader :healey_vivian_teacher
  attr_reader :healey_ell_teacher
  attr_reader :healey_sped_teacher
  attr_reader :healey_laura_principal
  attr_reader :healey_sarah_teacher
  attr_reader :west_marcus_teacher
  attr_reader :west_counselor
  attr_reader :shs_jodi
  attr_reader :shs_bill_nye
  attr_reader :shs_sofia_counselor
  attr_reader :shs_hugo_art_teacher
  attr_reader :shs_fatima_science_teacher
  attr_reader :shs_harry_housemaster

  # homerooms
  attr_reader :healey_kindergarten_homeroom
  attr_reader :healey_fifth_homeroom
  attr_reader :west_fifth_homeroom
  attr_reader :shs_jodi_homeroom
  attr_reader :shs_sophomore_homeroom

  # courses
  attr_reader :shs_biology_course
  attr_reader :shs_ceramics_course
  attr_reader :shs_physics_course

  # sections
  attr_reader :shs_tuesday_biology_section
  attr_reader :shs_thursday_biology_section
  attr_reader :shs_second_period_ceramics
  attr_reader :shs_fourth_period_ceramics
  attr_reader :shs_third_period_physics
  attr_reader :shs_fifth_period_physics

  def time_now
    Time.zone.local(2018, 3, 13, 11, 03)
  end

  def create!(options = {})
    TestPals.seed_somerville_schools_for_test!

    email_domain = options.fetch(:email_domain, 'demo.studentinsights.org')
    skip_team_memberships = options.fetch(:skip_team_memberships, false)
    skip_imported_forms = options.fetch(:skip_imported_forms, false)
    district_school_year = options.fetch(:district_school_year, Section.to_district_school_year(SchoolYear.to_school_year(time_now)))

    # Uri works in the central office, and is the admin for the
    # project at the district.
    @uri = Educator.create!(
      id: 999999,
      login_name: 'uri',
      email: "uri@#{email_domain}",
      full_name: 'Disney, Uri',
      staff_type: 'Administrator',
      can_set_districtwide_access: true,
      districtwide_access: true,
      admin: true,
      schoolwide_access: true,
      restricted_to_sped_students: false,
      restricted_to_english_language_learners: false,
      grade_level_access: [],
      can_view_restricted_notes: true,
      school: School.find_by_local_id('HEA')
    )
    EducatorLabel.create!(
      educator: @uri,
      label_key: 'can_upload_student_voice_surveys'
    )
    EducatorLabel.create!(
      educator: @uri,
      label_key: 'should_show_levels_shs_link'
    )
    EducatorLabel.create!({
      educator: @uri,
      label_key: 'enable_reading_benchmark_data_entry'
    })
    EducatorLabel.create!({
      educator: @uri,
      label_key: 'profile_enable_minimal_reading_data'
    })
    EducatorLabel.create!({
      educator: @uri,
      label_key: 'enable_equity_experiments'
    })
    EducatorLabel.create!({
      educator: @uri,
      label_key: 'enable_reading_debug'
    })
    EducatorLabel.create!({
      educator: @uri,
      label_key: 'enable_viewing_educators_with_access_to_student'
    })
    EducatorLabel.create!({
      educator: @uri,
      label_key: 'enable_reflection_on_notes_patterns'
    })
    EducatorMultifactorConfig.create!({
      educator: @uri,
      rotp_secret: '4444rrr2vwjqgua2umohlpuzobar4444' # so development and demo have a stable TOTP setup over deploys
    })

    # Rich works in the central office and has districwide access, but
    # not project lead access.
    @rich_districtwide = Educator.create!(
      login_name: 'rich',
      email: "rich@#{email_domain}",
      full_name: 'Districtwide, Rich',
      staff_type: 'Administrator',
      can_set_districtwide_access: false,
      districtwide_access: true,
      admin: true,
      schoolwide_access: true,
      restricted_to_sped_students: false,
      restricted_to_english_language_learners: false,
      grade_level_access: [],
      can_view_restricted_notes: true,
      school: nil
    )
    EducatorMultifactorConfig.create!({
      educator: @rich_districtwide,
      sms_number: '+15555550009',
      rotp_secret: EducatorMultifactorConfig.new_rotp_secret
    })

    # Healey is a K8 school.
    @healey = School.find_by_local_id!('HEA')
    @healey_kindergarten_homeroom = Homeroom.create!(
      name: 'HEA 003',
      grade: 'KF',
      school: @healey
    )
    @healey_fifth_homeroom = Homeroom.create!(
      name: 'HEA 500',
      grade: '5',
      school: @healey,
    )

    @healey_vivian_teacher = Educator.create!(
      login_name: 'vivian',
      email: "vivian@#{email_domain}",
      full_name: 'Teacher, Vivian',
      staff_type: nil,
      school: @healey,
      homeroom: @healey_kindergarten_homeroom
    )

    @healey_ell_teacher = Educator.create!(
      login_name: 'alonso',
      email: "alonso@#{email_domain}",
      full_name: 'Teacher, Alonso',
      restricted_to_english_language_learners: true,
      school: @healey
    )
    @healey_sped_teacher = Educator.create!(
      login_name: 'silva',
      email: "silva@#{email_domain}",
      full_name: 'Teacher, Silva',
      restricted_to_sped_students: true,
      school: @healey
    )
    @healey_laura_principal = Educator.create!(
      login_name: 'laura',
      email: "laura@#{email_domain}",
      full_name: 'Principal, Laura',
      school: @healey,
      staff_type: 'Principal',
      admin: true,
      schoolwide_access: true,
      can_view_restricted_notes: true,
      local_id: '350'
    )
    EducatorLabel.create!(
      educator: @healey_laura_principal,
      label_key: 'class_list_maker_finalizer_principal'
    )
    @healey_sarah_teacher = Educator.create!(
      login_name: 'sarah',
      email: "sarah@#{email_domain}",
      full_name: 'Teacher, Sarah',
      homeroom: @healey_fifth_homeroom,
      school: @healey,
      local_id: '450'
    )
    @healey_kindergarten_student = Student.create!(
      first_name: 'Garfield',
      last_name: 'Skywalker',
      school: @healey,
      homeroom: @healey_kindergarten_homeroom,
      grade: 'KF',
      local_id: '111111111',
      state_id: '991111111',
      enrollment_status: 'Active'
    )

    # West is a K8 school
    @west = School.find_by_local_id!('WSNS')
    @west_fifth_homeroom = Homeroom.create!(
      name: 'WSNS 501',
      grade: '5',
      school: @west
    )
    @west_marcus_teacher = Educator.create!(
      login_name: 'marcus',
      email: "marcus@#{email_domain}",
      full_name: 'Teacher, Marcus',
      local_id: '550',
      homeroom: @west_fifth_homeroom,
      school: @west
    )
    @west_counselor = Educator.create!(
      login_name: 'les',
      email: "les@#{email_domain}",
      full_name: "Counselor, Les",
      local_id: '551',
      school: @west,
      can_view_restricted_notes: true,
      schoolwide_access: true
    )
    EducatorLabel.create!(
      educator: @west_counselor,
      label_key: 'k8_counselor'
    )
    EducatorLabel.create!(
      educator: @west_counselor,
      label_key: 'enable_transition_note_features'
    )
    @west_eighth_ryan = Student.create!(
      first_name: 'Ryan',
      last_name: 'Rodriguez',
      school: @west,
      grade: '8',
      local_id: '333333333',
      state_id: '993333333',
      enrollment_status: 'Active'
    )
    SecondTransitionNote.create!({
      recorded_at: time_now - 4.days,
      educator: @west_counselor,
      student: @west_eighth_ryan,
      form_key: SecondTransitionNote::SOMERVILLE_TRANSITION_2019,
      form_json: {
        strengths: 'Ryan is polite and able to diffuse difficult social situations or potential conflicts.  He enjoys playing with technology and swimming.',
        connecting: 'Asking him about scouting can work well talking 1:1, or in the classroom he sometimes like being seen as a leader with setting up the computer or projector system.',
        community: "He doesn't always feel like he can relate to every in his grade easily, and so hasn't become involved within school, but is in scouts outside school.",
        peers: 'Ryan has a small circle of friends that he spends most of his time with.',
        family: 'Although Ryan lives primarily with his mother, his father is very involved with education and it makes a big difference if he is updated regularly. The best way to reach the mother is through email and the father by phone.',
        other: "Ryan is caring and thoughtful and has many strengths, but school seems tough for him a lot of the time.  He needs consistent support to stay focused and motivated on schoolwork, which this year has been with redirect.  He has done some counseling in the past as well, but redirect has been the most effective day-to-day."
      },
      restricted_text: 'Ryan has worked with a counselor at Riverside in the past, Mikayla, but has not this year.  Contact 8th grade counselor for more.'
    })

    # high school
    @shs = School.find_by_local_id!('SHS')
    @shs_sofia_counselor = Educator.create!(
      login_name: 'sofia',
      email: "sofia@#{email_domain}",
      full_name: 'Counselor, Sofia',
      school: @shs,
      schoolwide_access: true
    )
    EducatorLabel.create!({
      educator: @shs_sofia_counselor,
      label_key: 'use_counselor_based_feed'
    })
    EducatorLabel.create!(
      educator: @shs_sofia_counselor,
      label_key: 'enable_transition_note_features'
    )
    EducatorLabel.create!(
      educator: @shs_sofia_counselor,
      label_key: 'high_school_house_master'
    )
    EducatorLabel.create!({
      educator: @shs_sofia_counselor,
      label_key: 'enable_counselor_meetings_page'
    })
    CounselorNameMapping.create!({
      counselor_field_text: 'sofia',
      educator_id: @shs_sofia_counselor.id
    })

    @shs_sophomore_homeroom = Homeroom.create!(name: "SHS ALL", grade: "10", school: @shs)

    # Jodi has a homeroom period at the high school.
    @shs_jodi_homeroom = Homeroom.create!(
      name: 'SHS 942',
      grade: '9',
      school: @shs
    )
    @shs_jodi = Educator.create!(
      login_name: 'jodi',
      email: "jodi@#{email_domain}",
      full_name: 'Teacher, Jodi',
      school: @shs,
      homeroom: @shs_jodi_homeroom
    )
    EducatorLabel.create!({
      educator: @shs_jodi,
      label_key: 'shs_experience_team'
    })
    EducatorLabel.create!(
      educator: @shs_jodi,
      label_key: 'can_upload_student_voice_surveys'
    )

    @shs_harry_housemaster = Educator.create!(
      login_name: 'harry',
      email: "harry@#{email_domain}",
      full_name: 'Housemaster, Harry',
      school: @shs,
      schoolwide_access: true,
      can_view_restricted_notes: true
    )
    EducatorMultifactorConfig.create!({
      educator: @shs_harry_housemaster,
      via_email: true,
      rotp_secret: EducatorMultifactorConfig.new_rotp_secret
    })
    EducatorLabel.create!({
      educator: @shs_harry_housemaster,
      label_key: 'high_school_house_master'
    })
    EducatorLabel.create!({
      educator: @shs_harry_housemaster,
      label_key: 'use_housemaster_based_feed'
    })
    HouseEducatorMapping.create!({
      house_field_text: 'broadway',
      educator_id: @shs_harry_housemaster.id
    })

    # Bill Nye is a biology teacher at Somerville High School.  He teaches sections
    # on Tuesday and Thursday and has a homeroom period.  And he's on the NGE team.
    @shs_bill_nye_homeroom = Homeroom.create!(
      name: 'SHS 917',
      grade: '9',
      school: @shs
    )
    @shs_bill_nye = Educator.create!(
      login_name: 'bill',
      email: "bill@#{email_domain}",
      full_name: 'Teacher, Bill',
      school: @shs,
      homeroom: @shs_bill_nye_homeroom
    )
    @shs_biology_course = Course.create!({
      school: @shs,
      course_number: 'BIO-700',
      course_description: 'BIOLOGY 1 HONORS'
    })
    create_section_assignment(@shs_bill_nye, [
      @shs_tuesday_biology_section = Section.create!(
        course: @shs_biology_course,
        section_number: 'SHS-BIO-TUES',
        term_local_id: 'Q3',
        district_school_year: district_school_year,
      ),
      @shs_thursday_biology_section = Section.create!(
        course: @shs_biology_course,
        section_number: 'SHS-BIO-THUR',
        term_local_id: 'Q4',
        district_school_year: district_school_year,
      )
    ])
    EducatorLabel.create!({
      educator: @shs_bill_nye,
      label_key: 'shs_experience_team'
    })

    # Hugo teachers two sections of ceramics at the high school.
    @shs_hugo_art_teacher = Educator.create!(
      login_name: 'hugo',
      email: "hugo@#{email_domain}",
      full_name: 'Teacher, Hugo',
      local_id: '650',
      school: @shs
    )
    @shs_ceramics_course = Course.create!({
      school: @shs,
      course_number: "ART-302",
      course_description: "ART MAJOR FOUNDATIONS",
    })
    create_section_assignment(@shs_hugo_art_teacher, [
      @shs_second_period_ceramics = Section.create!(
        section_number: "ART-302A",
        term_local_id: "FY",
        district_school_year: district_school_year,
        schedule: "2(M,R)",
        room_number: "201",
        course: @shs_ceramics_course
      ),
      @shs_fourth_period_ceramics = Section.create!(
        section_number: "ART-302B",
        term_local_id: "FY",
        district_school_year: district_school_year,
        schedule: "4(M,R)",
        room_number: "234",
        course: @shs_ceramics_course
      )
    ])

    # Fatima teaches two sections of physics at the high school.
    # She's a data coordinator, so has schoolwide access also, but
    # wants her feed and other views to be focused on students in her
    # courses.
    @shs_fatima_science_teacher = Educator.create!(
      login_name: 'fatima',
      email: "fatima@#{email_domain}",
      full_name: 'Teacher, Fatima',
      schoolwide_access: true,
      local_id: '750',
      school: @shs
    )
    EducatorLabel.create!(
      educator: @shs_fatima_science_teacher,
      label_key: 'use_section_based_feed'
    )
    @shs_physics_course = Course.create!({
      school: @shs,
      course_number: "SCI-201",
      course_description: "PHYSICS 1"
    })
    create_section_assignment(@shs_fatima_science_teacher, [
      @shs_third_period_physics = Section.create!(
        section_number: "SCI-201A",
        term_local_id: "S1",
        district_school_year: district_school_year,
        schedule: "3(M,W,F)",
        room_number: "306W",
        course: @shs_physics_course
      ),
      @shs_fifth_period_physics = Section.create!(
        section_number: "SCI-201B",
        term_local_id: "S1",
        district_school_year: district_school_year,
        schedule: "5(M,W,F)",
        room_number: "306W",
        course: @shs_physics_course
      )
    ])

    # Mari is a freshman at the high school, enrolled in biology and in Jodi's homeroom.
    @shs_freshman_mari = Student.create!(
      first_name: 'Mari',
      last_name: 'Kenobi',
      school: @shs,
      homeroom: @shs_jodi_homeroom,
      house: 'Beacon',
      counselor: 'SOFIA',
      grade: '9',
      date_of_birth: '2004-03-12',
      local_id: '111222222',
      state_id: '991222222',
      enrollment_status: 'Active'
    )
    StudentSectionAssignment.create!(
      student: @shs_freshman_mari,
      section: @shs_tuesday_biology_section,
      grade_numeric: 67,
      grade_letter: 'D'
    )
    @shs_freshman_amir = Student.create!(
      first_name: 'Amir',
      last_name: 'Solo',
      school: @shs,
      homeroom: @shs_jodi_homeroom,
      house: 'Broadway',
      counselor: 'FISHMAN',
      grade: '9',
      date_of_birth: '2003-02-07',
      local_id: '2222222211',
      state_id: '9922222211',
      enrollment_status: 'Active'
    )
    StudentSectionAssignment.create!(
      student: @shs_freshman_amir,
      section: @shs_third_period_physics,
      grade_numeric: 84,
      grade_letter: 'B'
    )
    @shs_senior_kylo = Student.create!(
      first_name: 'Kylo',
      last_name: 'Ren',
      school: @shs,
      homeroom: nil,
      house: 'Broadway',
      counselor: 'FISHMAN',
      grade: '12',
      date_of_birth: '2001-02-07',
      local_id: '2225555555',
      state_id: '9925555555',
      enrollment_status: 'Active'
    )
    StudentSectionAssignment.create!(
      student: @shs_senior_kylo,
      section: @shs_second_period_ceramics,
      grade_numeric: 61,
      grade_letter: 'F'
    )

    add_team_memberships unless skip_team_memberships
    add_student_voice_surveys unless skip_imported_forms
    add_bedford_end_of_year_transition unless skip_imported_forms

    reindex!
    self
  end

  private
  # "now" in time_now for test (not wall clock)
  def add_team_memberships
    this_season_key, school_year_text = TeamMembership.this_season_and_year(time_now: time_now)
    TeamMembership.create!({
      student_id: shs_freshman_mari.id,
      activity_text: 'Competitive Cheerleading Varsity',
      coach_text: 'Fatima Teacher',
      season_key: this_season_key,
      school_year_text: school_year_text
    })
    TeamMembership.create!({
      student_id: shs_senior_kylo.id,
      activity_text: 'Cross Country - Boys Varsity',
      coach_text: 'Jonathan Fishman',
      season_key: this_season_key,
      school_year_text: school_year_text
    })
  end

  # time_now, not wall clock
  def add_student_voice_surveys
    ImportedForm.create!({
      "educator_id"=>shs_jodi.id,
      "student_id"=>shs_freshman_mari.id,
      'form_timestamp' => time_now - 2.days,
      "form_key"=>"shs_what_i_want_my_teacher_to_know_mid_year",
      'form_url' => 'https://example.com/mid_year_survey_form_url',
      'form_json' => {
        "What was the high point for you in school this year so far?"=>"A high point has been my grade in Biology since I had to work a lot for it",
        "I am proud that I..."=>"Have good grades in my classes",
        "My best qualities are..."=>"helping others when they don't know how to do homework assignments",
        "My activities and interests outside of school are..."=>"cheering",
        "I get nervous or stressed in school when..."=>"I get a low grade on an assignment that I thought I would do well on",
        "I learn best when my teachers..."=>"show me each step of what I have to do"
      }
    })
    ImportedForm.create!({
      "educator_id"=>shs_jodi.id,
      "student_id"=>shs_freshman_mari.id,
      'form_timestamp' => time_now - 2.days,
      "form_key"=>"shs_q2_self_reflection",
      'form_url' => 'https://example.com/q2_self_reflection_form_url',
      'form_json' => {
        "What classes are you doing well in?"=>"Computer Science, French",
        "Why are you doing well in those classes?"=>"I make time in my afternoon each day for doing homework and stick to it",
        "What courses are you struggling in?"=>"Nothing really",
        "Why are you struggling in those courses?"=>"I have to work really hard ",
        "In the classes that you are struggling in, how can your teachers support you so that your grades, experience, work load, etc, improve?"=>"Change the way homework works, it's too much",
        "When you are struggling, who do you go to for support, encouragement, advice, etc?"=>"Being able to stay after school and work with teachers when I need help",
        "At the end of the quarter 3, what would make you most proud of your accomplishments in your course?"=>"Keeping grades high in all classes since I'm worried about college",
        "What other information is important for your teachers to know so that we can support you and your learning? (For example, tutor, mentor, before school HW help, study group, etc)"=>"Help in the morning before school"
      }
    })
  end

  def add_bedford_end_of_year_transition
    ImportedForm.create!({
      'student_id' => healey_kindergarten_student.id,
      'educator_id' => healey_vivian_teacher.id,
      'form_key' => ImportedForm::BEDFORD_DAVIS_TRANSITION_NOTES_FORM,
      'form_url' => 'https://example.com/form_url',
      'form_timestamp' => time_now,
      "form_json"=>{
        "LLI"=>'yes',
        "Reading Intervention (w/ specialist)"=>nil,
        "Math Intervention (w/ consult from SD)"=>'yes',
        "Please share any specific information you want the teacher to know beyond the report card. This could include notes on interventions, strategies, academic updates that aren't documented in an IEP or 504. If information is in a file please be sure to link it here or share w/ Jess via google doc folder or paper copy"=>"Nov- Dec: 3x30 1:4 pull out Reading group (PA and fundations)",
        "Is there any key information that you wish you knew about this student in September?"=>nil,
        "Please share anything that helped you connect with this student that might be helpful to the next teacher."=>'Garfield enjoyed sharing special time reading together for a few minutes at the end of the day.'
      }
    })
  end

  def create_section_assignment(educator, sections)
    sections.each do |section|
      EducatorSectionAssignment.create!(educator: educator, section: section)
    end
  end

  # Normally these records are created in the import process, which
  # computes some indexes after importing.  So we do the same here.
  def reindex!
    Student.update_recent_student_assessments!
  end
end
