# frozen_string_literal: true

require 'bank'

require 'minitest/autorun'

class TestReconnect < Minitest::Test
  def setup
    Bank.setup!
  end

  def test_transaction_with_reconnect_false
    prev_balance = Bank.fetch_total_balance
    assert_equal(Bank.default_total_balance, prev_balance)

    assert_raises Mysql2::Error::ConnectionError do
      Bank.transfer_balance(client_options: { reconnect: true }) do |client1, client2|
        client2.query("KILL CONNECTION #{client1.thread_id}")
      end
    end

    assert_equal(prev_balance, Bank.fetch_total_balance)
  end

  def test_transaction_with_reconnect_true
    prev_balance = Bank.fetch_total_balance
    assert_equal(Bank.default_total_balance, prev_balance)

    assert_raises Mysql2::Error::ConnectionError do
      Bank.transfer_balance(client_options: { reconnect: true }) do |client1, client2|
        client2.query("KILL CONNECTION #{client1.thread_id}")
      end
    end

    assert_equal(prev_balance, Bank.fetch_total_balance)
  end

  def test_transaction_with_reconnect_false_and_bad_handling
    prev_balance = Bank.fetch_total_balance
    assert_equal(Bank.default_total_balance, prev_balance)

    assert_raises Mysql2::Error do
      Bank.transfer_balance(client_options: { reconnect: false }) do |client1, client2|
        client2.query("KILL CONNECTION #{client1.thread_id}")

        assert_raises(Mysql2::Error::ConnectionError) { client1.query('SELECT 1 AS one') } # MySQL server has gone away
        assert_raises(Mysql2::Error) { client1.query('SELECT 1 AS one') } # MySQL client is not connected
        assert_raises(Mysql2::Error) { client1.query('SELECT 1 AS one') } # client keeps raising exceptions
      end
    end

    assert_equal(prev_balance, Bank.fetch_total_balance)
  end

  def test_transaction_with_reconnect_true_and_bad_handling
    prev_balance = Bank.fetch_total_balance
    assert_equal(Bank.default_total_balance, prev_balance)

    Bank.transfer_balance(client_options: { reconnect: true }) do |client1, client2|
      client2.query("KILL CONNECTION #{client1.thread_id}")

      assert_raises(Mysql2::Error::ConnectionError) { client1.query('SELECT 1 AS one') }
      assert_equal(1, client1.query('SELECT 1 AS one').first['one']) # Implicitly reconnected without exception!!!
    end

    refute_equal(prev_balance, Bank.fetch_total_balance)
  end
end
