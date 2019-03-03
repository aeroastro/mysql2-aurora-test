# frozen_string_literal: true

require 'minitest/autorun'

require 'transaction_helper'

class TestMysql2 < Minitest::Test
  include TransactionHelper

  def client_class
    Mysql2::Client
  end
end
