#!/usr/bin/env ruby

require 'json'

# This script reads all the current port information JSON files, filters it from
# sensitive information and stores the new JSON files.

base_dir = 'public/haven_data'
visits_dir = base_dir + '/vesselvisits'

# Start with the Vessel Positions file
vessel_positions = JSON.parse File.read(base_dir + '/vesselpositions')

vessel_positions.map! do |position|
  {
    position: position['position'],
    vesselId: position['vesselId'],
  }
end

# Write out new data file
File.open base_dir + '/vesselpositions', 'w+' do |file|
  file.write vessel_positions.to_json
end

# Filter all the Vessel Vistis

Dir.foreach visits_dir do |visit_file|
  next if visit_file == '.' or visit_file == '..'

  p "Reading #{visit_file}"

  file_content = File.read(visits_dir + '/' + visit_file)
  file = JSON.parse file_content
  file.map! do |visit|
    filtered = {
      vessel: {id: visit['vessel']['id'], length: visit['vessel']['length'], grossTonnage: visit['vessel']['grossTonnage']},
      shipNameDuringVisit: visit['shipNameDuringVisit']
    }

    filtered['movements'] = visit['movements'].map do |movement|
      {
        berthVisitArrival: movement['berthVisitArrival'],
        berthVisitDeparture: movement['berthVisitDeparture'],
      }
    end

    filtered
  end

  # Write new file
  File.open visits_dir + '/' + visit_file, 'w+' do |new_file|
    new_file.write file.to_json
  end

end

