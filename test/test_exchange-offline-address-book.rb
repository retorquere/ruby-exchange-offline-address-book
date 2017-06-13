require 'dotenv/load'

require 'minitest/autorun'
require 'exchange-offline-address-book'

class EOABTest < Minitest::Test
  def test_downlod
    oab = OfflineAddressBook.new(username: ENV['USERNAME'], password: ENV['PASSWORD'], email: ENV['EMAIL'])
    puts oab.addressbook
  end
end
