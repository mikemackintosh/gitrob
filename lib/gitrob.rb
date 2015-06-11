require 'json'
require 'cgi'

require 'methadone'
require 'highline/import'
require 'thread/pool'
require 'httparty'
require 'ruby-progressbar'
require 'paint'
require 'sinatra/base'
require 'data_mapper'

require 'gitrob/version'
require 'gitrob/util'
require 'gitrob/progressbar'
require 'gitrob/github/http_client'
require 'gitrob/github/repository'
require 'gitrob/github/blob'
require 'gitrob/github/organization'
require 'gitrob/github/user'
require 'gitrob/observers/sensitive_files'
require 'gitrob/webapp'

require "#{File.dirname(__FILE__)}/../models/organization"
require "#{File.dirname(__FILE__)}/../models/repo"
require "#{File.dirname(__FILE__)}/../models/user"
require "#{File.dirname(__FILE__)}/../models/blob"
require "#{File.dirname(__FILE__)}/../models/finding"

module Gitrob
  def self.task(message)
    print " #{Paint['[*]', :bright, :blue]} #{Paint[message, :bright, :white]}"
    yield
    puts Paint[" done", :bright, :green]
  rescue => e
    puts Paint[" failed", :bright, :red]
    puts "#{Paint[' [!]', :bright, :red]} #{Paint[e.class, :bright, :white]}: #{e.message}"
    exit!
  end

  def self.status(message)
    puts " #{Paint['[*]', :bright, :blue]} #{Paint[message, :bright, :white]}"
  end

  def self.fatal(message)
    puts " #{Paint['[!]', :bright, :red]} #{Paint[message, :bright, :white]}"
    exit!
  end

  def self.prepare_database!
    DataMapper::Model.raise_on_save_failure = true
    DataMapper::Property.auto_validation(false)
    DataMapper.setup(:default, configuration['sql_connection_uri'])
    DataMapper.finalize
    DataMapper.auto_upgrade!
  end

  def self.delete_organization(org)
    orgs = Gitrob::Organization.all(:login => org)
    if orgs.count > 0
      task("Deleting existing #{org} organization...") do
        orgs.destroy
      end
    end
  end

  def self.license
    File.read("#{File.dirname(__FILE__)}/../LICENSE.txt")
  end

  def self.configured?
    conf_file = ENV['CONFIG_FILE'] || "#{Dir.home}/.gitrobrc"
    File.exists?(conf_file)
  end

  def self.configuration
    @config ||= load_configuration!
  end

  def self.load_configuration!
    conf_file = ENV['CONFIG_FILE'] || "#{Dir.home}/.gitrobrc"
    YAML.load_file(conf_file)
  end

  def self.save_configuration!(config)
    @config = config
    File.open("#{Dir.home}/.gitrobrc", 'w') { |f| f.write YAML.dump(config) }
  end

  def self.banner
<<-BANNER
      _ _           _
  ___|_| |_ ___ ___| |_
 | . | |  _|  _| . | . |
 |_  |_|_| |_| |___|___|
 |___| #{Paint["as modified by", :bright, :white]}
     #{Paint[" - @mikemackintosh", :bright, :white]}
BANNER
  end
end
