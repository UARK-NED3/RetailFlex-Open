#!/usr/bin/env ruby
# frozen_string_literal: true

# Creates transparent, screening-level scenario models for the RetailFlex demo.
# The schedule changes are intentionally simple and are not a control strategy.

require 'json'
require 'optparse'
require 'fileutils'
require 'openstudio'

options = { baseline: nil, config: File.expand_path('../config/demo_scenarios.json', __dir__), output: nil }
OptionParser.new do |parser|
  parser.banner = 'Usage: prepare_demo_scenarios.rb --baseline PATH --output DIRECTORY [options]'
  parser.on('--baseline PATH', 'Path to a generated baseline OSM') { |value| options[:baseline] = value }
  parser.on('--config PATH', 'Scenario configuration JSON') { |value| options[:config] = value }
  parser.on('--output DIRECTORY', 'Directory for generated OSM and OSW files') { |value| options[:output] = value }
  parser.on('--help', 'Show this message') { puts parser; exit }
end.parse!

abort 'Missing --baseline PATH' unless options[:baseline]
abort 'Missing --output DIRECTORY' unless options[:output]
options[:baseline] = File.expand_path(options[:baseline])
options[:config] = File.expand_path(options[:config])
options[:output] = File.expand_path(options[:output])
abort "Baseline OSM does not exist: #{options[:baseline]}" unless File.file?(options[:baseline])
abort "Scenario configuration does not exist: #{options[:config]}" unless File.file?(options[:config])

def time_at(hour)
  OpenStudio::Time.new(0, hour, 0, 0)
end

def unique_day_schedules(schedule)
  ([schedule.defaultDaySchedule] + schedule.scheduleRules.map(&:daySchedule)).uniq { |day| day.handle.to_s }
end

def apply_cooling_shift(schedule, scenario)
  shift = scenario.fetch('setpoint_shift_c')
  pre_start = scenario.fetch('pre_cool_start_hour')
  peak_start = scenario.fetch('peak_start_hour')
  peak_end = scenario.fetch('peak_end_hour')
  unique_day_schedules(schedule).each do |day|
    pre_value = day.getValue(time_at(pre_start))
    peak_value = day.getValue(time_at(peak_start))
    end_value = day.getValue(time_at(peak_end))
    day.addValue(time_at(pre_start), pre_value - shift)
    day.addValue(time_at(peak_start), peak_value + shift)
    day.addValue(time_at(peak_end), end_value)
  end
end

def apply_lighting_multiplier(schedule, scenario)
  start_hour = scenario.fetch('peak_start_hour')
  end_hour = scenario.fetch('peak_end_hour')
  multiplier = scenario.fetch('lighting_multiplier')
  unique_day_schedules(schedule).each do |day|
    start_value = day.getValue(time_at(start_hour))
    end_value = day.getValue(time_at(end_hour))
    day.addValue(time_at(start_hour), start_value * multiplier)
    day.addValue(time_at(end_hour), end_value)
  end
end

def request_hourly_outputs(model)
  %w[Electricity:Facility InteriorLights:Electricity Cooling:Electricity].each do |meter_name|
    meter = OpenStudio::Model::OutputMeter.new(model)
    meter.setName(meter_name)
    meter.setReportingFrequency('Hourly')
  end
  model.getThermalZones.each do |zone|
    variable = OpenStudio::Model::OutputVariable.new('Zone Mean Air Temperature', model)
    variable.setKeyValue(zone.nameString)
    variable.setReportingFrequency('Hourly')
  end
end

config = JSON.parse(File.read(options[:config]))
FileUtils.mkdir_p(options[:output])
generated = []

config.fetch('scenarios').each do |scenario|
  model = OpenStudio::Model::Model.load(OpenStudio::Path.new(options[:baseline])).get
  if scenario['cooling_schedule']
    cooling = model.getScheduleRulesetByName(scenario.fetch('cooling_schedule'))
    abort "Cooling schedule not found: #{scenario.fetch('cooling_schedule')}" unless cooling.is_initialized
    apply_cooling_shift(cooling.get, scenario)
  end
  if scenario['lighting_schedule']
    lighting = model.getScheduleRulesetByName(scenario.fetch('lighting_schedule'))
    abort "Lighting schedule not found: #{scenario.fetch('lighting_schedule')}" unless lighting.is_initialized
    apply_lighting_multiplier(lighting.get, scenario)
  end
  request_hourly_outputs(model)
  scenario_dir = File.join(options[:output], scenario.fetch('id'))
  FileUtils.mkdir_p(scenario_dir)
  model_path = File.join(scenario_dir, "#{scenario.fetch('id')}.osm")
  model.save(OpenStudio::Path.new(model_path), true)
  osw = { seed_file: model_path, steps: [] }
  File.write(File.join(scenario_dir, 'in.osw'), JSON.pretty_generate(osw) + "\n")
  generated << scenario.merge('model_path' => model_path, 'osw_path' => File.join(scenario_dir, 'in.osw'))
end

manifest = {
  schema_version: '0.1.0',
  evidence_class: 'simulated_screening',
  source_baseline: options[:baseline],
  claim_boundary: config.fetch('claim_boundary'),
  scenarios: generated
}
File.write(File.join(options[:output], 'scenario_manifest.json'), JSON.pretty_generate(manifest) + "\n")
puts JSON.pretty_generate(manifest)
