#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'optparse'
require 'fileutils'
require 'openstudio'
require 'openstudio-standards'

options = {
  template: '90.1-2013',
  building_type: 'SuperMarket',
  climate_zone: 'ASHRAE 169-2013-4A',
  output: nil,
  epw: nil
}

OptionParser.new do |parser|
  parser.banner = 'Usage: build_supermarket_baseline.rb --epw PATH --output DIRECTORY [options]'
  parser.on('--epw PATH', 'Path to a local EnergyPlus weather file') { |value| options[:epw] = value }
  parser.on('--output DIRECTORY', 'Directory for generated model and sizing files') { |value| options[:output] = value }
  parser.on('--template NAME', 'OpenStudio Standards template (default: 90.1-2013)') { |value| options[:template] = value }
  parser.on('--climate-zone NAME', 'ASHRAE climate zone (default: ASHRAE 169-2013-4A)') { |value| options[:climate_zone] = value }
  parser.on('--help', 'Show this message') { puts parser; exit }
end.parse!

abort 'Missing --epw PATH' if options[:epw].nil?
abort 'Missing --output DIRECTORY' if options[:output].nil?

options[:epw] = File.expand_path(options[:epw])
options[:output] = File.expand_path(options[:output])
abort "EPW does not exist: #{options[:epw]}" unless File.file?(options[:epw])

# OpenStudio Standards uses the design-day objects stored in the companion DDY
# during weather-specific sizing.  An EPW alone is therefore not a sufficient
# input for a reproducible sizing run.
ddy_path = options[:epw].sub(/\.epw\z/i, '.ddy')
stat_path = options[:epw].sub(/\.epw\z/i, '.stat')
abort "Missing companion DDY for weather-specific sizing: #{ddy_path}" unless File.file?(ddy_path)
warn "Companion STAT not found (recommended for weather metadata): #{stat_path}" unless File.file?(stat_path)

FileUtils.mkdir_p(options[:output])
sizing_dir = File.join(options[:output], 'sizing')
FileUtils.mkdir_p(sizing_dir)

standard_name = "#{options[:template]}_#{options[:building_type]}"
prototype_creator = Standard.build(standard_name)
model = prototype_creator.model_create_prototype_model(options[:climate_zone], '', sizing_dir, false)
raise "Prototype creation failed for #{standard_name}" unless model

# The prototype is created from its declared climate-zone assumptions. Attach the
# requested local EPW and resize the resulting model for that weather file.
OpenstudioStandards::Weather.model_set_building_location(model, weather_file_path: options[:epw])
raise 'Weather-specific sizing run failed' unless prototype_creator.model_run_sizing_run(model, File.join(options[:output], 'weather_specific_sizing'))

model_path = File.join(options[:output], 'supermarket_baseline.osm')
model.save(OpenStudio::Path.new(model_path), true)

manifest = {
  schema_version: '0.1.0',
  model_status: 'generated_screening_baseline',
  openstudio_version: OpenStudio.openStudioVersion,
  energyplus_version: OpenStudio.energyPlusVersion,
  template: options[:template],
  building_type: options[:building_type],
  climate_zone: options[:climate_zone],
  epw_path: options[:epw],
  epw_filename: File.basename(options[:epw]),
  ddy_path: ddy_path,
  ddy_filename: File.basename(ddy_path),
  stat_path: File.file?(stat_path) ? stat_path : nil,
  model_path: model_path,
  thermal_zones: model.getThermalZones.size,
  spaces: model.getSpaces.size,
  refrigeration_cases: model.getRefrigerationCases.size,
  compressor_racks: model.getRefrigerationCompressorRacks.size,
  note: 'Generated model; not calibrated or independently validated.'
}

File.write(File.join(options[:output], 'build_manifest.json'), JSON.pretty_generate(manifest) + "\n")
puts JSON.pretty_generate(manifest)
