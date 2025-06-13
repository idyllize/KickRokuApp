sub init()
  print "HttpTask: Initializing..."
  m.top.functionName = "executeRequest"
  m.top.isComplete = false
  m.top.isSuccess = false
end sub

sub executeRequest()
  print "HttpTask: Starting request..."
  
  ' Validate URL
  if m.top.url = invalid or m.top.url = ""
      m.top.error = "No URL specified"
      m.top.isComplete = true
      m.top.isSuccess = false
      return
  end if
  
  ' Create request object in task thread
  request = createObject("roUrlTransfer")
  if request = invalid
      m.top.error = "Failed to create roUrlTransfer"
      m.top.isComplete = true
      m.top.isSuccess = false
      return
  end if
  
  ' Configure request
  port = createObject("roMessagePort")
  request.setPort(port)
  request.setUrl(m.top.url)
  request.setCertificatesFile("common:/certs/ca-bundle.crt")
  request.initClientCertificates()
  request.enableEncodings(true)
  
  ' **FIXED: Only use methods that exist in Roku**
  ' setConnectionTimeout is the only timeout method available
  request.setConnectionTimeout(7)
  
  ' Set headers
  if m.top.headers <> invalid
      for each header in m.top.headers
          request.addHeader(header, m.top.headers[header])
      end for
  end if
  
  print "HttpTask: Making async request to: " + m.top.url
  
  ' **Use AsyncGetToString for non-blocking request**
  if request.asyncGetToString()
      print "HttpTask: Async request initiated successfully"
      
      ' **Non-blocking wait with timeout handling**
      timeoutMs = 7000
      intervalMs = 100
      elapsedMs = 0
      
      while elapsedMs < timeoutMs
          ' **Non-blocking wait - check every 100ms**
          msg = wait(intervalMs, port)
          elapsedMs = elapsedMs + intervalMs
          
          if msg <> invalid
              if type(msg) = "roUrlEvent"
                  responseCode = msg.getResponseCode()
                  print "HttpTask: Response received - Code: " + responseCode.toStr()
                  
                  if responseCode = 200
                      response = msg.getString()
                      if response <> invalid and response <> ""
                          m.top.response = response
                          m.top.isSuccess = true
                          print "HttpTask: Success - Response length: " + response.len().toStr()
                      else
                          m.top.error = "Empty response"
                          m.top.isSuccess = false
                          print "HttpTask: Error - Empty response"
                      end if
                  else
                      m.top.error = "HTTP Error: " + responseCode.toStr()
                      m.top.isSuccess = false
                      print "HttpTask: HTTP Error: " + responseCode.toStr()
                  end if
                  
                  m.top.isComplete = true
                  return
              else if type(msg) = "roUrlEvent" and msg.getInt() = 0
                  ' Connection failed or timeout
                  print "HttpTask: Connection failed or timeout"
                  m.top.error = "Connection failed"
                  m.top.isSuccess = false
                  m.top.isComplete = true
                  return
              end if
          end if
          
          ' **Allow other threads to run**
          ' Note: sleep() might not be available, so we rely on the wait() intervals
      end while
      
      ' Timeout occurred
      print "HttpTask: Timeout after " + timeoutMs.toStr() + "ms"
      m.top.error = "Request timeout after " + (timeoutMs/1000).toStr() + " seconds"
      m.top.isSuccess = false
      m.top.isComplete = true
      
  else
      print "HttpTask: Failed to initiate async request"
      m.top.error = "Failed to initiate request"
      m.top.isSuccess = false
      m.top.isComplete = true
  end if
end sub