sub init()
    print "HttpTask: Initializing..."
    m.top.functionName = "executeRequest"
    m.top.isComplete = false
    m.top.isSuccess = false
end sub

sub executeRequest()
    print "HttpTask: Executing request for URL: " + m.top.url
    if m.top.url = invalid or m.top.url = ""
        m.top.error = "No URL specified"
        m.top.isComplete = true
        print "HttpTask: Error - No URL specified"
        return
    end if

    request = createObject("roUrlTransfer")
    if request = invalid
        m.top.error = "Failed to create roUrlTransfer object"
        m.top.isComplete = true
        print "HttpTask: Error - Failed to create roUrlTransfer"
        return
    end if

    request.setUrl(m.top.url)
    request.setCertificatesFile("common:/certs/ca-bundle.crt")
    request.initClientCertificates()
    request.enableEncodings(true)

    ' Set headers
    if m.top.headers <> invalid
        for each header in m.top.headers
            request.addHeader(header, m.top.headers[header])
        end for
    end if

    port = createObject("roMessagePort")
    request.setMessagePort(port)

    if request.asyncGetToString()
        print "HttpTask: Request sent, waiting for response..."
        msg = wait(15000, port) ' 15 second timeout
        if type(msg) = "roUrlEvent"
            responseCode = msg.getResponseCode()
            print "HttpTask: Response code: " + str(responseCode)
            if responseCode = 200
                m.top.response = msg.getString()
                m.top.isSuccess = true
                print "HttpTask: Success - Response length: " + str(len(m.top.response)) + " characters"
            else
                m.top.error = "HTTP error: " + str(responseCode)
                print "HttpTask: Error - HTTP " + str(responseCode)
            end if
        else
            m.top.error = "Request timeout"
            print "HttpTask: Error - Request timeout"
        end if
    else
        m.top.error = "Failed to start request"
        print "HttpTask: Error - Failed to start request"
    end if

    m.top.isComplete = true
    print "HttpTask: Request complete"
end sub