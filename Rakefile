#!/usr/bin/env rake

require 'bundler/setup'
require 'grape/activerecord/rake'

namespace :db do
   task :environment do
      require './environment'
      require_relative 'app'
   end
end

namespace :ns do
   task :insert, [:name, :description] do |t, args|
      require './environment'
      require './app/models/namespace'
      DB::Namespace.create(name: args.name, description: args.description)
   end
end
