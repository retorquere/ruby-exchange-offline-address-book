require 'dotenv/load'

require 'minitest/autorun'
require 'exchange-offline-address-book'

class EOABTest < Minitest::Test
#  def test_downlod
#    oab = OfflineAddressBook.new(username: ENV['EWS_USERNAME'], password: ENV['EWS_PASSWORD'], email: ENV['EWS_EMAIL'])
#    puts oab.addressbook
#  end
#  def test_baseurl
#    oab = OfflineAddressBook.new(username: ENV['EWS_USERNAME'], password: ENV['EWS_PASSWORD'], email: ENV['EWS_EMAIL'])
#    puts oab.baseurl
#  end
#  def test_given_baseurl
#    oab = OfflineAddressBook.new(username: ENV['EWS_USERNAME'], password: ENV['EWS_PASSWORD'], email: ENV['EWS_EMAIL'], baseurl: ENV['EWS_BASEURL'])
#    puts oab.addressbook
#  end
  def test_records
    oab = OfflineAddressBook.new(username: ENV['EWS_USERNAME'], password: ENV['EWS_PASSWORD'], email: ENV['EWS_EMAIL'])
    puts oab.records.length
  end
end
