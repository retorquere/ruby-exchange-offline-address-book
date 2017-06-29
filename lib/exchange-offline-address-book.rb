#!/usr/bin/env ruby

require 'dotenv/load'

require 'autodiscover'

require "autodiscover/debug" if ENV['DEBUG']
require 'yaml'
require 'nokogiri'
require 'tempfile'
require 'json'
require 'ostruct'
require 'shellwords'

require_relative 'exchange-offline-address-book/parser'
require_relative 'exchange-offline-address-book/mspack'

class OfflineAddressBook
  def initialize(email: nil, password: nil, username: nil, cachedir: nil, baseurl: nil, update: true)
    @email = email
    @username = username || email
    @password = password
    @cachedir = cachedir
    @update = update
    @baseurl = baseurl
  end

  def path(name)
    @files ||= {}
    @files[name] ||= begin
      if @cachedir
        File.join(@cachedir, name)
      else
        tmp = Tempfile.new(name).path
        File.delete(tmp)
        tmp
      end
    end
    @files[name]
  end

  def download(name)
    if !@cachedir || @update || !File.file?(path(name))
      system "curl --#{ENV['DEBUG'] ? 'verbose' : 'silent'} --ntlm --user #{[@username, @password].join(':').shellescape} #{[baseurl, name].join('').shellescape} -o #{path(name).shellescape}"
    end
    return path(name)
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

      lzx ||= Nokogiri::XML(open(download('oab.xml'))).at('//Full').inner_text
      oab = File.basename(lzx, File.extname(lzx)) + '.oab'

      if !File.file?(path(oab))
        if @cachedir
          %w{*.oab *.lzx *.yml *.json}.each{|ext|
            Dir[File.join(@cachedir, ext)].each{|f| File.unlink(f) }
          }
        end

        download(lzx)
        LibMsPack.oab_decompress(path(lzx), path(oab))
      end

      path(oab)
    end
  end

  def cache
    @cache ||= path(File.basename(addressbook, File.extname(addressbook)) + '.json')
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
