module LogHelper
  # STDOUT
  class FakeLog
    attr_reader :msgs

    def initialize
      @msgs = []
    end

    def puts(msg)
      @msgs << msg
    end

    def output
      @msgs.join("\n")
    end

    def flush
      nil
    end

    def clear!
      @msgs = []
    end
  end

  # Rails logger, at INFO level
  class RailsLogger
    attr_reader :msgs

    def initialize
      @msgs = []
    end

    def debug?
      false
    end

    def debug(message = nil)
      log_with(:debug, if block_given? then yield else message end)
    end

    def info?
      true
    end

    def info(message = nil)
      log_with(:info, if block_given? then yield else message end)
    end

    def warn?
      true
    end

    def warn(message = nil)
      log_with(:warn, if block_given? then yield else message end)
    end

    def error?
      true
    end

    def error(message = nil)
      log_with(:error, if block_given? then yield else message end)
    end

    def calls
      @msgs
    end

    def output
      @msgs.map {|msg| msg[:message] }.join("\n")
    end

    private
    def log_with(level, message)
      @msgs << {type: level, message: message }
    end
  end
end

RSpec.configure do |config|
  config.include LogHelper
end
