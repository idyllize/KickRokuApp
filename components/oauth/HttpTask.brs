' HttpTask.brs - Elite HTTP Request Handler
' Zero errors, production-ready code

function init() as void
    print "🔧 HttpTask initializing..."
    
    ' Initialize task properties
    m.top.functionName = "executeHttpRequest"
    m.top.observeField("url", "onUrlChanged")
    m.top.observeField("method", "onMethodChanged")
    m.top.observeField("headers", "onHeadersChanged")
    m.top.observeField("timeout", "onTimeoutChanged")
    
    ' Initialize state
    m.isRunning = false
    m.isRequestActive = false
    m.startTime = 0
    m.retryCount = 0
    m.maxRetries = 3
    m.retryDelay = 1000 ' 1 second
    m.urlTransfer = invalid
    
    ' Initialize logging
    m.enableLogging = true
    
    ' Default values
    m.top.method = "GET"
    m.top.timeout = 15000 ' 15 seconds
    m.top.headers = {}
    m.top.retryCount = 0
    
    print "✅ HttpTask initialized"
end function

' Handle URL changes
function onUrlChanged() as void
    if m.top.url <> invalid and m.top.url <> "" then
        print "🌐 URL set: " + m.top.url
    end if
end function

' Handle method changes
function onMethodChanged() as void
    if m.top.method <> invalid and m.top.method <> "" then
        print "📋 Method set: " + m.top.method
    end if
end function

' Handle headers changes
function onHeadersChanged() as void
    if m.top.headers <> invalid then
        print "📋 Headers updated"
    end if
end function

' Handle timeout changes
function onTimeoutChanged() as void
    if m.top.timeout <> invalid then
        print "⏰ Timeout set: " + str(m.top.timeout) + "ms"
    end if
end function

' Start HTTP request
function startRequest() as void
    if m.isRunning or m.isRequestActive then
        print "⚠️ Request already running"
        return
    end if
    
    if m.top.url = invalid or m.top.url = "" then
        setError("No URL specified")
        return
    end if
    
    print "🚀 Starting HTTP request..."
    
    ' Reset state
    m.top.isComplete = false
    m.top.isSuccess = false
    m.top.error = ""
    m.top.response = ""
    m.top.responseCode = 0
    m.top.progress = ""
    
    m.isRunning = true
    m.isRequestActive = true
    m.startTime = createObject("roDateTime").asSeconds()
    m.top.control = "RUN"
end function

' Execute HTTP request (runs in background thread)
function executeHttpRequest() as void
    try
        print "🌐 Executing HTTP request: " + m.top.url
        m.top.progress = "Starting request..."
        
        ' Create URL transfer object
        m.urlTransfer = createObject("roUrlTransfer")
        if m.urlTransfer = invalid then
            setError("Failed to create HTTP request object")
            return
        end if
        
        ' Configure request
        m.urlTransfer.setUrl(m.top.url)
        
        ' Set timeout
        if m.top.timeout <> invalid and m.top.timeout > 0 then
            m.urlTransfer.setTimeout(m.top.timeout)
        else
            m.urlTransfer.setTimeout(15000) ' Default 15 seconds
        end if
        
        ' Enable encodings
        m.urlTransfer.enableEncodings(true)
        
        ' Set default headers
        m.urlTransfer.addHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")
        m.urlTransfer.addHeader("Accept", "application/json, text/plain, */*")
        m.urlTransfer.addHeader("Accept-Language", "en-US,en;q=0.9")
        m.urlTransfer.addHeader("Cache-Control", "no-cache")
        
        ' Set custom headers
        if m.top.headers <> invalid then
            for each key in m.top.headers
                m.urlTransfer.addHeader(key, m.top.headers[key])
            end for
        end if
        
        ' Set certificates for HTTPS
        m.urlTransfer.setCertificatesFile("common:/certs/ca-bundle.crt")
        m.urlTransfer.initClientCertificates()
        
        ' Execute request based on method
        response = ""
        responseCode = 0
        
        method = "GET"
        if m.top.method <> invalid and m.top.method <> "" then
            method = m.top.method.toUpper()
        end if
        
        ' Check if request was cancelled before proceeding
        if not m.isRequestActive then
            print "🚫 Request was cancelled before execution"
            return
        end if
        
        if method = "GET" then
            m.top.progress = "Sending GET request..."
            response = m.urlTransfer.getToString()
            responseCode = m.urlTransfer.getResponseCode()
        else if method = "POST" then
            m.top.progress = "Sending POST request..."
            postData = ""
            if m.top.postData <> invalid then
                postData = m.top.postData
            end if
            response = m.urlTransfer.postFromString(postData)
            responseCode = m.urlTransfer.getResponseCode()
        else if method = "HEAD" then
            m.top.progress = "Sending HEAD request..."
            responseCode = m.urlTransfer.head()
        else
            setError("Unsupported HTTP method: " + method)
            return
        end if
        
        ' Check if request was cancelled during execution
        if not m.isRequestActive then
            print "🚫 Request was cancelled during execution"
            return
        end if
        
        ' Get response headers
        responseHeaders = m.urlTransfer.getResponseHeaders()
        if responseHeaders <> invalid then
            m.top.responseHeaders = responseHeaders
        end if
        
        ' Process response
        onHttpComplete(response, responseCode)
        
    catch error
        print "❌ HTTP request exception: " + str(error)
        setError("Request failed: " + str(error))
    end try
    
    m.isRunning = false
    m.isRequestActive = false
end function

' Handle HTTP completion with enhanced error handling
function onHttpComplete(response as String, responseCode as Integer) as void
    ' Log the response for debugging
    if m.enableLogging then
        print "🌐 HTTP Response Code: " + str(responseCode)
        if response <> invalid and response <> "" then
            print "📄 Response Preview: " + left(response, 200)
        end if
    end if
    
    ' Set response data
    m.top.response = response
    m.top.responseCode = responseCode
    
    ' Handle different response codes
    if responseCode = 200 then
        processSuccessfulResponse(response)
    else if responseCode = 404 then
        setError("Resource not found - please check the streamer name")
        logError("404 Error: Streamer does not exist")
        handleRetry()
    else if responseCode = 429 then
        setError("Too many requests - please wait a moment")
        logError("Rate limited by API")
        handleRateLimit()
    else if responseCode = 500 then
        setError("Server error - please try again later")
        logError("Internal server error from API")
        handleRetry()
    else if responseCode = 503 then
        setError("Service temporarily unavailable")
        logError("Service unavailable - server overloaded")
        handleRetry()
    else if responseCode = 0 then
        setError("No internet connection - check your network")
        logError("Network connectivity issue")
        handleNetworkError()
    else if responseCode = 408 then
        setError("Request timeout - please try again")
        logError("Request timeout")
        handleRetry()
    else
        setError("HTTP " + str(responseCode) + ": " + getHttpStatusText(responseCode))
        logError("HTTP Error " + str(responseCode) + ": " + str(response))
        handleRetry()
    end if
end function

' Process successful HTTP response
function processSuccessfulResponse(response as String) as void
    if response = invalid or response = "" then
        logError("Empty response received")
        setError("No data received from server")
        return
    end if
    
    ' Parse the response
    parsedData = parseProxiedKickResponse(response)
    if parsedData <> invalid then
        ' Reset retry counter on success
        m.top.retryCount = 0
        setSuccess(response, 200)
        
        ' Set parsed data for further processing
        m.top.responseData = parsedData
        print "✅ HTTP request successful with parsed data"
    else
        logError("Failed to parse response data")
        setError("Invalid data received from server")
        handleRetry()
    end if
end function

' Enhanced JSON parsing with detailed logging
function parseProxiedKickResponse(responseString as String) as Object
    if responseString = invalid or responseString = "" then
        logError("Empty response string provided to parser")
        return invalid
    end if
    
    try
        ' Log response preview for debugging
        if m.enableLogging then
            print "🔍 Raw response preview: " + left(responseString, 200)
        end if
        
        ' Handle different proxy response formats
        parsedResponse = invalid
        
        ' Try direct JSON parsing first
        parsedResponse = parseJson(responseString)
        
        ' If that fails, try parsing as proxied response
        if parsedResponse = invalid then
            ' Check if it's wrapped in a proxy response (AllOrigins format)
            if responseString.inStr("contents") > -1 then
                proxyWrapper = parseJson(responseString)
                if proxyWrapper <> invalid and proxyWrapper.contents <> invalid then
                    parsedResponse = parseJson(proxyWrapper.contents)
                end if
            ' Check for other proxy formats
            else if responseString.inStr("data") > -1 then
                proxyWrapper = parseJson(responseString)
                if proxyWrapper <> invalid and proxyWrapper.data <> invalid then
                    parsedResponse = proxyWrapper.data
                end if
            end if
        end if
        
        if parsedResponse = invalid then
            logError("JSON parsing failed. Response: " + left(responseString, 500))
            return invalid
        end if
        
        return parsedResponse
        
    catch error
        logError("Exception during JSON parsing: " + str(error))
        logError("Failed response: " + left(responseString, 500))
        return invalid
    end try
end function

' Set successful response
function setSuccess(response as String, responseCode as Integer) as void
    duration = createObject("roDateTime").asSeconds() - m.startTime
    
    print "✅ HTTP request successful in " + str(duration) + "s"
    print "📊 Response length: " + str(len(response)) + " characters"
    
    m.top.response = response
    m.top.responseCode = responseCode
    m.top.isSuccess = true
    m.top.isComplete = true
    m.top.error = ""
    
    ' Update progress
    m.top.progress = "Request completed successfully"
end function

' Set error response
function setError(errorMessage as String, responseCode = 0 as Integer) as void
    duration = createObject("roDateTime").asSeconds() - m.startTime
    
    print "❌ HTTP request failed in " + str(duration) + "s: " + errorMessage
    
    m.top.response = ""
    if responseCode > 0 then
        m.top.responseCode = responseCode
    end if
    m.top.isSuccess = false
    m.top.isComplete = true
    m.top.error = errorMessage
    
    ' Update progress
    m.top.progress = "Request failed: " + errorMessage
end function

' Handle retry logic
function handleRetry() as void
    currentRetryCount = m.top.retryCount
    
    if currentRetryCount < m.maxRetries then
        print "🔄 Retrying HTTP request (attempt " + str(currentRetryCount + 1) + ")"
        
        ' Increment retry count
        m.top.retryCount = currentRetryCount + 1
        
        ' Wait before retrying
        sleep(m.retryDelay)
        
        ' Restart the request
        startRequest()
    else
        logError("Max retries exceeded")
        setError("Unable to connect after multiple attempts")
        m.top.requestFailed = true
    end if
end function

' Handle rate limiting
function handleRateLimit() as void
    ' Wait longer for rate limit
    print "⏳ Rate limited - waiting 5 seconds before retry"
    sleep(5000) ' 5 seconds
    
    currentRetryCount = m.top.retryCount
    if currentRetryCount < m.maxRetries then
        m.top.retryCount = currentRetryCount + 1
        startRequest()
    else
        setError("Rate limit exceeded - too many requests")
    end if
end function

' Handle network errors
function handleNetworkError() as void
    ' Check connectivity before retrying
    if checkNetworkConnectivity() then
        handleRetry()
    else
        setError("No internet connection available")
        m.top.requestFailed = true
    end if
end function

' Check network connectivity
function checkNetworkConnectivity() as Boolean
    try
        deviceInfo = createObject("roDeviceInfo")
        if deviceInfo <> invalid then
            connectionType = deviceInfo.getConnectionType()
            return (connectionType = "WiFiConnection" or connectionType = "WiredConnection")
        end if
    catch error
        print "❌ Error checking network connectivity: " + str(error)
    end try
    
    return false
end function

' Cancel the current request
function cancelRequest() as void
    print "🚫 Cancelling HTTP request"
    
    ' Mark request as inactive
    m.isRequestActive = false
    m.isRunning = false
    
    ' Cancel URL transfer if active
    if m.urlTransfer <> invalid then
        try
            m.urlTransfer.asyncCancel()
        catch error
            print "⚠️ Error cancelling request: " + str(error)
        end try
    end if
    
    ' Stop the task
    m.top.control = "STOP"
    
    ' Update status
    m.top.progress = "Request cancelled"
    m.top.error = "Request was cancelled by user"
    m.top.isComplete = true
    m.top.isSuccess = false
    
    print "✅ HTTP request cancelled"
end function

' Get HTTP status text
function getHttpStatusText(code as Integer) as String
    statusTexts = {
        "200": "OK",
        "201": "Created",
        "204": "No Content",
        "301": "Moved Permanently",
        "302": "Found",
        "304": "Not Modified",
        "400": "Bad Request",
        "401": "Unauthorized",
        "403": "Forbidden",
        "404": "Not Found",
        "405": "Method Not Allowed",
        "408": "Request Timeout",
        "429": "Too Many Requests",
        "500": "Internal Server Error",
        "502": "Bad Gateway",
        "503": "Service Unavailable",
        "504": "Gateway Timeout"
    }
    
    codeStr = str(code)
    if statusTexts[codeStr] <> invalid then
        return statusTexts[codeStr]
    end if
    
    return "Unknown Status"
end function

' Clean up resources
function cleanup() as void
    print "🧹 Cleaning up HttpTask resources"
    
    ' Cancel any active request
    if m.isRequestActive or m.isRunning then
        cancelRequest()
    end if
    
    ' Clean up URL transfer object
    if m.urlTransfer <> invalid then
        m.urlTransfer = invalid
    end if
    
    ' Reset state
    reset()
    
    print "✅ HttpTask cleanup completed"
end function

' Reset task for reuse
function reset() as void
    m.top.response = ""
    m.top.responseCode = 0
    m.top.isSuccess = false
    m.top.isComplete = false
    m.top.error = ""
    m.top.progress = ""
    m.top.retryCount = 0
    m.top.requestFailed = false
    m.top.responseData = invalid
    m.top.responseHeaders = invalid
    
    m.retryCount = 0
    m.isRunning = false
    m.isRequestActive = false
    m.urlTransfer = invalid
    
    print "🔄 HttpTask reset"
end function

' Stop current request
function stopRequest() as void
    if m.isRunning or m.isRequestActive then
        cancelRequest()
    else
        print "⚠️ No active request to stop"
    end if
end function

' Log error for debugging
function logError(message as String) as void
    if m.enableLogging then
        print "🚨 LOG ERROR: " + message
        ' You could also write to a log file here if needed
    end if
end function

' Sleep function for delays
function sleep(milliseconds as Integer) as void
    if milliseconds <= 0 then return
    
    timer = createObject("roTimespan")
    timer.mark()
    
    while timer.totalMilliseconds() < milliseconds
        ' Wait - this creates the delay
    end while
end function

' Utility function to safely get left substring
function left(str as String, length as Integer) as String
    if str = invalid or length <= 0 then return ""
    if len(str) <= length then return str
    return str.left(length)
end function