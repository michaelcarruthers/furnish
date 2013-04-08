require 'helper'

# NOTE the dummy classes in this file are defined in test/dummy_classes.rb
class TestProvisionerGroup < Furnish::TestCase
  def test_constructor
    dummy = Dummy.new
    pg = Furnish::ProvisionerGroup.new(dummy, 'blarg')
    assert_includes(pg, dummy)
    assert_equal('blarg', pg.name)
    assert_kind_of(Set, pg.dependencies)
    assert_empty(pg.dependencies)
    assert_equal('blarg', dummy.furnish_group_name)

    dummy = Dummy.new
    pg = Furnish::ProvisionerGroup.new([dummy], 'blarg2', %w[blarg])
    assert_includes(pg, dummy)
    assert_equal('blarg2', pg.name)
    assert_equal(Set['blarg'], pg.dependencies)
    assert_equal('blarg2', dummy.furnish_group_name)

    assert_raises(ArgumentError, "A non-empty list of provisioners must be provided") { Furnish::ProvisionerGroup.new([], 'blarg3') }
    assert_raises(ArgumentError, "A non-empty list of provisioners must be provided") { Furnish::ProvisionerGroup.new(nil, 'blarg3') }
  end

  def test_up_down
    Furnish.logger.puts "Testing logging, output muted"

    require 'stringio'
    Furnish.logger = Furnish::Logger.new(StringIO.new, 3)

    store = Palsy::Object.new('dummy')
    dummy = Dummy.new
    pg = Furnish::ProvisionerGroup.new(dummy, 'blarg')

    assert(pg.startup, 'started')
    assert(store[ [pg.name, 'startup'].join("-") ], 'startup ran')
    assert_nil(pg.group_state['index'])
    assert_nil(pg.group_state['provisioner_args'])
    assert_nil(pg.group_state['action'])
    assert_nil(pg.group_state['provisioner'])

    assert(pg.shutdown, 'stopped')
    assert(store[ [pg.name, 'startup'].join("-") ], 'shutdown ran')
    assert_nil(pg.group_state['index'])
    assert_nil(pg.group_state['provisioner_args'])
    assert_nil(pg.group_state['action'])
    assert_nil(pg.group_state['provisioner'])

    pg = Furnish::ProvisionerGroup.new([Dummy.new, StartFailDummy.new], 'track_test')
    assert_raises(RuntimeError, "Could not provision #{pg.name} with provisioner #{dummy.class.name}") { pg.startup({ :foo => 1 }) }
    assert_equal(1, pg.group_state['index'])
    assert_equal(:startup, pg.group_state['action'])
    assert_equal(StartFailDummy, pg.group_state['provisioner'].class)
    assert_equal(true, pg.group_state['provisioner_args'])

    pg = Furnish::ProvisionerGroup.new([Dummy.new, StartExceptionDummy.new], 'track_test')
    assert_raises(RuntimeError, "Could not provision #{pg.name} with provisioner #{dummy.class.name}") { pg.startup({ :foo => 1 }) }
    assert_equal(1, pg.group_state['index'])
    assert_equal(:startup, pg.group_state['action'])
    assert_equal(StartExceptionDummy, pg.group_state['provisioner'].class)
    assert_equal(true, pg.group_state['provisioner_args'])

    pg = Furnish::ProvisionerGroup.new([StopFailDummy.new, Dummy.new], 'track_test')
    assert_raises(RuntimeError, "Could not deprovision #{pg.name}/#{dummy.class.name}") { pg.shutdown }
    assert_equal(1, pg.group_state['index'])
    assert_equal(:shutdown, pg.group_state['action'])
    assert_equal(StopFailDummy, pg.group_state['provisioner'].class)

    pg = Furnish::ProvisionerGroup.new([StopExceptionDummy.new, Dummy.new], 'track_test')
    assert_raises(RuntimeError, "Could not deprovision #{pg.name}/#{dummy.class.name}") { pg.shutdown }
    assert_equal(1, pg.group_state['index'])
    assert_equal(:shutdown, pg.group_state['action'])
    assert_equal(StopExceptionDummy, pg.group_state['provisioner'].class)

    dummy = StartFailDummy.new
    pg = Furnish::ProvisionerGroup.new(dummy, 'blarg2')
    assert_raises(RuntimeError, "Could not provision #{pg.name} with provisioner #{dummy.class.name}") { pg.startup({ :foo => 1 }) }
    assert_equal(0, pg.group_state['index'])
    assert_equal(:startup, pg.group_state['action'])
    assert_equal(dummy.class, pg.group_state['provisioner'].class)
    assert_equal({:foo => 1}, pg.group_state['provisioner_args'])

    dummy = StopFailDummy.new
    pg = Furnish::ProvisionerGroup.new(dummy, 'blarg3')
    assert_raises(RuntimeError, "Could not deprovision #{pg.name}/#{dummy.class.name}") { pg.shutdown }
    assert_equal(0, pg.group_state['index'])
    assert_equal(:shutdown, pg.group_state['action'])
    assert_equal(dummy.class, pg.group_state['provisioner'].class)
    pg.shutdown(true)
    assert_nil(pg.group_state['index'])
    assert_nil(pg.group_state['provisioner_args'])
    assert_nil(pg.group_state['action'])
    assert_nil(pg.group_state['provisioner'])

    dummy = StartExceptionDummy.new
    pg = Furnish::ProvisionerGroup.new(dummy, 'blarg4')
    assert_raises(RuntimeError, "Could not provision #{pg.name} with provisioner #{dummy.class.name}") { pg.startup }
    assert_equal(:startup, pg.group_state['action'])
    assert_equal(dummy.class, pg.group_state['provisioner'].class)

    dummy = StopExceptionDummy.new
    pg = Furnish::ProvisionerGroup.new(dummy, 'blarg4')
    assert_raises(RuntimeError, "Could not deprovision #{pg.name}/#{dummy.class.name}") { pg.shutdown }
    assert_equal(0, pg.group_state['index'])
    assert_equal(:shutdown, pg.group_state['action'])
    assert_equal(dummy.class, pg.group_state['provisioner'].class)
    pg.shutdown(true)
    assert_nil(pg.group_state['index'])
    assert_nil(pg.group_state['provisioner_args'])
    assert_nil(pg.group_state['action'])
    assert_nil(pg.group_state['provisioner'])
    sleep 0.1 # wait for flush
    assert_includes(Furnish.logger.string.split(/\n/), "Deprovision of #{pg.name}[#{dummy.class.name}] had errors:")
  end

  def test_recover
    [ RecoverableDummy, RaisingRecoverableDummy ].each do |prov|
      pg = Furnish::ProvisionerGroup.new(prov.new, 'recover1')
      assert_raises(RuntimeError) { pg.startup }
      assert_equal(0, pg.group_state['index'])
      assert_equal(:startup, pg.group_state['action'])
      assert_equal(prov, pg.group_state['provisioner'].class)
      assert_equal({ }, pg.group_state['provisioner_args'])
      assert(pg.recover)
      assert_nil(pg.group_state['index'])
      assert_nil(pg.group_state['provisioner_args'])
      assert_nil(pg.group_state['action'])
      assert_nil(pg.group_state['provisioner'])
      #
      # FIXME encode is needed for issue #2 in palsy
      #
      assert(pg.first.run_state['startup'.encode('UTF-8')])

      pg = Furnish::ProvisionerGroup.new(prov.new, 'recover2')
      assert_raises(RuntimeError) { pg.shutdown }
      assert_equal(0, pg.group_state['index'])
      assert_equal(:shutdown, pg.group_state['action'])
      assert_equal(prov, pg.group_state['provisioner'].class)
      assert_nil(pg.group_state['provisioner_args'])
      assert(pg.recover)
      assert_nil(pg.group_state['index'])
      assert_nil(pg.group_state['provisioner_args'])
      assert_nil(pg.group_state['action'])
      assert_nil(pg.group_state['provisioner'])
      #
      # FIXME encode is needed for issue #2 in palsy
      #
      assert(pg.first.run_state['shutdown'.encode('UTF-8')])
    end
  end
end
