#!/usr/bin/env ruby

require 'minitest/autorun'
require 'hola_hxcan_1'

class HolaTest < Minitest::Test
    def test_english_hello
        assert_equal "hello world",
                HolaHxcan1.hi("english")
    end
    
    def test_any_hello
        assert_equal "hello world",
                HolaHxcan1.hi("ruby")
    end
    
    def test_spanish_hello
        assert_equal "hola mundo",
                HolaHxcan1.hi("spanish")
    end
end
