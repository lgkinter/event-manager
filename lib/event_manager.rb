require 'csv'
require 'sunlight/congress'
require 'erb'

Sunlight::Congress.api_key = "e179a6973728c4dd3fb1204283aaccb5"
DAYS = {0 => "Sunday",
        1 => "Monday",
        2 => "Tuesday",
        3 => "Wednesday",
        4 => "Thursday",
        5 => "Friday",
        6 => "Saturday"}


def clean_zipcode(zipcode)
  # if the zip code is exactly five digits, assume that is ok
  # if the zip code is more than five digits, truncate to the first five.
  # if the zip code is less than five digits, add zeros to the front until becomes five digits.
  zipcode.to_s.rjust(5, "0")[0..4]
  #if zipcode.nil?
  #  "00000"
  #elsif zipcode.length < 5
  #  zipcode.rjust(5, "O")
  #elsif zipcode.length > 5
  #  zipcode[0..4]
  #else
  #  zipcode
  #end
end

def clean_phone_number(homephone)
  number = homephone.gsub(/[\D]/, "")
  number.length == 10 || (number.length == 11 && number[0] == "1") ? number[-10..-1] : nil
end

def find_registration_date(regdate)
  DateTime.strptime(regdate, '%m/%d/%y %H:%M')
end

def legislators_by_zipcode(zipcode)
  Sunlight::Congress::Legislator.by_zipcode(zipcode)
end

def save_thank_you_letters(id, form_letter)
    Dir.mkdir("output") unless Dir.exists? "output"
    filename = "output/thanks_#{id}.html"
    File.open(filename, 'w') do |file|
      file.puts form_letter
    end
end

puts "EventManager initialized."

#contents = File.read "event_attendees.csv" if File.exist? "event_attendees.csv"
#puts contents

#Read as array of lines
#lines = File.readlines "event_attendees.csv"
#lines.each_with_index do |line, index|
#  next if index == 0
#  columns = line.split(",")
#  first_name = columns[2]
#  puts first_name
#end

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol
template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

registration_hours = []
registration_week_days = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  homephone = clean_phone_number(row[:homephone])

  registration_date = find_registration_date(row[:regdate])
  registration_hours << registration_date.hour
  registration_week_days << registration_date.wday

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)
  save_thank_you_letters(id, form_letter)
end

most_popular_hour = registration_hours.uniq.max_by { |hour| registration_hours.count(hour) }
most_popular_week_day = registration_week_days.uniq.max_by { |day| registration_week_days.count(day) }
puts "The most popular day of the week to register was #{DAYS[most_popular_week_day]}."
puts "The most popular hour of the day to register was #{most_popular_hour}."
