# frozen_string_literal: true

require "thread"
require "much-timeout/version"

module MuchTimeout
  TimeoutError = Class.new(Interrupt) # rubocop:disable Lint/InheritException

  PIPE_SIGNAL = "."

  def self.timeout(seconds, klass = nil, &block)
    if seconds.nil?
      raise ArgumentError, "please specify a non-nil seconds value"
    end
    unless seconds.is_a?(::Numeric)
      raise ArgumentError, "please specify a numeric seconds value " \
                           "(`#{seconds.inspect}` was given)"
    end
    exception_klass = klass || TimeoutError
    reader, writer  = IO.pipe

    begin
      main_thread = Thread.current
      io_select_thread ||= Thread.new do
        unless ::IO.select([reader], nil, nil, seconds)
          main_thread.raise exception_klass
        end
      end
      begin
        block.call
      ensure
        begin
          writer.write_nonblock(PIPE_SIGNAL)
        rescue
          false
        end
        io_select_thread.join
      end
    ensure
      begin
        reader.close
      rescue
        false
      end
      begin
        writer.close
      rescue
        false
      end
    end
  end

  def self.optional_timeout(seconds, klass = nil, &block)
    if !seconds.nil?
      timeout(seconds, klass, &block)
    else
      block.call
    end
  end

  def self.just_timeout(seconds, args)
    args ||= {}
    if args[:do].nil?
      raise ArgumentError, "you need to specify a :do block arg to call"
    end
    unless args[:do].is_a?(::Proc)
      raise ArgumentError, "you need pass a Proc as the :do arg " \
                           "(`#{args[:do].inspect}` was given)"
    end
    if !args[:on_timeout].nil? && !args[:on_timeout].is_a?(::Proc)
      raise ArgumentError, "you need pass a Proc as the :on_timeout arg " \
                           "(`#{args[:on_timeout].inspect}` was given)"
    end

    begin
      timeout(seconds, &args[:do])
    rescue TimeoutError
      (args[:on_timeout] || proc{}).call
    end
  end

  def self.just_optional_timeout(seconds, args)
    args ||= {}
    if args[:do].nil?
      raise ArgumentError, "you need to specify a :do block arg to call"
    end
    unless args[:do].is_a?(::Proc)
      raise ArgumentError, "you need pass a Proc as the :do arg " \
                           "(`#{args[:do].inspect}` was given)"
    end

    if !seconds.nil?
      just_timeout(seconds, args)
    else
      args[:do].call
    end
  end
end
