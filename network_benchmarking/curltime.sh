curl_time() {
    curl -isL -w "\n\
   namelookup:  %{time_namelookup}s\n\
      connect:  %{time_connect}s\n\
   appconnect:  %{time_appconnect}s\n\
  pretransfer:  %{time_pretransfer}s\n\
     redirect:  %{time_redirect}s\n\
starttransfer:  %{time_starttransfer}s\n\
-------------------------\n\
        total:  %{time_total}s\n" "$@"
}


#curl_time -X POST -H "Content-Type: application/json" -d '{"key": "val"}' https://testdomain.<your>.<domain>
curl_time https://testdomain.<your>.<domain>
echo
echo