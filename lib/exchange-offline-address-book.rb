#!/usr/bin/env ruby

require 'dotenv/load'

require 'autodiscover'
# until https://github.com/WinRb/autodiscover/pull/9 is merged
if Autodiscover::VERSION == '1.0.2'
  module Autodiscover
    class PoxRequest

      def autodiscover
        available_urls.each do |url|
          puts "Trying #{url} for #{client.email}..."
          begin
            response = client.http.post(url, request_body, {'Content-Type' => 'text/xml; charset=utf-8'})
            redirs = [url]
            while (response.status == 301 || response.status == 302) && response.headers['Location']
              raise "Redirect loop for #{url}" if redirs.include?(response.headers['Location'])
              redirs << response.headers['Location']
              puts "Re-trying on redirect #{response.headers['Location']}..."
              response = client.http.post(response.headers['Location'], request_body, {'Content-Type' => 'text/xml; charset=utf-8'})
            end
            return PoxResponse.new(response.body) if good_response?(response)
          rescue SocketError, Errno::EHOSTUNREACH, Errno::ENETUNREACH, Errno::ECONNREFUSED, HTTPClient::ConnectTimeoutError
            next
          rescue OpenSSL::SSL::SSLError
            options[:ignore_ssl_errors] ? next : raise
          end
        end
      end

    end
  end
end

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
      def initialize(email: nil, password: nil, username: nil, cachedir: nil, baseurl: nil, update: true, app_password: nil)
        @email = email
        @username = username || email
        @password = password
        @app_password = app_password
        @cachedir = cachedir
        @update = update

        if baseurl
          @baseurl = baseurl
        else
          client = Autodiscover::Client.new(email: @email, password: @password, username: @username)
          data = client.autodiscover(ignore_ssl_errors: true)
          raise "No data" unless data

          if data.response['Account']['Action'] == 'redirectAddr'
            @app_email = data.response['Account']['RedirectAddr']
            puts "Redirect to #{@app_email}"
            raise "Autodiscover loop for #{@app_email}" if @app_email.downcase == @email.downcase
            client = Autodiscover::Client.new(email: @app_email, username: @username, password: @app_password)
            data = client.autodiscover(ignore_ssl_errors: true)
            if data.nil? && @app_password
              client = Autodiscover::Client.new(email: @app_email, username: @username, password: @app_password)
              data = client.autodiscover(ignore_ssl_errors: true)
            end
            raise "No data for redirect" unless data
          else
            @app_password = nil
          end

          @baseurl = data.response['Account']['Protocol'].detect{|p| p['OABUrl'] && p['Type'] == 'EXPR'}['OABUrl']
          "Found #{@baseurl}"
        end

        if cachedir
          fetch_to(cachedir)
        else
          Dir.mktmpdir{|dir| fetch_to(dir) }
        end
      end

      attr_reader :records

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

      def cache
        @cache ||= File.join(@dir || @cachedir, File.basename(addressbook, File.extname(addressbook)) + '.json')
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
        [@username, @email, @app_email].compact.each{|username|
          [@app_password, @password].compact.each{|password|
            
            req = "curl --#{ENV['DEBUG'] ? 'verbose' : 'silent'} --fail --ntlm --user #{[username, password].join(':').shellescape} #{[@baseurl, name].join('').shellescape} -o #{File.join(@dir, name).shellescape}"
            puts req # if ENV['DEBUG']
            return File.join(@dir, name) if system(req)
          }
        }
        raise "Failed to download #{name}"
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
    end

  end
end
