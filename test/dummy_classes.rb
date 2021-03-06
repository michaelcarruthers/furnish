#
# Several dummy class mutations (inherited from Furnish::Provisioner::Dummy) we
# use in tests.
#

require 'furnish/provisioners/dummy'

Dummy = Furnish::Provisioner::Dummy unless defined? Dummy

#
# FIXME move all these dummy classes to their own file
#
# FIXME Probably should generate these classes
#

class ReturnsInfoDummy < Dummy
  def startup(args={})
    retval = { :startup_blah => [1] }
    super(retval)
    return retval
  end

  def shutdown(args={})
    retval = { :shutdown_blah => [1] }
    super(retval)
    return retval
  end
end

class AcceptsIntegerBarDummy < Dummy
  configure_startup do
    accepts :bar, "bar", Integer
  end
end

class YieldsIntegerBarDummy < Dummy
  configure_startup do
    yields :bar, "bar", Integer
  end
end

class AcceptsStringBarDummy < Dummy
  configure_startup do
    accepts :bar, "bar", String
  end
end

class YieldsStringBarDummy < Dummy
  configure_startup do
    yields :bar, "bar", String
  end
end

class AcceptsFooDummy < Dummy
  configure_startup do
    accepts :foo, "foo", String
  end
end

class YieldsFooDummy < Dummy
  configure_startup do
    yields :foo, "foo", String
  end
end

class RequiresBarDummy < Dummy
  configure_startup do
    requires :bar, "bar", Integer
  end
end

class YieldsFooBarDummy < Dummy
  configure_startup do
    yields :bar, "bar", Integer
    yields :foo, "foo", String
  end
end

class RequiresBarAcceptsFooDummy < Dummy
  configure_startup do
    requires :bar, "bar", Integer
    accepts :foo, "foo", String
  end
end

class ShutdownAcceptsIntegerBarDummy < Dummy
  configure_shutdown do
    accepts :bar, "bar", Integer
  end
end

class ShutdownYieldsIntegerBarDummy < Dummy
  configure_shutdown do
    yields :bar, "bar", Integer
  end
end

class ShutdownAcceptsStringBarDummy < Dummy
  configure_shutdown do
    accepts :bar, "bar", String
  end
end

class ShutdownYieldsStringBarDummy < Dummy
  configure_shutdown do
    yields :bar, "bar", String
  end
end

class ShutdownAcceptsFooDummy < Dummy
  configure_shutdown do
    accepts :foo, "foo", String
  end
end

class ShutdownYieldsFooDummy < Dummy
  configure_shutdown do
    yields :foo, "foo", String
  end
end

class ShutdownRequiresBarDummy < Dummy
  configure_shutdown do
    requires :bar, "bar", Integer
  end
end

class ShutdownYieldsFooBarDummy < Dummy
  configure_shutdown do
    yields :bar, "bar", Integer
    yields :foo, "foo", String
  end
end

class ShutdownRequiresBarAcceptsFooDummy < Dummy
  configure_shutdown do
    requires :bar, "bar", Integer
    accepts :foo, "foo", String
  end
end

class StartFailDummy < Dummy
  def startup(args={ })
    super
    false
  end
end

class StopFailDummy < Dummy
  def shutdown(args={ })
    super
    false
  end
end

class StartExceptionDummy < Dummy
  def startup(args={ })
    super
    raise "ermagherd startup"
  end
end

class StopExceptionDummy < Dummy
  def shutdown(args={ })
    super
    raise "ermagherd shutdown"
  end
end

class APIDummy < Furnish::Provisioner::API
  furnish_property :foo, "does things with foo", Integer
  furnish_property "a_string"
  attr_accessor :bar
end

class BadDummy < Furnish::Provisioner::Dummy
  attr_accessor :name

  # this retardation lets us make it look like furnish_group_name doesn't exist
  def respond_to?(meth, include_all=true)
    super unless [:furnish_group_name, :furnish_group_name=].include?(meth)
  end
end

class SleepyDummy < Dummy
  def startup(args={ })
    sleep 1
    super
  end
end

class SleepyFailingDummy < SleepyDummy
  def startup(args={ })
    super
    return false
  end
end

class BrokenRecoverAPIDummy < Dummy
  allows_recovery
end

class RecoverableDummy < Dummy
  allows_recovery

  def startup(args={ })
    super
    run_state[__method__] = @recovered
    return @recovered
  end

  def shutdown(args={ })
    super
    run_state[__method__] = @recovered
    return @recovered
  end

  def recover(state, args)
    @recovered = { state => true }
    return true
  end
end

class RaisingRecoverableDummy < Dummy
  allows_recovery

  def startup(args={ })
    super
    run_state[__method__] = @recovered
    raise unless @recovered
    return @recovered
  end

  def shutdown(args={ })
    super
    run_state[__method__] = @recovered
    raise unless @recovered
    return @recovered
  end

  def recover(state, args)
    @recovered = { state => true }
    return true
  end
end

class FailedRecoverDummy < Dummy
  allows_recovery

  def startup(args={ })
    super
    return run_state[__method__] = false
  end

  def shutdown(args={ })
    super
    return run_state[__method__] = false
  end

  def recover(state, args)
    return run_state[__method__] = false
  end
end

class ReturnsDataDummy < Dummy
  def startup(args={ })
    super
    return({ :started => 1 })
  end

  def shutdown(args={ })
    super
    return({ :stopped => 1 })
  end
end
