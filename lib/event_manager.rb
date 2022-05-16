require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def open_csv
  CSV.open(
    'event_attendees.csv',
    headers: true,
    header_converters: :symbol
  )
end

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone_number(number)
  clean_num = number.to_s.gsub(/\D/, '')
  return clean_num if clean_num.length == 10
  return clean_num[1..10] if (clean_num.length == 11 && clean_num[0] == '1')

  'N/A'
end

def most_common(var)
  contents = open_csv
  arr = []
  contents.each do |row|
    reg = row[:regdate]
    x = Time.strptime(reg, "%m/%d/%y %k:%M").send(var) unless var == :wday
    x = Time.strptime(reg, "%m/%d/%y %k:%M").strftime('%A') if var == :wday

    arr << x
  end
  arr.group_by { |n| n }.values.max_by(&:size).first
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

# template_letter = File.read('form_letter.erb')
# erb_template = ERB.new template_letter

# contents.each do |row|
#   id = row[0]
#   name = row[:first_name]
#   zipcode = clean_zipcode(row[:zipcode])
#   legislators = legislators_by_zipcode(zipcode)

#   form_letter = erb_template.result(binding)

#   save_thank_you_letter(id, form_letter)
# end

puts "Most common hour: #{most_common(:hour)}."
puts "Most common day: #{most_common(:wday)}."
