#!/usr/bin/env rake

require 'bundler/setup'
require 'grape/activerecord/rake'
require 'rspec/core'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

namespace :db do
   task :environment do
      require './environment'
      require_relative 'app'
      Grape::ActiveRecord.configure_from_file! "config/database.yml"
   end
end

namespace :ns do
   task :insert, [:name, :description] do |t, args|
      require './environment'
      require './app/models/namespace'
      DB::Namespace.create(name: args.name, description: args.description)
   end
end

task :default do
   ENV['RACK_ENV'] = 'test'
   require './environment'
   require './app'
   DB::Facility.destroy_all
   Rake::Task['db:reset'].invoke
   Rake::Task['spec'].invoke
end
