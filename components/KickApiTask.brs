sub init()
  m.top.functionName = "fetchKickApi"
end sub

sub fetchKickApi()
  print "=== KickApiTask: Fetching from " + m.top.apiUrl + " ==="
  
  ' Create HTTP request
  request = createObject("roUrlTransfer")
  request.setUrl(m.top.apiUrl)
  request.setCertificatesFile("common:/certs/ca-bundle.crt")
  
  ' Set headers to mimic browser request
  request.addHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
  request.addHeader("Accept", "application/json")
  request.addHeader("Referer", "https://kick.com/")
  
  ' Make the request
  response = request.getToString()
  
  if response <> invalid and len(response) > 0
      print "✅ API request successful"
      m.top.response = response
  else
      errorMsg = "Failed to fetch data"
      if request.getFailureReason() <> ""
          errorMsg = request.getFailureReason()
      end if
      print "❌ API request failed: " + errorMsg
      m.top.error = errorMsg
  end if
end sub