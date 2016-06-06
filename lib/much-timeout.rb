require 'thread'
require "much-timeout/version"

module MuchTimeout

  TimeoutError = Class.new(Interrupt)

  PIPE_SIGNAL = '.'

  def self.timeout(seconds, klass = nil, &block)
    if seconds.nil?
      raise ArgumentError, 'please specify a non-nil seconds value'
    end
    if !seconds.kind_of?(::Numeric)
      raise ArgumentError, "please specify a numeric seconds value "\
                           "(`#{seconds.inspect}` was given)"
    end
    exception_klass = klass || TimeoutError
    reader, writer  = IO.pipe

    begin
      block_thread ||= Thread.new do
        begin
          block.call
        ensure
          writer.write_nonblock(PIPE_SIGNAL) rescue false
        end
      end
      if !!::IO.select([reader], nil, nil, seconds)
        block_thread.join
      else
        block_thread.raise exception_klass
        block_thread.join
      end
      block_thread.value
    ensure
      reader.close rescue false
      writer.close rescue false
    end
  end

end
