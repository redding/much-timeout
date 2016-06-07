require 'assert'
require 'much-timeout'

module MuchTimeout

  class UnitTests < Assert::Context
    desc "MuchTimeout"
    setup do
      @module = MuchTimeout
    end
    subject{ @module }

    should have_imeths :timeout

    should "know its TimeoutError" do
      assert_true subject::TimeoutError < Interrupt
    end

    should "know its pipe signal" do
      assert_equal '.', subject::PIPE_SIGNAL
    end

  end

  class TimeoutSetupTests < UnitTests
    setup do
      @mutex    = Mutex.new
      @cond_var = ConditionVariable.new

      @seconds = 0.01
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

    should "interrupt and raise if a custom exception is given and block times out" do
      exception = Class.new(RuntimeError)

      assert_raises(exception) do
        subject.timeout(@seconds, exception) do
          @mutex.synchronize{ @cond_var.wait(@mutex) }
        end
      end
    end

    should "not interrupt and return the block's return value if there is no timeout" do
      exp = Factory.string
      val = nil

      assert_nothing_raised do
        val = subject.timeout(@seconds){ exp }
      end
      assert_equal exp, val
    end

    should "raise any exception that the block raises" do
      exception = Class.new(RuntimeError)

      assert_raises(exception) do
        subject.timeout(@seconds){ raise exception }
      end
    end

    should "complain if given a nil seconds value" do
      assert_raises(ArgumentError) do
        subject.timeout(nil){ }
      end
    end

    should "complain if given a non-numeric seconds value" do
      assert_raises(ArgumentError) do
        subject.timeout(Factory.string){ }
      end
    end

  end

end
