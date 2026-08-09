#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'optparse'
require 'fileutils'
require 'openstudio'

options = { scenarios: nil, output: nil }
OptionParser.new do |parser|
  parser.banner = 'Usage: summarize_demo_results.rb --scenarios DIRECTORY --output DIRECTORY'
  parser.on('--scenarios DIRECTORY', 'Directory containing scenario subdirectories') { |value| options[:scenarios] = value }
  parser.on('--output DIRECTORY', 'Directory for demo JSON') { |value| options[:output] = value }
end.parse!
abort 'Missing --scenarios DIRECTORY' unless options[:scenarios]
abort 'Missing --output DIRECTORY' unless options[:output]

options[:scenarios] = File.expand_path(options[:scenarios])
options[:output] = File.expand_path(options[:output])
manifest = JSON.parse(File.read(File.join(options[:scenarios], 'scenario_manifest.json')))

def time_series(sql, environment, variable, key)
  [key, '', 'Facility'].each do |candidate_key|
    result = sql.timeSeries(environment, 'Hourly', variable, candidate_key)
    return result.get if result.is_initialized
  end
  raise "Missing hourly series #{variable}; tried keys Whole Building, blank, and Facility"
end

def series_records(series)
  series.dateTimes.zip(series.values).map do |datetime, value|
    { 'timestamp' => datetime.to_s, 'month' => datetime.date.monthOfYear.value, 'day' => datetime.date.dayOfMonth, 'hour' => datetime.time.hours, 'joules' => value }
  end
end

outputs = {}
manifest.fetch('scenarios').each do |scenario|
  sql_path = File.join(File.dirname(scenario.fetch('model_path')), 'run', 'eplusout.sql')
  raise "Missing simulation SQL: #{sql_path}" unless File.file?(sql_path)
  sql = OpenStudio::SqlFile.new(OpenStudio::Path.new(sql_path))
  environment = sql.availableEnvPeriods.find { |name| name.upcase.include?('RUN PERIOD') } || sql.availableEnvPeriods.last
  raise "No environment period in #{sql_path}" unless environment
  facility = series_records(time_series(sql, environment, 'Electricity:Facility', 'Whole Building'))
  outputs[scenario.fetch('id')] = scenario.merge('facility_hourly' => facility)
  sql.close
end

baseline = outputs.fetch('baseline').fetch('facility_hourly')
event_day = baseline.select { |r| (6..9).cover?(r['month']) && (15..17).cover?(r['hour']) }
                    .group_by { |r| [r['month'], r['day']] }
                    .max_by { |_day, records| records.sum { |r| r['joules'] } }
raise 'Could not select a summer peak event day' unless event_day
selected_month, selected_day = event_day.first

summaries = outputs.transform_values do |scenario|
  records = scenario.fetch('facility_hourly')
  event = records.select { |r| r['month'] == selected_month && r['day'] == selected_day }
  {
    'id' => scenario.fetch('id'),
    'label' => scenario.fetch('label'),
    'description' => scenario.fetch('description'),
    'annual_site_kwh' => records.sum { |r| r['joules'] } / 3_600_000.0,
    'annual_peak_kw' => records.map { |r| r['joules'] / 3_600_000.0 }.max,
    'event_window_kwh' => event.select { |r| (15..17).cover?(r['hour']) }.sum { |r| r['joules'] } / 3_600_000.0,
    'event_day_hourly_kw' => event.map { |r| { 'hour' => r['hour'], 'kw' => r['joules'] / 3_600_000.0 } }
  }
end

payload = {
  schema_version: '0.1.0',
  evidence_class: 'simulated_screening',
  claim_boundary: manifest.fetch('claim_boundary'),
  event_day: format('%02d-%02d', selected_month, selected_day),
  event_window: '15:00-18:00 local model time',
  summaries: summaries
}
FileUtils.mkdir_p(options[:output])
File.write(File.join(options[:output], 'results.json'), JSON.pretty_generate(payload) + "\n")
puts JSON.pretty_generate(payload)
