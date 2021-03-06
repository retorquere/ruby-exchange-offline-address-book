require 'dotenv/load'

require 'minitest/autorun'
require 'exchange-offline-address-book'

require 'tmpdir'

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
#  def test_records
#    oab = Exchange::OfflineAddressBook::AddressBook.new(username: ENV['EWS_USERNAME'], password: ENV['EWS_PASSWORD'], email: ENV['EWS_EMAIL'])
#    puts oab.records.length
#  end
#  def test_cache
#    Dir.mktmpdir{|dir|
#      oab = Exchange::OfflineAddressBook::AddressBook.new(cachedir: dir, username: ENV['EWS_USERNAME'], password: ENV['EWS_PASSWORD'], app_password: ENV['EWS_APP_PASSWORD'], email: ENV['EWS_EMAIL'])
#      puts oab.records.length
#    }
#  end
  def test_debug
    oab = Exchange::OfflineAddressBook::AddressBook.new(cachedir: 'tmp', username: ENV['EWS_USERNAME'], password: ENV['EWS_PASSWORD'], app_password: ENV['EWS_APP_PASSWORD'], email: ENV['EWS_EMAIL'])
    puts oab.records.length
  end
end
