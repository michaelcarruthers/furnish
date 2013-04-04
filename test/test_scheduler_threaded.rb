require 'helper'

# NOTE the dummy classes in this file are defined in test/dummy_classes.rb
class TestSchedulerThreaded < Furnish::RestartingSchedulerTestCase
  def setup
    super
    sched.serial = false
  end

  def test_running
    assert(sched.schedule_provision('blarg', SleepyDummy.new))
    sched.run
    assert(sched.running?, 'running after provision')
    sched.teardown
    refute(sched.running?, 'not running after teardown')

    # we have a monitor that's waiting for timeouts in the test suite to abort
    # it if the scheduler crashes.
    #
    # this actually tests that functionality, so kill the monitor prematurely.
    #
    @monitor.kill rescue nil
    assert(sched.schedule_provision('blarg', SleepyFailingDummy.new))
    sched.run
    assert(sched.running?, 'running after provision')
    sleep 3
    assert_raises(RuntimeError, "Could not provision blarg with provisioner SleepyFailingDummy") { sched.running? }
    sched.teardown
    refute(sched.running?, 'not running after teardown')
  end
end
