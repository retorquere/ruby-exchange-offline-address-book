#!/usr/bin/env ruby

require 'dotenv/load'

require 'autodiscover'
#require "autodiscover/debug"

require 'yaml'
require 'nokogiri'
require 'tempfile'
require 'json'
require 'ostruct'

require 'curb'
require_relative 'exchange-offline-address-book/parser'
require_relative 'exchange-offline-address-book/mspack'

class OfflineAddressBook
  def initialize(email: nil, password: nil, username: nil, cachedir: nil, update: true)
    @email = email
    @username = username || email
    @password = password
    @cachedir = cachedir
    @update = update
  end

  def download(file, target = nil)
    client = Curl::Easy.new(baseurl + file)
    client.http_auth_types = :ntlm
    client.username = @username
    client.password = @password
    client.perform

    return client.body_str if target.nil?

    open(target, 'wb'){|f| f.write(client.body_str) }
  end

  def baseurl
    @baseurl ||= begin
      client = Autodiscover::Client.new(email: @email, password: @password, username: @username)
      data = client.autodiscover(ignore_ssl_errors: true)
      raise "No data" unless data
      data.response['Account']['Protocol'].detect{|p| p['OABUrl'] && p['Type'] == 'EXPR'}['OABUrl']
    end
  end

  def addressbook
    @addressbook ||= begin
      lzx = nil
      if !@update & @cachedir
        oab = Dir[File.join(@cachedir, '*.oab')][0]
        lzx = File.basename(oab, File.extname(oab)) + '.lzx' if oab
      end

      lzx ||= Nokogiri::XML(download('oab.xml')).at('//Full').inner_text
      oab = File.basename(lzx, File.extname(lzx)) + '.oab'

      if @cachedir && File.file?(File.join(@cachedir, oab))
        oab = File.join(@cachedir, oab)
      else
        if @cachedir
          %w{*.oab *.lzx *.yml *.json}.each{|ext|
            Dir[File.join(@cachedir, ext)].each{|f| File.unlink(f) }
          }
          download(lzx, File.join(@cachedir, lzx))
          lzx = File.join(@cachedir, lzx)
          @oab = File.join(@cachedir, oab)
        else
          _lzx = Tempfile.new('lzx')
          download(lzx, _lzx.path)
          lzx = _lzx.path
          oab = Tempfile.new('oab').path
        end

        LibMsPack.oab_decompress(lzx, oab)
      end

      oab
    end
  end

  def cache
    @cache ||= File.join(File.dirname(addressbook), File.basename(addressbook, File.extname(addressbook)) + '.json')
  end

  def header
    @parsed ||= Parser.new(addressbook)
    @parsed.header
  end

  def records
    @records ||= begin
      if File.file?(cache)
        parsed = JSON.parse(open(cache).read).collect{|record| OpenStruct.new(record) }
      else
        @parsed ||= Parser.new(addressbook)
        parsed = @parsed.records.collect{|record|
          record.to_h.each_pair{|k, v|
            record[k] = v[0] if v.length == 1
          }
          # no idea what's going on here
          record.AddressBookObjectGuid = record.AddressBookObjectGuid.inspect if record.AddressBookObjectGuid
          record
        }
        open(cache, 'w'){|f| f.write(JSON.pretty_generate(parsed.collect{|r| r.to_h}))} if @cachedir
      end

      parsed
    end
  end
end
