# coding: utf-8
#
# USB UART <-> Grove UART
#

uart1 = UART.new(1, 19200)      # USBUART
uart2 = UART.new(2, 115200)     # Pin13 and 14
#uart2.set_modem_params("stop_bits"=>2)

flag_local_echo = false


while true
  data = uart1.read_nonblock(100)
  if data
    leds_write(1)
    uart1.write( data ) if flag_local_echo
    uart2.write( data )
  end
  sleep_ms 5
  leds_write(0)

  data = uart2.read_nonblock(100)
  if data
    leds_write(2)
    uart1.write(data)
  end
  sleep_ms 5

  # local echo on/off
  if sw() == 0
    flag_local_echo = !flag_local_echo
    leds_write(3)
    sleep 1
  end

  leds_write(0)
end
__END__


# UART割り付けピン変更のテスト
while true
  data = uart1.gets
  case data
  when nil
    # nothing to do

  when "1\r\n", "1\n"
    uart2.set_modem_params("txd"=>14, "rxd"=>13)
    puts "set to grove UART"

  when "2\r\n", "2\n"
    uart2.set_modem_params("txd"=>15, "rxd"=>16)
    puts "set to grove Digital"

  else
    uart2.write(data)
  end

  data = uart2.gets
  uart1.puts(data)  if data

  sleep_ms 50
end
__END__
