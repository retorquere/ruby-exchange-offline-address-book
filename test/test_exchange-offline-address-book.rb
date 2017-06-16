require 'dotenv/load'

require 'minitest/autorun'
require 'exchange-offline-address-book'

ENV['DEBUG'] = 'true'

class EOABTest < Minitest::Test
  def test_downlod
    oab = OfflineAddressBook.new(username: ENV['USERNAME'], password: ENV['PASSWORD'], email: ENV['EMAIL'])
    puts oab.addressbook
  end
  def test_baseurl
    oab = OfflineAddressBook.new(username: ENV['USERNAME'], password: ENV['PASSWORD'], email: ENV['EMAIL'])
    puts oab.baseurl
  end
  def test_given_baseurl
    oab = OfflineAddressBook.new(username: ENV['USERNAME'], password: ENV['PASSWORD'], email: ENV['EMAIL'], baseurl: ENV['BASEURL'])
    puts oab.addressbook
  end
end
