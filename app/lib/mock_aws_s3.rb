# typed: true
module MockAwsS3
  def self.create_real_or_mock
    if EnvironmentVariable.is_true('USE_PLACEHOLDER_STUDENT_PHOTO')
      MockAwsS3.with_student_photo_mocked
    else
      Aws::S3::Client.new
    end
  end

  def self.with_put_mocked
    MockClientForPut.new
  end

  def self.with_student_photo_mocked
    MockedAwsS3.create_with_read_block do |key, bucket|
      small_photo = 'demo-student-photo-small-172x207.jpg'
      large_photo = 'demo-student-photo-large-308x364.jpg'

      if key == small_photo
        File.read("#{Rails.root}/public/#{small_photo}")
      elsif key == large_photo
        File.read("#{Rails.root}/public/#{large_photo}")
      else
        raise 'Unexpected value for AWS S3 request!'
      end
    end
  end

  class MockedAwsS3
    def self.create_with_read_block(&read_block)
      new(read_block: read_block)
    end

    def initialize(options = {})
      @read_block = options.fetch(:read_block)
    end

    def get_object(key:, bucket:)
      MockObject.new(proc { @read_block.call(key, bucket) })
    end
  end

  class MockObject
    def initialize(closed_read_block)
      @closed_read_block = closed_read_block
    end

    def body
      MockObjectBody.new(@closed_read_block)
    end
  end

  class MockObjectBody
    def initialize(closed_read_block)
      @closed_read_block = closed_read_block
    end

    def read
      @closed_read_block.call
    end
  end

  class MockClientForPut
    def put_object(args = {})
      { echo_back_put_object_arguments: args }
    end
  end
end
