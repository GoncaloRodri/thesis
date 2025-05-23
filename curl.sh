start=$(date +%s.%N)
curl -w "HTTP Response: %{http_code}\nDNS resolution time: %{time_namelookup}s\nTCP connection time: %{time_connect}s\nSSL handshake time: %{time_appconnect}s\nTime until transfer began: %{time_pretransfer}s\nTime to first byte: %{time_starttransfer}s\nTotal time: %{time_total}s\nDownload speed: %{speed_download} bytes/sec\n" -o /dev/null http://ipv4.download.thinkbroadband.com/5MB.zip

end=$(date +%s.%N)
duration=$(echo "$end - $start" | bc -l)
echo "Started at: ${start}s"
echo "Ended at: ${end}s"
echo "Duration: ${duration}s"