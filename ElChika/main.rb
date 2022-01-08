while true
  (0..15).each {|n|
    leds_write(n)
    puts n
    sleep_ms 100
  }
end
