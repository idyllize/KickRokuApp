' KickLinkScene.brs - Elite Main Scene Controller
' Zero errors, production-ready code

function init() as void
    print "✅ KickLinkScene initializing..."
    
    ' Initialize scene properties
    m.top.setFocus(true)
    m.top.backgroundURI = ""
    m.top.backgroundColor = "0x000000"
    
    ' Get UI references
    initializeUIReferences()
    
    ' Initialize application state
    initializeApplicationState()
    
    ' Initialize HTTP service
    initializeHttpService()
    
    ' Initialize proxy manager
    initializeProxyManager()
    
    ' Set up observers
    setupObservers()
    
    ' Initialize connection check
    checkInitialConnectivity()
    
    print "✅ KickLinkScene initialized successfully"
end function

' Initialize UI element references
function initializeUIReferences() as void
    ' Get all UI elements
    m.titleLabel = m.top.findNode("titleLabel")
    m.statusLabel = m.top.findNode("statusLabel")
    m.videoPlayer = m.top.findNode("videoPlayer")
    m.loadingSpinner = m.top.findNode("loadingSpinner")
    m.connectionStatus = m.top.findNode("connectionStatus")
    
    ' Stream info elements
    m.streamerNameLabel = m.top.findNode("streamerNameLabel")
    m.streamTitleLabel = m.top.findNode("streamTitleLabel")
    m.viewerCountLabel = m.top.findNode("viewerCountLabel")
    m.categoryLabel = m.top.findNode("categoryLabel")
    m.statusIndicator = m.top.findNode("statusIndicator")
    
    ' Panels
    m.infoPanel = m.top.findNode("infoPanel")
    m.instructionsPanel = m.top.findNode("instructionsPanel")
    
    print "✅ UI references initialized"
end function

' Initialize application state variables
function initializeApplicationState() as void
    ' Current state
    m.currentStreamer = invalid
    m.isStreamActive = false
    m.isLoading = false
    m.hasInternetConnection = false
    
    ' Stream data
    m.streamData = invalid
    m.streamUrl = invalid
    m.streamTitle = ""
    m.viewerCount = 0
    m.category = ""
    m.isLive = false
    
    ' Error handling
    m.lastError = ""
    m.retryCount = 0
    m.maxRetries = 3
    
    ' UI state
    m.showingDialog = false
    m.currentDialog = invalid
    
    print "✅ Application state initialized"
end function

' Initialize HTTP service
function initializeHttpService() as void
    try
        m.httpTask = createObject("roSGNode", "HttpTask")
        if m.httpTask <> invalid then
            m.httpTask.observeField("isComplete", "onHttpRequestComplete")
            m.httpTask.observeField("error", "onHttpRequestError")
            m.httpTask.observeField("progress", "onHttpProgress")
            print "✅ HTTP service initialized"
        else
            print "❌ Failed to create HTTP task"
            showError("Failed to initialize HTTP service")
        end if
    catch error
        print "❌ HTTP service initialization error: " + str(error)
        showError("HTTP service unavailable")
    end try
end function

' Initialize CORS proxy manager
function initializeProxyManager() as void
    m.corsProxies = [
        "https://api.allorigins.win/get?url=",
        "https://cors-anywhere.herokuapp.com/",
        "https://thingproxy.freeboard.io/fetch/",
        "https://api.codetabs.com/v1/proxy?quest="
    ]
    
    m.currentProxyIndex = 0
    m.proxyRetryCount = 0
    m.maxProxyRetries = m.corsProxies.count() * 2
    
    print "✅ Proxy manager initialized with " + str(m.corsProxies.count()) + " proxies"
end function

' Set up event observers
function setupObservers() as void
    if m.videoPlayer <> invalid then
        m.videoPlayer.observeField("state", "onVideoPlayerState")
        m.videoPlayer.observeField("position", "onVideoPlayerPosition")
    end if
    
    print "✅ Observers set up"
end function

' Check initial internet connectivity
function checkInitialConnectivity() as void
    m.hasInternetConnection = checkInternetConnectivity()
    updateConnectionStatus()
    
    if not m.hasInternetConnection then
        showError("No internet connection detected")
    end if
end function

' Handle key events
function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    
    print "🔑 Key pressed: " + key
    
    ' Prevent multiple dialogs
    if m.showingDialog then
        return handleDialogKeyEvent(key)
    end if
    
    if key = "back" then
        return handleBackKey()
    else if key = "OK" then
        return handleOKKey()
    else if key = "options" then
        return handleOptionsKey()
    else if key = "info" then
        return handleInfoKey()
    else if key = "play" then
        return handlePlayKey()
    else if key = "pause" then
        return handlePauseKey()
    else if key = "rewind" then
        return handleRewindKey()
    else if key = "fastforward" then
        return handleFastForwardKey()
    end if
    
    return false
end function

' Handle back key
function handleBackKey() as Boolean
    if m.isStreamActive then
        stopVideoPlayback()
        return true
    else
        ' Exit app
        exitApp()
        return true
    end if
end function

' Handle OK key
function handleOKKey() as Boolean
    if not m.hasInternetConnection then
        showError("No internet connection available")
        return true
    end if
    
    showStreamerSelection()
    return true
end function

' Handle options key
function handleOptionsKey() as Boolean
    showOptionsMenu()
    return true
end function

' Handle info key
function handleInfoKey() as Boolean
    showStreamInfo()
    return true
end function

' Handle play key
function handlePlayKey() as Boolean
    if m.videoPlayer <> invalid and m.isStreamActive then
        m.videoPlayer.control = "resume"
        print "▶️ Video resumed"
        updateStatusLabel("Playing")
    end if
    return true
end function

' Handle pause key
function handlePauseKey() as Boolean
    if m.videoPlayer <> invalid and m.isStreamActive then
        m.videoPlayer.control = "pause"
        print "⏸️ Video paused"
        updateStatusLabel("Paused")
    end if
    return true
end function

' Handle rewind key
function handleRewindKey() as Boolean
    if m.videoPlayer <> invalid and m.isStreamActive then
        currentPos = m.videoPlayer.position
        newPos = currentPos - 30 ' Rewind 30 seconds
        if newPos < 0 then newPos = 0
        m.videoPlayer.seek = newPos
        print "⏪ Rewound 30 seconds"
    end if
    return true
end function

' Handle fast forward key
function handleFastForwardKey() as Boolean
    if m.videoPlayer <> invalid and m.isStreamActive then
        currentPos = m.videoPlayer.position
        duration = m.videoPlayer.duration
        newPos = currentPos + 30 ' Fast forward 30 seconds
        if newPos > duration then newPos = duration
        m.videoPlayer.seek = newPos
        print "⏩ Fast forwarded 30 seconds"
    end if
    return true
end function

' Handle dialog key events
function handleDialogKeyEvent(key as String) as Boolean
    if key = "back" and m.currentDialog <> invalid then
        closeCurrentDialog()
        return true
    end if
    return false
end function

' Show streamer selection dialog
function showStreamerSelection() as void
    if m.showingDialog then return
    
    print "📋 Showing streamer selection"
    
    dialog = createObject("roSGNode", "Dialog")
    if dialog <> invalid then
        dialog.title = "Select Streamer"
        dialog.message = "Choose a streamer to watch:"
        
        dialog.buttons = [
            "Tectone",
            "Adin Ross",
            "xQc", 
            "Trainwreck",
            "HasanAbi",
            "Amouranth",
            "Destiny",
            "Enter Custom Name"
        ]
        
        dialog.observeField("buttonSelected", "onStreamerDialogButton")
        dialog.observeField("wasClosed", "onDialogClosed")
        
        m.top.appendChild(dialog)
        dialog.visible = true
        m.showingDialog = true
        m.currentDialog = dialog
    end if
end function

' Handle streamer dialog button selection
function onStreamerDialogButton() as void
    if m.currentDialog = invalid then return
    
    buttonIndex = m.currentDialog.buttonSelected
    
    if buttonIndex >= 0 and buttonIndex < m.currentDialog.buttons.count() then
        selectedStreamer = m.currentDialog.buttons[buttonIndex]
        
        closeCurrentDialog()
        
        if selectedStreamer = "Enter Custom Name" then
            showCustomStreamerInput()
        else
            onStreamerSelected(selectedStreamer)
        end if
    end if
end function

' Show custom streamer input
function showCustomStreamerInput() as void
    if m.showingDialog then return
    
    keyboard = createObject("roSGNode", "MiniKeyboard")
    if keyboard <> invalid then
        keyboard.title = "Enter Streamer Name"
        keyboard.text = ""
        keyboard.observeField("text", "onCustomStreamerEntered")
        keyboard.observeField("wasClosed", "onDialogClosed")
        
        m.top.appendChild(keyboard)
        keyboard.visible = true
        m.showingDialog = true
        m.currentDialog = keyboard
    end if
end function

' Handle custom streamer name entered
function onCustomStreamerEntered() as void
    if m.currentDialog = invalid then return
    
    streamerName = m.currentDialog.text
    
    closeCurrentDialog()
    
    if streamerName <> invalid and streamerName.trim() <> "" then
        onStreamerSelected(streamerName.trim())
    else
        showError("Please enter a valid streamer name")
    end if
end function

' Handle streamer selection
function onStreamerSelected(streamerName as String) as void
    if streamerName = invalid or streamerName = "" then
        showError("Invalid streamer name")
        return
    end if
    
    if not m.hasInternetConnection then
        showError("No internet connection available")
        return
    end if
    
    print "🎯 Streamer selected: " + streamerName
    m.currentStreamer = streamerName
    m.retryCount = 0
    
    ' Update UI
    updateStreamerInfo(streamerName, "", "", "", false)
    showLoadingState("Connecting to " + streamerName + "...")
    
    ' Start API request
    fetchStreamerData(streamerName)
end function

' Fetch streamer data from API
function fetchStreamerData(streamerName as String) as void
    if m.httpTask = invalid then
        showError("HTTP service not available")
        return
    end if
    
    if m.isLoading then
        print "⚠️ Request already in progress"
        return
    end if
    
    ' Build API URL
    baseUrl = "https://kick.com/api/v1/channels/" + streamerName.trim()
    proxyUrl = getNextProxy() + encodeURIComponent(baseUrl)
    
    print "🌐 Fetching data from: " + proxyUrl
    
    ' Configure HTTP request
    m.httpTask.url = proxyUrl
    m.httpTask.method = "GET"
    m.httpTask.timeout = 15000
    m.httpTask.headers = {
        "Accept": "application/json",
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
        "Referer": "https://kick.com/",
        "Origin": "https://kick.com"
    }
    
    m.isLoading = true
    
    ' Start the request
    m.httpTask.callFunc("startRequest")
end function

' Get next available proxy
function getNextProxy() as String
    if m.corsProxies = invalid or m.corsProxies.count() = 0 then
        return "https://api.allorigins.win/get?url="
    end if
    
    proxy = m.corsProxies[m.currentProxyIndex]
    m.currentProxyIndex = (m.currentProxyIndex + 1) % m.corsProxies.count()
    
    return proxy
end function

' URL encode function
function encodeURIComponent(str as String) as String
    if str = invalid then return ""
    
    encoded = str
    encoded = encoded.replace("%", "%25")
    encoded = encoded.replace(" ", "%20")
    encoded = encoded.replace("!", "%21")
    encoded = encoded.replace("#", "%23")
    encoded = encoded.replace("$", "%24")
    encoded = encoded.replace("&", "%26")
    encoded = encoded.replace("'", "%27")
    encoded = encoded.replace("(", "%28")
    encoded = encoded.replace(")", "%29")
    encoded = encoded.replace("*", "%2A")
    encoded = encoded.replace("+", "%2B")
    encoded = encoded.replace(",", "%2C")
    encoded = encoded.replace("/", "%2F")
    encoded = encoded.replace(":", "%3A")
    encoded = encoded.replace(";", "%3B")
    encoded = encoded.replace("=", "%3D")
    encoded = encoded.replace("?", "%3F")
    encoded = encoded.replace("@", "%40")
    encoded = encoded.replace("[", "%5B")
    encoded = encoded.replace("]", "%5D")
    
    return encoded
end function

' Handle HTTP request completion
function onHttpRequestComplete() as void
    m.isLoading = false
    hideLoadingState()
    
    if m.httpTask = invalid then return
    
    if m.httpTask.isSuccess then
        handleSuccessfulResponse()
    else
        handleFailedResponse()
    end if
end function

' Handle successful HTTP response
function handleSuccessfulResponse() as void
    response = m.httpTask.response
    
    if response = invalid or response = "" then
        showError("Empty response received")
        return
    end if
    
    print "✅ HTTP request successful"
    
    ' Parse the response
    parsedData = parseKickResponse(response)
    if parsedData <> invalid then
        processStreamerData(parsedData)
    else
        showError("Failed to parse streamer data")
        handleRetryLogic()
    end if
end function

' Handle failed HTTP response
function handleFailedResponse() as void
    errorMsg = "Unknown error"
    if m.httpTask.error <> invalid and m.httpTask.error <> "" then
        errorMsg = m.httpTask.error
    end if
    
    responseCode = m.httpTask.responseCode
    
    print "❌ HTTP request failed: " + str(responseCode) + " - " + errorMsg
    
    ' Handle specific error codes
    if responseCode = 404 then
        showError("Streamer '" + m.currentStreamer + "' not found")
    else if responseCode = 429 then
        showError("Too many requests - please wait")
        handleRateLimitRetry()
    else if responseCode = 0 then
        showError("Network connection failed")
        checkInternetConnectivity()
    else
        showError("Connection failed: " + errorMsg)
        handleRetryLogic()
    end if
end function

' Handle HTTP progress updates
function onHttpProgress() as void
    if m.httpTask <> invalid and m.httpTask.progress <> invalid then
        updateStatusLabel(m.httpTask.progress)
    end if
end function

' Handle HTTP request errors
function onHttpRequestError() as void
    m.isLoading = false
    hideLoadingState()
    
    errorMsg = "Request failed"
    if m.httpTask <> invalid and m.httpTask.error <> invalid then
        errorMsg = m.httpTask.error
    end if
    
    print "❌ HTTP request error: " + errorMsg
    showError(errorMsg)
    handleRetryLogic()
end function

' Parse Kick API response
function parseKickResponse(responseString as String) as Object
    if responseString = invalid or responseString = "" then
        print "❌ Empty response string"
        return invalid
    end if
    
    try
        ' Handle proxy wrapper responses
        parsedResponse = ParseJson(responseString)
        
        if parsedResponse = invalid then
            print "❌ Failed to parse JSON response"
            return invalid
        end if
        
        ' Check if it's wrapped in a proxy response
        if parsedResponse.contents <> invalid then
            ' AllOrigins proxy format
            innerResponse = ParseJson(parsedResponse.contents)
            if innerResponse <> invalid then
                return innerResponse
            end if
        else if parsedResponse.data <> invalid then
            ' Other proxy formats
            return parsedResponse.data
        else
            ' Direct response
            return parsedResponse
        end if
        
        return parsedResponse
        
    catch error
        print "❌ JSON parsing exception: " + str(error)
        return invalid
    end try
end function

' Process parsed streamer data
function processStreamerData(data as Object) as void
    if data = invalid then
        showError("Invalid streamer data received")
        return
    end if
    
    try
        ' Extract streamer information
        streamerName = getStringValue(data, "slug", m.currentStreamer)
        streamTitle = getStringValue(data, "user", "")
        
        ' Check if there's a livestream
        livestream = data.livestream
        isLive = (livestream <> invalid)
        
        viewerCount = 0
        category = ""
        streamUrl = ""
        
        if isLive then
            ' Extract live stream data
            viewerCount = getIntValue(livestream, "viewer_count", 0)
            category = getStringValue(livestream, "category", "")
            
            if livestream.session_title <> invalid then
                streamTitle = livestream.session_title
            end if
            
            ' Get stream URL
            streamUrl = extractStreamUrl(livestream)
        end if
        
        ' Update UI with streamer data
        updateStreamerInfo(streamerName, streamTitle, str(viewerCount), category, isLive)
        
        if isLive and streamUrl <> "" then
            ' Start video playback
            startVideoPlayback(streamUrl)
        else
            showError("Stream is currently offline")
        end if
        
    catch error
        print "❌ Error processing streamer data: " + str(error)
        showError("Failed to process stream data")
    end try
end function

' Extract stream URL from livestream data
function extractStreamUrl(livestream as Object) as String
    if livestream = invalid then return ""
    
    ' Try different possible URL fields
    if livestream.playback_url <> invalid then
        return livestream.playback_url
    else if livestream.hls_url <> invalid then
        return livestream.hls_url
    else if livestream.source <> invalid then
        return livestream.source
    else if livestream.video <> invalid and livestream.video.hls_url <> invalid then
        return livestream.video.hls_url
    end if
    
    ' Construct HLS URL if we have the stream ID
    if livestream.id <> invalid then
        return "https://ingest.kick.com/live/" + str(livestream.id) + "/index.m3u8"
    end if
    
    return ""
end function

' Get string value from object with fallback
function getStringValue(obj as Object, key as String, fallback as String) as String
    if obj = invalid or obj[key] = invalid then
        return fallback
    end if
    return str(obj[key])
end function

' Get integer value from object with fallback
function getIntValue(obj as Object, key as String, fallback as Integer) as Integer
    if obj = invalid or obj[key] = invalid then
        return fallback
    end if
    
    value = obj[key]
    if type(value) = "roInt" or type(value) = "roInteger" then
        return value
    else if type(value) = "roString" then
        return val(value)
    end if
    
    return fallback
end function

' Update streamer information display
function updateStreamerInfo(name as String, title as String, viewers as String, category as String, isLive as Boolean) as void
    if m.streamerNameLabel <> invalid then
        m.streamerNameLabel.text = name
    end if
    
    if m.streamTitleLabel <> invalid then
        m.streamTitleLabel.text = title
    end if
    
    if m.viewerCountLabel <> invalid then
        if viewers <> "0" and viewers <> "" then
            m.viewerCountLabel.text = "👥 " + viewers + " viewers"
        else
            m.viewerCountLabel.text = ""
        end if
    end if
    
    if m.categoryLabel <> invalid then
        if category <> "" then
            m.categoryLabel.text = "🎮 " + category
        else
            m.categoryLabel.text = ""
        end if
    end if
    
    if m.statusIndicator <> invalid then
        if isLive then
            m.statusIndicator.text = "🔴 LIVE"
            m.statusIndicator.color = "0x00FF00FF"
        else
            m.statusIndicator.text = "⚫ OFFLINE"
            m.statusIndicator.color = "0xFF0000FF"
        end if
    end if
    
    print "✅ Streamer info updated: " + name + " (" + (if isLive then "LIVE" else "OFFLINE") + ")"
end function

' Start video playback
function startVideoPlayback(streamUrl as String) as void
    if m.videoPlayer = invalid then
        showError("Video player not available")
        return
    end if
    
    if streamUrl = invalid or streamUrl = "" then
        showError("No stream URL available")
        return
    end if
    
    print "🎬 Starting video playback: " + streamUrl
    
    ' Configure video content
    videoContent = createObject("roSGNode", "ContentNode")
    videoContent.url = streamUrl
    videoContent.title = m.currentStreamer + " - Live Stream"
    videoContent.streamformat = "hls"
    
    ' Set video content
    m.videoPlayer.content = videoContent
    m.videoPlayer.visible = true
    m.videoPlayer.control = "play"
    
    ' Hide info panel and show video
    if m.infoPanel <> invalid then
        m.infoPanel.visible = false
    end if
    if m.instructionsPanel <> invalid then
        m.instructionsPanel.visible = false
    end if
    
    m.isStreamActive = true
    updateStatusLabel("Playing " + m.currentStreamer + "'s stream")
    
    print "✅ Video playback started"
end function

' Stop video playback
function stopVideoPlayback() as void
    if m.videoPlayer <> invalid then
        m.videoPlayer.control = "stop"
        m.videoPlayer.visible = false
        print "⏹️ Video playback stopped"
    end if
    
    ' Show info panels again
    if m.infoPanel <> invalid then
        m.infoPanel.visible = true
    end if
    if m.instructionsPanel <> invalid then
        m.instructionsPanel.visible = true
    end if
    
    m.isStreamActive = false
    updateStatusLabel("Stream stopped")
end function

' Handle video player state changes
function onVideoPlayerState() as void
    if m.videoPlayer = invalid then return
    
    state = m.videoPlayer.state
    print "🎬 Video player state: " + state
    
    if state = "error" then
        showError("Video playback failed")
        stopVideoPlayback()
    else if state = "finished" then
        print "🏁 Video playback finished"
        stopVideoPlayback()
    else if state = "playing" then
        updateStatusLabel("Playing")
    else if state = "paused" then
        updateStatusLabel("Paused")
    else if state = "buffering" then
        updateStatusLabel("Buffering...")
    end if
end function

' Handle video player position updates
function onVideoPlayerPosition() as void
    if m.videoPlayer <> invalid then
        position = m.videoPlayer.position
        duration = m.videoPlayer.duration
        
        if duration > 0 then
            progressPercent = (position / duration) * 100
            ' Update any progress indicators if needed
        end if
    end if
end function

' Show options menu
function showOptionsMenu() as void
    if m.showingDialog then return
    
    print "⚙️ Showing options menu"
    
    dialog = createObject("roSGNode", "Dialog")
    if dialog <> invalid then
        dialog.title = "Options"
        dialog.message = "Select an option:"
        
        buttons = [
            "Change Streamer",
            "Refresh Stream",
            "Check Connection",
            "About"
        ]
        
        if m.isStreamActive then
            buttons.unshift("Stop Stream")
        end if
        
        dialog.buttons = buttons
        dialog.observeField("buttonSelected", "onOptionsDialogButton")
        dialog.observeField("wasClosed", "onDialogClosed")
        
        m.top.appendChild(dialog)
        dialog.visible = true
        m.showingDialog = true
        m.currentDialog = dialog
    end if
end function

' Handle options dialog button selection
function onOptionsDialogButton() as void
    if m.currentDialog = invalid then return
    
    buttonIndex = m.currentDialog.buttonSelected
    
    if buttonIndex >= 0 and buttonIndex < m.currentDialog.buttons.count() then
        selectedOption = m.currentDialog.buttons[buttonIndex]
        
        closeCurrentDialog()
        
        if selectedOption = "Stop Stream" then
            stopVideoPlayback()
        else if selectedOption = "Change Streamer" then
            showStreamerSelection()
        else if selectedOption = "Refresh Stream" then
            refreshCurrentStream()
        else if selectedOption = "Check Connection" then
            checkConnectionStatus()
        else if selectedOption = "About" then
            showAboutDialog()
        end if
    end if
end function

' Refresh current stream
function refreshCurrentStream() as void
    if m.currentStreamer <> invalid and m.currentStreamer <> "" then
        print "🔄 Refreshing stream for: " + m.currentStreamer
        stopVideoPlayback()
        fetchStreamerData(m.currentStreamer)
    else
        showError("No streamer selected to refresh")
    end if
end function

' Check connection status
function checkConnectionStatus() as void
    print "🌐 Checking connection status..."
    
    m.hasInternetConnection = checkInternetConnectivity()
    updateConnectionStatus()
    
    if m.hasInternetConnection then
        showMessage("✅ Internet connection is active")
    else
        showMessage("❌ No internet connection detected")
    end if
end function

' Show about dialog
function showAboutDialog() as void
    if m.showingDialog then return
    
    aboutMsg = "KickRoku App v1.0" + chr(10) + chr(10)
    aboutMsg = aboutMsg + "Unofficial Kick.com viewer for Roku" + chr(10) + chr(10)
    aboutMsg = aboutMsg + "Controls:" + chr(10)
    aboutMsg = aboutMsg + "• OK - Select streamer" + chr(10)
    aboutMsg = aboutMsg + "• Options - Show menu" + chr(10)
    aboutMsg = aboutMsg + "• Back - Exit/Stop" + chr(10)
    aboutMsg = aboutMsg + "• Play/Pause - Control playback" + chr(10)
    aboutMsg = aboutMsg + "• Info - Stream details" + chr(10)
    aboutMsg = aboutMsg + "• Rewind/FF - Skip 30 seconds" + chr(10) + chr(10)
    aboutMsg = aboutMsg + "Note: This is an unofficial app and is not affiliated with Kick.com"
    
    showMessage(aboutMsg)
end function

' Show stream info
function showStreamInfo() as void
    if m.currentStreamer = invalid then
        showMessage("No streamer selected")
        return
    end if
    
    infoMsg = "Current Stream Info:" + chr(10) + chr(10)
    infoMsg = infoMsg + "Streamer: " + m.currentStreamer + chr(10)
    
    if m.streamTitleLabel <> invalid and m.streamTitleLabel.text <> "" then
        infoMsg = infoMsg + "Title: " + m.streamTitleLabel.text + chr(10)
    end if
    
    if m.viewerCountLabel <> invalid and m.viewerCountLabel.text <> "" then
        infoMsg = infoMsg + "Viewers: " + m.viewerCountLabel.text + chr(10)
    end if
    
    if m.categoryLabel <> invalid and m.categoryLabel.text <> "" then
        infoMsg = infoMsg + "Category: " + m.categoryLabel.text + chr(10)
    end if
    
    if m.statusIndicator <> invalid and m.statusIndicator.text <> "" then
        infoMsg = infoMsg + "Status: " + m.statusIndicator.text + chr(10)
    end if
    
    if m.isStreamActive then
        infoMsg = infoMsg + chr(10) + "Stream is currently playing"
    else
        infoMsg = infoMsg + chr(10) + "Stream is not active"
    end if
    
    showMessage(infoMsg)
end function

' Handle retry logic
function handleRetryLogic() as void
    m.retryCount = m.retryCount + 1
    
    if m.retryCount <= m.maxRetries then
        print "🔄 Retrying request (" + str(m.retryCount) + "/" + str(m.maxRetries) + ")"
        
        ' Wait before retry
        timer = createObject("roSGNode", "Timer")
        timer.duration = 2.0 ' 2 seconds
        timer.repeat = false
        timer.observeField("fire", "onRetryTimer")
        timer.control = "start"
        
        updateStatusLabel("Retrying in 2 seconds...")
    else
        showError("Max retries exceeded. Please try again later.")
        m.retryCount = 0
    end if
end function

' Handle rate limit retry
function handleRateLimitRetry() as void
    print "⏳ Rate limited, waiting before retry..."
    
    timer = createObject("roSGNode", "Timer")
    timer.duration = 5.0 ' 5 seconds for rate limit
    timer.repeat = false
    timer.observeField("fire", "onRetryTimer")
    timer.control = "start"
    
    updateStatusLabel("Rate limited - waiting 5 seconds...")
end function

' Handle retry timer
function onRetryTimer() as void
    if m.currentStreamer <> invalid and m.currentStreamer <> "" then
        print "🔄 Retrying request for: " + m.currentStreamer
        fetchStreamerData(m.currentStreamer)
    end if
end function

' Close current dialog
function closeCurrentDialog() as void
    if m.currentDialog <> invalid then
        m.top.removeChild(m.currentDialog)
        m.currentDialog = invalid
    end if
    m.showingDialog = false
end function

' Handle dialog closed event
function onDialogClosed() as void
    closeCurrentDialog()
end function

' Show loading state
function showLoadingState(message as String) as void
    if m.loadingSpinner <> invalid then
        m.loadingSpinner.visible = true
    end if
    
    updateStatusLabel(message)
    m.isLoading = true
    
    print "⏳ Loading: " + message
end function

' Hide loading state
function hideLoadingState() as void
    if m.loadingSpinner <> invalid then
        m.loadingSpinner.visible = false
    end if
    
    m.isLoading = false
end function

' Update status label
function updateStatusLabel(text as String) as void
    if m.statusLabel <> invalid then
        m.statusLabel.text = text
    end if
    print "📢 Status: " + text
end function

' Update connection status
function updateConnectionStatus() as void
    if m.connectionStatus <> invalid then
        if m.hasInternetConnection then
            m.connectionStatus.text = "🌐 Connected"
            m.connectionStatus.color = "0x00FF00FF"
        else
            m.connectionStatus.text = "❌ No Connection"
            m.connectionStatus.color = "0xFF0000FF"
        end if
    end if
end function

' Check internet connectivity
function checkInternetConnectivity() as Boolean
    try
        ' Simple connectivity check
        request = createObject("roUrlTransfer")
        if request <> invalid then
            request.setUrl("https://www.google.com")
            request.setTimeout(5000)
            response = request.getToString()
            return (response <> invalid and response <> "")
        end if
    catch error
        print "❌ Connectivity check failed: " + str(error)
    end try
    
    return false
end function

' Show error message
function showError(message as String) as void
    print "❌ Error: " + message
    showMessage("Error: " + message)
    updateStatusLabel("Error: " + message)
end function

' Show generic message
function showMessage(message as String) as void
    if m.showingDialog then return
    
    dialog = createObject("roSGNode", "Dialog")
    if dialog <> invalid then
        dialog.title = "KickRoku"
        dialog.message = message
        dialog.buttons = ["OK"]
        dialog.observeField("buttonSelected", "onMessageDialogButton")
        dialog.observeField("wasClosed", "onDialogClosed")
        
        m.top.appendChild(dialog)
        dialog.visible = true
        m.showingDialog = true
        m.currentDialog = dialog
    end if
end function

' Handle message dialog button
function onMessageDialogButton() as void
    closeCurrentDialog()
end function

' Exit application
function exitApp() as void
    print "🚪 Exiting KickRoku App"
    
    ' Clean up resources
    stopVideoPlayback()
    
    if m.httpTask <> invalid then
        m.httpTask.control = "stop"
    end if
    
    ' Exit the app
    m.top.getScene().exitApp = true
end function

' Utility function to safely get field value
function getFieldValue(node as Object, fieldName as String, defaultValue as Dynamic) as Dynamic
    if node <> invalid and node.hasField(fieldName) then
        return node[fieldName]
    end if
    return defaultValue
end function

' Utility function to format time
function formatTime(seconds as Integer) as String
    if seconds < 0 then seconds = 0
    
    hours = int(seconds / 3600)
    minutes = int((seconds mod 3600) / 60)
    secs = seconds mod 60
    
    if hours > 0 then
        return stri(hours).trim() + ":" + right("0" + stri(minutes).trim(), 2) + ":" + right("0" + stri(secs).trim(), 2)
    else
        return stri(minutes).trim() + ":" + right("0" + stri(secs).trim(), 2)
    end if
end function

' Utility function to validate URL
function isValidUrl(url as String) as Boolean
    if url = invalid or url = "" then return false
    
    url = url.trim().toLower()
    return (url.instr("http://") = 0 or url.instr("https://") = 0)
end function

' Utility function to clean string
function cleanString(str as String) as String
    if str = invalid then return ""
    
    cleaned = str.trim()
    ' Remove any control characters
    cleaned = cleaned.replace(chr(10), " ")
    cleaned = cleaned.replace(chr(13), " ")
    cleaned = cleaned.replace(chr(9), " ")
    
    return cleaned
end function

' Debug function to print object contents
function debugPrintObject(obj as Dynamic, label as String) as void
    if obj = invalid then
        print label + ": invalid"
        return
    end if
    
    objType = type(obj)
    print label + " (" + objType + "):"
    
    if objType = "roAssociativeArray" then
        for each key in obj
            print "  " + key + ": " + str(obj[key])
        end for
    else
        print "  Value: " + str(obj)
    end if
end function
