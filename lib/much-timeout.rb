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
      raise ArgumentError, "please specify a numeric seconds value " \
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

  def self.optional_timeout(seconds, klass = nil, &block)
    if !seconds.nil?
      self.timeout(seconds, klass, &block)
    else
      block.call
    end
  end

  def self.just_timeout(seconds, args)
    args ||= {}
    if args[:do].nil?
      raise ArgumentError, 'you need to specify a :do block arg to call'
    end
    if !args[:do].kind_of?(::Proc)
      raise ArgumentError, "you need pass a Proc as the :do arg " \
                           "(`#{args[:do].inspect}` was given)"
    end
    if !args[:on_timeout].nil? && !args[:on_timeout].kind_of?(::Proc)
      raise ArgumentError, "you need pass a Proc as the :on_timeout arg " \
                           "(`#{args[:on_timeout].inspect}` was given)"
    end

    begin
      self.timeout(seconds, &args[:do])
    rescue TimeoutError
      (args[:on_timeout] || proc{ }).call
    end
  end

  def self.just_optional_timeout(seconds, args)
    args ||= {}
    if args[:do].nil?
      raise ArgumentError, 'you need to specify a :do block arg to call'
    end
    if !args[:do].kind_of?(::Proc)
      raise ArgumentError, "you need pass a Proc as the :do arg " \
                           "(`#{args[:do].inspect}` was given)"
    end

    if !seconds.nil?
      self.just_timeout(seconds, args)
    else
      args[:do].call
    end
  end

end
