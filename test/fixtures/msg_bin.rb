

[addr].each_with_index do |m, i|
  File.open("message_#{i}.bin", 'wb') do |f|
    m.each do |byte|
      f.write([byte].pack('C'))
    end
  end
end
