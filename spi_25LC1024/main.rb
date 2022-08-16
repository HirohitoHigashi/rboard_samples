#
# MICROCHIP 25LC1024
#  1 Mbit SPI Bus Serial EEPROM
#
#  https://www.microchip.com/en-us/product/25LC1024
#
# Pin assign.
#  SDI: Pin10 (B5)
#  SDO: Pin11 (B6) but not used.
#  SCK: Pin19 (B14)
#  SS:  Pin17 (B12)
#


$spi = SPI.new()

$ss = GPIO.new("B12")
$ss.setmode(GPIO::OUT)
$ss.write( 1 )

#
# Read sequence
#
def eeprom_read( adrs, size )
  $ss.write( 0 )
  $spi.write( 0x03, (adrs >> 16) & 0xff, (adrs >> 8) & 0xff, adrs & 0xff )
  s = $spi.read(size)
  $ss.write( 1 )

  return s
end


#
# Write sequence
#
# (note) data size is 256 bytes max
#
def eeprom_write( adrs, data )
  s = "\x02"
  s << ((adrs >> 16) & 0xff)
  s << ((adrs >>  8) & 0xff)
  s << ( adrs        & 0xff)
  s << data

  $ss.write( 0 )
  $spi.write( s )
  $ss.write( 1 )
end


#
# write enable
#
def eeprom_write_enable()
  $ss.write( 0 )
  $spi.write( 0b0000_0110 )
  $ss.write( 1 )
end


#
# write disable
#
def eeprom_write_disable()
  $ss.write( 0 )
  $spi.write( 0b0000_0100 )
  $ss.write( 1 )
end


#
# read status register
#
def eeprom_read_status()
  $ss.write( 0 )
  s = $spi.transfer( [0b0000_0101], 1 )
  $ss.write( 1 )

  st = s.getbyte(0)
  return {
    :WPEN => (st & 0b1000_0000) >> 7,
    :BP1  => (st & 0b0000_1000) >> 3,
    :BP0  => (st & 0b0000_0100) >> 2,
    :WEL  => (st & 0b0000_0010) >> 1,
    :WIP  => (st & 0b0000_0001)
  }
end


#
# page erase
#
# (note) 256 bytes/page
#
def eeprom_page_erase( adrs )
  s = "\x42"
  s << ((adrs >> 16) & 0xff)
  s << ((adrs >>  8) & 0xff)
  s << ( adrs        & 0xff)

  $ss.write( 0 )
  $spi.write( s )
  $ss.write( 1 )
end


#
# sector erase
#
# (note) 32K bytes/sector
#
def eeprom_sector_erase( adrs )
  s = "\xd8"
  s << ((adrs >> 16) & 0xff)
  s << ((adrs >>  8) & 0xff)
  s << ( adrs        & 0xff)

  $ss.write( 0 )
  $spi.write( s )
  $ss.write( 1 )
end


#
# chip erase
#
def eeprom_chip_erase()
  $ss.write( 0 )
  $spi.write( 0b1100_0111 )
  $ss.write( 1 )
end


#
# read convenience
#
def eeprom_read_c( adrs, size )
  # check write in process.
  while true
    st = eeprom_read_status()
    break if st[:WIP] == 0
  end

  # read start
  return eeprom_read( adrs, size )
end


#
# write convenience
#
def eeprom_write_c( adrs, data )
  return nil  if data.size > 256

  # check write in process.
  while true
    st = eeprom_read_status()
    break if st[:WIP] == 0
  end

  # write start
  eeprom_write_enable()
  eeprom_write( adrs, data )
end


#
# print hex dump
#
def hexdump( adrs, data )
  idx = 0

  while (d1 = data[idx, 16]) && (d1 != "")
    hex = ""
    ascii = ""
    d1.each_byte {|byte|
      hex << sprintf("%02X ", byte )
      ascii << ((0x20 <= byte && byte <= 0x7e) ? byte.chr : ".")
    }
    printf("%04X: %-48s %s\n", adrs, hex, ascii )
    adrs += 16
    idx += 16
  end
end



#
# fill test data
#
def fill_test_data()
  eeprom_write_enable()
  eeprom_chip_erase();

  adrs = 0x00
  while adrs < 0x02_00_00
    s = sprintf( "ADRS: $%02X_%02X_%02X ", (adrs >> 16) & 0xff, (adrs >> 8) & 0xff, adrs & 0xff )
    puts s
    (256-16).times {|i| s << (i+16) }

    while true
      st = eeprom_read_status()
      break if st[:WIP] == 0
    end
    eeprom_write_enable()
    eeprom_write( adrs, s )

    adrs += 256
  end
end


#
# simple read test
#
def test_read( adrs )
  printf("test simple read adrs=%06x\n", adrs )
  s = eeprom_read( adrs, 16 )
  hexdump( adrs, s )
end


#
# simple write and read test
#
def test_write_and_read( adrs )
  printf("test simple write and read adrs=%06x\n", adrs )
  eeprom_write_c( adrs, "abcdef" )
  s = eeprom_read_c( adrs, 16 )
  hexdump( adrs, s )
end



#
# test patterns
#
sleep 2
puts "Start EEPROM sample program."

#fill_test_data()
test_read( 0x00_00_00 )
#test_write_and_read( 0x00_00_00 )
