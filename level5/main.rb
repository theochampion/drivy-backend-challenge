require "json"
require "date"
require "pp"

Car = Struct.new(:price_per_day, :price_per_km)

class Rental
  # create a static map of discount ranges
  @@discount_map = { 0..1 => 1,
                    2..4 => 0.9,
                    5..10 => 0.7,
                    11..Float::INFINITY => 0.5 }

  @@options_price = { "gps" => 500,
                      "baby_seat" => 200,
                      "additional_insurance" => 1000 }

  def initialize(car, rental_details, options)
    @id = rental_details["id"]
    @car = car
    @duration = ((Date.parse(rental_details["end_date"]) - Date.parse(rental_details["start_date"])).to_i) + 1
    @distance = rental_details["distance"]
    @options = options
  end

  def dump_rental_result()
    total_duration_price = gen_duration_price_w_discount()
    total_distance_price = @distance * @car.price_per_km
    total_price = total_duration_price + total_distance_price
    return Hash["id" => @id, "options" => @options, "actions" => gen_commission_actions(total_price)]
  end

  def gen_duration_price_w_discount()
    discounted_price = 0
    for day in 1..@duration
      discounted_price += @car.price_per_day * @@discount_map.select { |discount| discount === day }.values.last
    end
    return discounted_price.to_i
  end

  def get_price_sum_applicable_options(applicable_options)
    return applicable_options.reduce(0) { |sum, option| sum + (@options.include?(option) ? (@@options_price[option] * @duration) : 0) }
  end

  def gen_commission_actions(total_price)
    comm = total_price * 0.3
    return [
             {
               "who": "driver",
               "type": "debit",
               "amount": total_price + get_price_sum_applicable_options(["gps", "baby_seat", "additional_insurance"]),
             },
             {
               "who": "owner",
               "type": "credit",
               "amount": (total_price - comm).to_i + get_price_sum_applicable_options(["gps", "baby_seat"]),
             },
             {
               "who": "insurance",
               "type": "credit",
               "amount": (comm /= 2).to_i,
             },
             {
               "who": "assistance",
               "type": "credit",
               "amount": @duration * 100,
             },
             {
               "who": "drivy",
               "type": "credit",
               "amount": (comm - (@duration * 100)).to_i + get_price_sum_applicable_options(["additional_insurance"]),
             },
           ]
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

options_h = {}
obj["options"].map { |option| (options_h[option["rental_id"]] ||= []).push(option["type"]) }
# convert rentals to array of Rental classes
rentals = obj["rentals"].map { |rental| Rental.new(cars[rental["car_id"]], rental, options_h.key?(rental["id"]) ? options_h[rental["id"]] : []) }
result = Hash["rentals" => rentals.map { |rental| rental.dump_rental_result() }]
File.write("data/output.json", JSON.pretty_generate(result))
