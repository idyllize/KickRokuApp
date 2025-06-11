' NetworkTask.brs - Custom Task component for HTTP requests ONLY

sub init()
    ' Set up the task function ONLY - no streaming logic here
    m.top.functionName = "performHttpRequest"
end sub

sub performHttpRequest()
    ' Get the URL from the task's custom field
    url = m.top.url
    
    if url = invalid or url = ""
        m.top.response = "ERROR: No URL provided"
        return
    end if
    
    print "🌐 NetworkTask: Making request to " + url
    
    ' Create URL transfer object (this works in Task thread)
    http = createObject("roUrlTransfer")
    if http = invalid
        m.top.response = "ERROR: Failed to create roUrlTransfer"
        return
    end if
    
    ' Configure the request
    http.setUrl(url)
    http.setCertificatesFile("common:/certs/ca-bundle.crt")
    http.setRequest("GET")
    http.addHeader("User-Agent", "Roku/KickStreamTest")
    http.addHeader("Accept", "*/*")
    
    ' Make synchronous request (this is fine in Task thread)
    response = http.getToString()
    
    ' Return the response
    if response <> invalid and response <> ""
        print "✅ NetworkTask: Response received (" + response.len().toStr() + " chars)"
        m.top.response = response
    else
        print "❌ NetworkTask: Empty response or network error"
        m.top.response = "ERROR: Empty response or network error"
    end if
end sub