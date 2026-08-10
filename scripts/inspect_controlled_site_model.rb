#!/usr/bin/env ruby
# frozen_string_literal: true

# Inspect an authorized local OpenStudio model without copying it or exporting
# geometry, object names, schedules, or other store-identifying information.

require 'json'
require 'optparse'
require 'fileutils'
require 'openstudio'

options = { model: nil, output: nil }
OptionParser.new do |parser|
  parser.banner = 'Usage: inspect_controlled_site_model.rb --model PATH --output DIRECTORY'
  parser.on('--model PATH', 'Authorized local OSM file; never copied by this script') { |value| options[:model] = value }
  parser.on('--output DIRECTORY', 'Ignored local directory for the non-identifying report') { |value| options[:output] = value }
  parser.on('--help', 'Show this message') { puts parser; exit }
end.parse!

abort 'Missing --model PATH' unless options[:model]
abort 'Missing --output DIRECTORY' unless options[:output]
model_path = File.expand_path(options[:model])
output_dir = File.expand_path(options[:output])
abort "Model does not exist: #{model_path}" unless File.file?(model_path)

loaded = OpenStudio::OSVersion::VersionTranslator.new.loadModel(OpenStudio::Path.new(model_path))
abort 'OpenStudio could not load the controlled model' if loaded.empty?
model = loaded.get

# Deliberately exclude model path, model name, object names, geometry, location,
# schedules, and equipment names from the output.
report = {
  schema_version: '0.1.0',
  data_classification: 'controlled_local_only',
  report_scope: 'non_identifying_structural_inventory',
  model_format: 'OpenStudio Model',
  thermal_zones: model.getThermalZones.size,
  spaces: model.getSpaces.size,
  air_loops: model.getAirLoopHVACs.size,
  plant_loops: model.getPlantLoops.size,
  refrigeration_cases: model.getRefrigerationCases.size,
  compressor_racks: model.getRefrigerationCompressorRacks.size,
  exterior_lights: model.getExteriorLightss.size,
  inspection_status: 'structural_inventory_only_not_calibration_or_validation',
  prohibited_interpretations: [
    'No store-specific savings claim',
    'No refrigeration safety or control recommendation',
    'No live control authorization',
    'No public release of model-derived identifying detail'
  ]
}

FileUtils.mkdir_p(output_dir)
report_path = File.join(output_dir, 'controlled_site_structure_report.json')
File.write(report_path, JSON.pretty_generate(report) + "\n")
puts JSON.pretty_generate(report)
