require "test_helper"

class EventsEngineAbsractTest < Dashing::Test
    def setup
    end
    def test_exceptions_raised
        ee = EventsEngine.new
        assert_raises(RuntimeError) {ee.send_event('a','b')}
        assert_raises(RuntimeError) {ee.stop}
    end
    def test_engine_registrations
        ee = EventsEngine.new
        assert_raises(RuntimeError) {EventsEngine.create "not_exist"}
    end
end
