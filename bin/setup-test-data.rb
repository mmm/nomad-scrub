#!/usr/bin/env ruby

require 'json'

def generate_timestamp
  a_year = 31536000 # seconds
  Time.new.to_i - rand(a_year) # sometime in the last year
end

def generate_event
  {
    :id => `uuidgen`.chop,
    :event_type => 37,
    :timestamp_utc => generate_timestamp,
    :cc_num => '1111-1111-1111-1111',
    :cc_expiration => '01/20',
    :first => 'Frank',
    :last => 'Dormer',
    :zip => '12345'
  }
end

def random_hash
  # 2 hex digits to spread s3 object names
  "%02x" % rand(255).to_i
end

def partitioned_path(event)
  time = Time.at(event[:timestamp_utc])
  "#{random_hash}/year=#{"%02d" % time.year}/month=#{"%02d" % time.month}/day=#{"%02d" % time.day}/#{event[:id]}.json"
end

def copy_to_s3(event)
  puts event[:id]
  tmpfile = "/tmp/#{event[:id]}.json"
  File.open(tmpfile,'w') do |file|
    file.write(event.to_json)
  end
  `aws s3 cp #{tmpfile} s3://nomad-data-to-scrub/events/#{partitioned_path(event)}`
end

(1..10).each do
  copy_to_s3(generate_event)
end

