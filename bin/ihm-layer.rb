#!/bin/env ruby
# frozen_string_literal: true

require 'optparse'

@script = File.basename($0)
@rcfile = ".#{@script}"

begin
  binding.eval(File.read(@rcfile), @rcfile)
rescue Errno::ENOENT => e
end

@timeout = 900
@maxsize = 1073741824
@area = '3606195356'
@query = '"amenity"="drinking_water"'
@type = 'node'

OptParse.new do |opts|
  opts.banner = <<EOF
Usage: #{@script} [options]

EOF
  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
  opts.on('--timeout INT', Integer,
          "Request timeout [#{@timeout}] (INT secs)") do |t|
    @timeout = t
  end
  opts.on('-t', '--type STRING', String,
          "Feature type [#{@type}] (node,way,rel,nw,nwr)") do |t|
    @type = t
  end
  opts.on('-q', '--query STRING', String,
          "Query string (e.g., '#{@query}')") do |q|
    @query = q
  end
  opts.on('-a', '--area STRING', String, "Area id [#{@area}]") do |a|
    @area = a
  end
  opts.on('-m', '--maxsize INT', Integer,
          "Maximum response size in bytes [#{@maxsize}]") do |m|
    @maxsize = m
  end
  opts.on('-o', '--outdir STRING', String,
          "Output subdirectory in layers") do |o|
    @outdir = o
  end
end.parse!

unless (@outdir) do
  parts = @query.split('=').map{|s| s.delete_prefix('"').delete_suffix('"')}
  @outdir = parts.join('/')
end

@query = <<EOF
[timeout:#{@timeout}][maxsize:#{@maxsize}][out:json];
#{@type}[#{@query}](area:#{@area});
out geom;
EOF

require 'faraday'

resp = Faraday.post('http://overpass-api.de/api/interpreter', @query)

require 'json'

json = JSON.parse(resp.body, symbolize_names: true)
geojson = {
  type: 'FeatureCollection',
  features: json[:elements].map do |el|
    {
      type: 'Feature',
      geometry: {
        type: 'Point',
        coordinates: [el.delete(:lon), el.delete(:lat)],
      },
      properties: el,
    }
  end,
}

puts geojson.to_json

