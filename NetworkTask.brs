sub init()
    m.top.functionName = "performHttpRequest"
    m.top.timeout = 10000 ' Default 10s timeout
    m.retryCount = 0
    m.maxRetries = 2
end sub

sub performHttpRequest()
    url = m.top.url
    
    if url = invalid or url = ""
        m.top.response = "ERROR: No URL provided"
        return
    end if
    
    print "🌐 NetworkTask: Making request to " + url + " (Attempt " + (m.retryCount + 1).toStr() + ")"
    
    http = createObject("roUrlTransfer")
    if http <> invalid
        port = createObject("roMessagePort")
        http.setPort(port)
        http.setUrl(url)
        http.setCertificatesFile("common:/certs/ca-bundle.crt")
        http.setRequest("GET")
        http.addHeader("User-Agent", "Roku/KickStreamTest")
        http.addHeader("Accept", "*/*")
        http.enableCookies()
        http.retainBodyOnError(true)
        
        if http.asyncGetToString()
            msg = wait(m.top.timeout, port)
            if type(msg) = "roUrlEvent"
                code = msg.getResponseCode()
                if code = 200
                    response = msg.getString()
                    if response <> invalid and response <> ""
                        print "✅ NetworkTask: Response received (" + response.len().toStr() + " chars)"
                        m.top.response = response
                        m.retryCount = 0 ' Reset retry counter on success
                    else
                        handleError("Empty response")
                    end if
                else
                    handleError("HTTP error " + code.toStr())
                end if
            else
                handleError("No response within timeout")
            end if
        else
            handleError("Async request failed")
        end if
    else
        handleError("Failed to create roUrlTransfer")
    end if
end sub

sub handleError(message as string)
    print "❌ NetworkTask: " + message
    
    ' Retry logic
    if m.retryCount < m.maxRetries
        m.retryCount = m.retryCount + 1
        print "🔄 NetworkTask: Retrying... (Attempt " + (m.retryCount + 1).toStr() + " of " + (m.maxRetries + 1).toStr() + ")"
        performHttpRequest()
    else
        m.top.response = "ERROR: " + message + " (after " + (m.retryCount + 1).toStr() + " attempts)"
        m.retryCount = 0 ' Reset for next request
    end if
end sub