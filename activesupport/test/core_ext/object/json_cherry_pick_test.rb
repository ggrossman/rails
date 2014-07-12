require 'abstract_unit'

# These test cases were added to test that cherry-picking the json extensions
# works correctly, primarily for dependencies problems reported in #16131. They
# need to be executed in isolation to reproduce the scenario correctly, because
# other test cases might have already loaded additional dependencies.

if Process.respond_to?(:fork)
  class JsonCherryPickTest < ActiveSupport::TestCase
    def test_time_as_json
      within_new_process do
        require 'active_support'
        require 'active_support/core_ext/object/json'

        expected = Time.new(2004, 7, 25)
        actual   = Time.parse(expected.as_json)

        assert_equal expected, actual
      end
    end

    def test_date_as_json
      within_new_process do
        require 'active_support'
        require 'active_support/core_ext/object/json'

        expected = Date.new(2004, 7, 25)
        actual   = Date.parse(expected.as_json)

        assert_equal expected, actual
      end
    end

    def test_datetime_as_json
      within_new_process do
        require 'active_support'
        require 'active_support/core_ext/object/json'

        expected = DateTime.new(2004, 7, 25)
        actual   = DateTime.parse(expected.as_json)

        assert_equal expected, actual
      end
    end

    private
      def within_new_process(&block)
        rd, wr = IO.pipe
        rd.binmode
        wr.binmode

        pid = fork do
          rd.close

          begin
            block.call
            exit!(true)
          rescue Exception => e
            wr.write Marshal.dump(e)
            exit!(false)
          ensure
            wr.close
          end
        end

        wr.close

        Process.waitpid pid

        raise Marshal.load(rd.read) unless $?.success?
      end
  end
end
