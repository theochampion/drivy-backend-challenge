require "json"
require "date"

Car = Struct.new(:price_per_day, :price_per_km)

class Rental
  def initialize(car, rental_details)
    @id = rental_details["id"]
    @car = car
    @duration = ((Date.parse(rental_details["end_date"]) - Date.parse(rental_details["start_date"])).to_i) + 1
    @distance = rental_details["distance"]
  end

  def dump_rental_result()
    return Hash["id" => @id,
                "price" => @duration * @car.price_per_day + @distance * @car.price_per_km]
  end
end


begin
  json = File.read("data/input.json")
  obj = JSON.parse(json)
rescue Errno::ENOENT
  puts "Input file not found, exiting."
  exit 1
rescue JSON::ParserError
  puts "Input file is not valid JSON, exiting."
  exit 1
end

# convert cars array to hash table for faster retrieval
cars = obj["cars"].map { |car| [car["id"], Car.new(car["price_per_day"], car["price_per_km"])] }.to_h
# convert rentals to array of Rental classes
rentals = obj["rentals"].map { |rental| Rental.new(cars[rental["car_id"]], rental) }
result = Hash["rentals" => rentals.map { |rental| rental.dump_rental_result() }]
File.write("data/output.json", JSON.pretty_generate(result))
