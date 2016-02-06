require './app/models/user'
require './app/models/namespace'
require './app/models/facility'
require './app/models/rent'
require './app/models/span'
require './app/models/entities'
require './app/helpers/http_errors'
require './app/helpers/oauth'
require './app/api/v1'

module Facility
   class API < Grape::API
      if $no_log
         ActiveRecord::Base.logger = nil
      else
         logger.formatter = GrapeLogging::Formatters::Default.new
         logger Logger.new GrapeLogging::MultiIO.new(STDOUT, File.open(Settings::LOG_PATH, 'a'))
         use GrapeLogging::Middleware::RequestLogger, { logger: logger }
      end
      mount Facility::V1 => '/facility/v1'
   end
end
