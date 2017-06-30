#!/usr/bin/env ruby

require 'dotenv/load'

require 'autodiscover'

require "autodiscover/debug" if ENV['DEBUG']
require 'yaml'
require 'nokogiri'
require 'json'
require 'shellwords'
require 'tmpdir'

require_relative 'exchange-offline-address-book/parser'
require_relative 'exchange-offline-address-book/mspack'

module Exchange
  module OfflineAddressBook

    class AddressBook
      def initialize(email: nil, password: nil, username: nil, cachedir: nil, baseurl: nil, update: true)
        @email = email
        @username = username || email
        @password = password
        @cachedir = cachedir
        @update = update
        @baseurl = baseurl

        if cachedir
          fetch_to(cachedir)
        else
          Dir.mktmpdir{|dir| fetch_to(dir) }
        end
      end

      attr_reader :records

      def baseurl
        @baseurl ||= begin
          client = Autodiscover::Client.new(email: @email, password: @password, username: @username)
          data = client.autodiscover(ignore_ssl_errors: true)
          raise "No data" unless data
          data.response['Account']['Protocol'].detect{|p| p['OABUrl'] && p['Type'] == 'EXPR'}['OABUrl']
        end
      end

      def header
        @parsed ||= Exchange::OfflineAddressBook::Parser.new(addressbook)
        @parsed.header
      end

      def load(file)
        raise "Not loading temporary file" unless @cachedir
        @records = JSON.parse(open(file).read, object_class: Exchange::OfflineAddressBook::Record)
      end

      def save(file)
        raise "Not saving to temporary file" unless @cachedir
        open(cache, 'w'){|f| f.write(JSON.pretty_generate(@records)) }
      end

      private

      def fetch_to(dir)
        begin
          @dir = dir

          if File.file?(cache)
            load(cache)
            return
          end

          if !File.file?(addressbook)
            %w{json oab lzx}.each{|ext|
              Dir[File.join(@dir, "*.#{ext}")].each{|f| File.delete(f) }
            }
            lzx = File.basename(addressbook, File.extname(addressbook)) + '.lzx'
            puts "OfflineAddressBook: Downloading #{lzx}" if ENV['DEBUG']
            download(lzx)
            puts "OfflineAddressBook: Decompressing #{lzx} to #{addressbook}" if ENV['DEBUG']
            LibMsPack.oab_decompress(File.join(@dir, lzx), addressbook)
          end
          puts "OfflineAddressBook: Addressbook ready at #{addressbook}" if ENV['DEBUG']

          parsed = Exchange::OfflineAddressBook::Parser.new(addressbook)
          @records = parsed.records.collect{|record|
            record.to_h.each_pair{|k, v|
              record[k] = v[0] if v.length == 1
            }
            # no idea what's going on here
            record.AddressBookObjectGuid = record.AddressBookObjectGuid.inspect if record.AddressBookObjectGuid
            record
          }
          save(cache)
        ensure
          @dir = nil
        end
      end

      def download(name)
        puts "curl --#{ENV['DEBUG'] ? 'verbose' : 'silent'} --ntlm --user #{[@username, @password].join(':').shellescape} #{[baseurl, name].join('').shellescape} -o #{File.join(@dir, name).shellescape}" if ENV['DEBUG']
        system "curl --#{ENV['DEBUG'] ? 'verbose' : 'silent'} --ntlm --user #{[@username, @password].join(':').shellescape} #{[baseurl, name].join('').shellescape} -o #{File.join(@dir, name).shellescape}"
        return File.join(@dir, name)
      end

      def addressbook
        @addressbook ||= begin
          if !@update && Dir[File.join(@dir, '*.oab')].length > 0
            oab = File.basename(Dir[File.join(@dir, '*.oab')][0])
            puts "OfflineAddressBook: Reusing #{oab}" if ENV['DEBUG']
          else
            lzx = Nokogiri::XML(open(download('oab.xml'))).at('//Full').inner_text
            oab = File.basename(lzx, File.extname(lzx)) + '.oab'
          end

          File.join(@dir, oab)
        end
      end

      def cache
        @cache ||= File.join(@dir, File.basename(addressbook, File.extname(addressbook)) + '.json')
      end
    end

  end
end
