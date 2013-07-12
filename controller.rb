#!/usr/bin/ruby
require 'rubygems'

require 'eventmachine'
require "gpio"
require "net/http"
require "uri"
require 'json'
EventMachine.run do
@blink_led = nil
@green = GPIO::Led.new(pin:10)
@red = GPIO::Led.new(pin:15)
@yellow = GPIO::Led.new(pin:22)
@test_service_leds = {:red => @red, :green => @green, :yellow => @yellow}
def poll_status_of_service(service,led_hash)
  uri = URI.parse("http://10.0.2.51:3000/status/#{service}")
  response = Net::HTTP.get_response(uri)
  @JSON_hash = JSON.parse(response.body)
  if !@JSON_hash.has_key? "error"
    puts @JSON_hash["isWorking"]
    if @blink_led != nil
      @blink_led.cancel
      @blink_led = nil
    end
    
    change_led_status(@JSON_hash["isWorking"],led_hash)
  else
    if @blink_led == nil
      @blink_led = EM.add_periodic_timer(1) {
        blink_non_blocking(led_hash[:red])
        blink_non_blocking(led_hash[:yellow])
        blink_non_blocking(led_hash[:green])
      }
    end
  end
end

def blink_non_blocking(led)
  #puts "here"
  led.on
  EM.add_timer(0.1) do
    led.off
  end
end

def change_led_status(status,led_hash)
  case status
  when "good"
    green_on(led_hash)
  when "bad"
    yellow_on(led_hash)
  when "failing"
    red_on(led_hash)
  end
end
#uri = URI.parse("http://10.0.2.51:3000/")
#response = Net::HTTP.get_response(uri)

def red_on(led_hash)
  led_hash[:red].on
  led_hash[:green].off
  led_hash[:yellow].off
end
def green_on(led_hash)
  led_hash[:red].off
  led_hash[:green].on
  led_hash[:yellow].off
end
def yellow_on(led_hash)
  led_hash[:red].off
  led_hash[:green].off
  led_hash[:yellow].on
end
def blink(led_hash)
  led_hash[:red].blink
  led_hash[:green].blink
  led_hash[:yellow].blink
end

   @poll_server = EM.add_periodic_timer(3) { poll_status_of_service("test_service",@test_service_leds)}
end

