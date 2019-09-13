require "json"
require "date"

Car = Struct.new(:price_per_day, :price_per_km)

class Rental
  # create a static map of discount ranges
  @@discount_map = { 0..1 => 1, 2..4 => 0.9,
                    5..10 => 0.7, 11..Float::INFINITY => 0.5 }

  def initialize(car, rental_details)
    @id = rental_details["id"]
    @car = car
    @duration = ((Date.parse(rental_details["end_date"]) - Date.parse(rental_details["start_date"])).to_i) + 1
    @distance = rental_details["distance"]
  end

  def dump_rental_result()
    total_duration_price = gen_duration_price_w_discount()
    total_distance_price = @distance * @car.price_per_km
    return Hash["id" => @id, "price" => total_duration_price + total_distance_price]
  end

  def gen_duration_price_w_discount()
    discounted_price = 0
    for day in 1..@duration
      discounted_price += @car.price_per_day * @@discount_map.select { |discount| discount === day }.values.last
    end
    return discounted_price.to_i
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
