# frozen_string_literal: true

require "assert"
require "much-timeout"

module MuchTimeout
  class UnitTests < Assert::Context
    desc "MuchTimeout"
    setup do
      @module = MuchTimeout
    end
    subject{ @module }

    should have_imeths :timeout, :optional_timeout
    should have_imeths :just_timeout, :just_optional_timeout

    should "know its TimeoutError" do
      assert_true subject::TimeoutError < Interrupt
    end

    should "know its pipe signal" do
      assert_equal ".", subject::PIPE_SIGNAL
    end
  end

  class TimeoutSetupTests < UnitTests
    setup do
      @mutex      = Mutex.new
      @cond_var   = ConditionVariable.new
      @seconds    = 0.01
      @exception  = Class.new(RuntimeError)
      @return_val = Factory.string
    end
    teardown do
      @cond_var.broadcast
    end
  end

  class TimeoutTests < TimeoutSetupTests
    desc "`timeout` method"

    should "interrupt and raise if the block takes too long to run" do
      assert_raises(TimeoutError) do
        subject.timeout(@seconds) do
          @mutex.synchronize{ @cond_var.wait(@mutex) }
        end
      end
    end

    should "interrupt and raise if a custom exception is given and block "\
           "times out" do
      assert_raises(@exception) do
        subject.timeout(@seconds, @exception) do
          @mutex.synchronize{ @cond_var.wait(@mutex) }
        end
      end
    end

    should "not interrupt and return the block's return value if there "\
           "is no timeout" do
      val = nil
      assert_nothing_raised do
        val = subject.timeout(@seconds){ @return_val }
      end
      assert_equal @return_val, val
    end

    should "raise any exception that the block raises" do
      assert_raises(@exception) do
        subject.timeout(@seconds){ raise @exception }
      end
    end

    should "complain if given a nil seconds value" do
      assert_raises(ArgumentError) do
        subject.timeout(nil){}
      end
    end

    should "complain if given a non-numeric seconds value" do
      assert_raises(ArgumentError) do
        subject.timeout(Factory.string){}
      end
    end
  end

  class OptionalTimeoutTests < TimeoutSetupTests
    desc "`optional_timeout` method"

    should "call `timeout` with any given args if seconds is not nil" do
      # this repeats the relevent tests from the TimeoutTests above

      assert_raises(TimeoutError) do
        subject.optional_timeout(@seconds) do
          @mutex.synchronize{ @cond_var.wait(@mutex) }
        end
      end

      assert_raises(@exception) do
        subject.optional_timeout(@seconds, @exception) do
          @mutex.synchronize{ @cond_var.wait(@mutex) }
        end
      end

      val = nil
      assert_nothing_raised do
        val = subject.optional_timeout(@seconds){ @return_val }
      end
      assert_equal @return_val, val

      assert_raises(@exception) do
        subject.optional_timeout(@seconds){ raise @exception }
      end

      assert_raises(ArgumentError) do
        subject.optional_timeout(Factory.string){}
      end
    end

    should "call the given block directly if seconds is nil" do
      val = nil
      assert_nothing_raised do
        val =
          subject.optional_timeout(nil) do
            sleep @seconds
            @return_val
          end
      end
      assert_equal @return_val, val

      assert_raises(@exception) do
        subject.optional_timeout(nil){ raise @exception }
      end
    end
  end

  class JustTimeoutTests < TimeoutSetupTests
    desc "`just_timeout` method"
    setup do
      @val_set = nil
    end

    should "call `timeout` with the given seconds and :do arg" do
      # this repeats the relevent tests from the TimeoutTests above

      assert_nothing_raised do
        subject.just_timeout(@seconds, do: proc{
          @mutex.synchronize{ @cond_var.wait(@mutex) }
          @val_set = Factory.string
        },)
      end
      assert_nil @val_set

      val = nil
      assert_nothing_raised do
        val = subject.just_timeout(@seconds, do: proc{ @return_val })
      end
      assert_equal @return_val, val

      assert_raises(@exception) do
        subject.just_timeout(@seconds, do: proc{ raise @exception })
      end

      assert_raises(ArgumentError) do
        subject.just_timeout(nil, do: proc{})
      end

      assert_raises(ArgumentError) do
        subject.just_timeout(Factory.string, do: proc{})
      end
    end

    should "call any given :on_timeout arg if a timeout occurs" do
      exp = Factory.string
      assert_nothing_raised do
        subject.just_timeout(@seconds, {
          do: proc{
            @mutex.synchronize{ @cond_var.wait(@mutex) }
          },
          on_timeout: proc{ @val_set = exp },
        },)
      end
      assert_equal exp, @val_set

      @val_set = val = nil
      assert_nothing_raised do
        val = subject.just_timeout(@seconds, {
          do: proc{ @return_val },
          on_timeout: proc{ @val_set = exp },
        },)
      end
      assert_equal @return_val, val
      assert_nil @val_set
    end

    should "complain if not given a :do arg" do
      assert_raises(ArgumentError) do
        subject.just_timeout(@seconds){}
      end
      assert_raises(ArgumentError) do
        subject.just_timeout(@seconds, do: nil)
      end
    end

    should "complain if given a non-proc :do arg" do
      assert_raises(ArgumentError) do
        subject.just_timeout(@seconds, do: Factory.string)
      end
    end

    should "complain if given a non-proc :on_timeout arg" do
      assert_raises(ArgumentError) do
        subject.just_timeout(@seconds, {
          do: proc{},
          on_timeout: Factory.string,
        },)
      end
    end
  end

  class JustOptionalTimeoutTests < TimeoutSetupTests
    desc "`just_optional_timeout` method"
    setup do
      @val_set = nil
    end

    should "call `optional_timeout` with the given seconds and :do arg" do
      # this repeats the relevent tests from the JustTimeoutTests above

      assert_nothing_raised do
        subject.just_optional_timeout(@seconds, do: proc{
          @mutex.synchronize{ @cond_var.wait(@mutex) }
          @val_set = Factory.string
        },)
      end
      assert_nil @val_set

      val = nil
      assert_nothing_raised do
        val =
          subject.just_optional_timeout(@seconds, do: proc{ @return_val })
      end
      assert_equal @return_val, val

      assert_raises(@exception) do
        subject.just_optional_timeout(@seconds, do: proc{ raise @exception })
      end

      assert_raises(ArgumentError) do
        subject.just_optional_timeout(Factory.string, do: proc{})
      end

      exp = Factory.string
      assert_nothing_raised do
        subject.just_optional_timeout(@seconds, {
          do: proc{
            @mutex.synchronize{ @cond_var.wait(@mutex) }
          },
          on_timeout: proc{ @val_set = exp },
        },)
      end
      assert_equal exp, @val_set

      @val_set = val = nil
      assert_nothing_raised do
        val = subject.just_optional_timeout(@seconds, {
          do: proc{ @return_val },
          on_timeout: proc{ @val_set = exp },
        },)
      end
      assert_equal @return_val, val
      assert_nil @val_set

      assert_raises(ArgumentError) do
        subject.just_optional_timeout(@seconds){}
      end
      assert_raises(ArgumentError) do
        subject.just_optional_timeout(@seconds, do: nil)
      end

      assert_raises(ArgumentError) do
        subject.just_optional_timeout(@seconds, do: Factory.string)
      end

      assert_raises(ArgumentError) do
        subject.just_optional_timeout(@seconds, {
          do: proc{},
          on_timeout: Factory.string,
        },)
      end
    end

    should "call the given :do arg directly if seconds is nil" do
      val = nil
      assert_nothing_raised do
        val = subject.just_optional_timeout(nil, do: proc{
          sleep @seconds
          @return_val
        },)
      end
      assert_equal @return_val, val

      assert_raises(@exception) do
        subject.just_optional_timeout(nil, do: proc{ raise @exception })
      end
    end

    should "complain if not given a :do arg" do
      assert_raises(ArgumentError) do
        subject.just_optional_timeout([@seconds, nil].sample){}
      end
      assert_raises(ArgumentError) do
        subject.just_optional_timeout([@seconds, nil].sample, do: nil)
      end
    end

    should "complain if given a non-proc :do arg" do
      assert_raises(ArgumentError) do
        subject.just_optional_timeout(
          [@seconds, nil].sample,
          do: Factory.string,
        )
      end
    end
  end
end
