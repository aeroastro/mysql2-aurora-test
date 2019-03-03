# frozen_string_literal: true

require 'minitest/autorun'

require 'transaction_helper'

class Test < Minitest::Test
  include TransactionHelper

  def client_class
    Mysql2::AWSAurora::Client
  end
end
