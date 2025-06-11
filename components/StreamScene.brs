' StreamScene.brs - Main streaming logic with improved video handling

function init()
    print "=== Kick.com Live Streaming App: init() ==="
    
    ' Initialize UI elements
    m.loadingSpinner = m.top.findNode("loadingSpinner")
    m.streamList = m.top.findNode("streamList")
    m.videoPlayer = m.top.findNode("videoPlayer")
    m.streamInfo = m.top.findNode("streamInfo")
    m.errorMessage = m.top.findNode("errorMessage")
    
    ' Initialize data
    m.liveStreams = []
    m.currentStreamIndex = 0
    m.streamersToCheck = [
        "trainwreckstv",
        "LosPollosTV",
        "cuffem", 
        "xQc",
        "cheesur",
        "tectone",
        "Adinross",
        "asmongold"
    ]
    m.currentStreamerIndex = 0
    m.currentStreamerName = ""
    m.networkTask = invalid
    m.playbackRetries = 0
    m.maxRetries = 3
    
    ' Set up key handler
    m.top.observeField("buttonSelected", "onButtonSelected")
    
    ' Start loading streams
    loadLiveStreams()
    
    print "=== Init complete ==="
end function

sub loadLiveStreams()
    print "=== Loading Live Kick.com Streamers ==="
    
    ' Show loading indicator
    if m.loadingSpinner <> invalid
        m.loadingSpinner.visible = true
        print "📋 Loading indicator shown"
    end if
    
    ' Hide error message
    if m.errorMessage <> invalid
        m.errorMessage.visible = false
    end if
    
    ' Reset data
    m.liveStreams.clear()
    m.currentStreamerIndex = 0
    
    ' Start checking streamers
    checkNextStreamer()
end sub

sub checkNextStreamer()
    if m.currentStreamerIndex >= m.streamersToCheck.count()
        ' All streamers checked
        finishLoading()
        return
    end if
    
    streamer = m.streamersToCheck[m.currentStreamerIndex]
    m.currentStreamerName = streamer
    
    print "=== Checking: @" + streamer + " (" + (m.currentStreamerIndex + 1).toStr() + "/" + m.streamersToCheck.count().toStr() + ") ==="
    
    url = "https://kickapi-dev.strayfade.com/api/v1/" + streamer
    print "🔗 URL: " + url
    
    ' Create and start network task
    createNetworkTask(url)
end sub

sub createNetworkTask(url as string)
    ' Clean up existing task
    if m.networkTask <> invalid
        m.networkTask.unobserveField("response")
        m.networkTask.control = "stop"
        m.networkTask = invalid
    end if
    
    ' Create NetworkTask
    m.networkTask = createObject("roSGNode", "NetworkTask")
    if m.networkTask <> invalid
        print "✅ NetworkTask created for @" + m.currentStreamerName
        
        ' Set up response observer
        m.networkTask.observeField("response", "onNetworkResponse")
        
        ' Set URL and start
        m.networkTask.url = url
        m.networkTask.control = "RUN"
    else
        print "❌ Failed to create NetworkTask"
        moveToNextStreamer()
    end if
end sub

sub onNetworkResponse(event as object)
    response = event.getData()
    streamerName = m.currentStreamerName
    
    print "📡 Response for @" + streamerName + ": " + left(response, 100) + "..."
    
    if response <> invalid and response <> "" and response.left(6) <> "ERROR:"
        ' Check if response contains .m3u8 (stream URL)
        if response.inStr(".m3u8") >= 0
            print "✅ LIVE: @" + streamerName + " - Stream URL found"
            processStreamUrl(response, streamerName)
        else
            print "❌ @" + streamerName + " - No stream URL (offline)"
        end if
    else
        print "❌ @" + streamerName + " - Network error or offline"
    end if
    
    ' Move to next streamer
    moveToNextStreamer()
end sub

sub processStreamUrl(streamUrl as string, streamerName as string)
    ' Clean the URL (remove any extra whitespace/newlines)
    cleanUrl = streamUrl.trim()
    
    ' Validate URL format and remove player_version parameter
    if cleanUrl.left(4) = "http"
        ' Use string replacement to remove player_version=1.19.0
        cleanUrl = cleanUrl.replace("player_version=1.19.0", "")
        ' Remove any trailing & or ? if parameter was at the end
        if right(cleanUrl, 1) = "&" or right(cleanUrl, 1) = "?"
            cleanUrl = left(cleanUrl, len(cleanUrl) - 1)
        end if
    else
        print "❌ Invalid stream URL format for @" + streamerName
        return
    end if
    
    streamData = {
        username: streamerName,
        title: "Live Stream",
        viewers: "🔴 LIVE",
        category: "Gaming",
        playback_url: cleanUrl,
        thumbnail: "pkg:/images/default_thumbnail.jpg"
    }
    
    m.liveStreams.push(streamData)
    print "📺 Added live stream: @" + streamerName + " (" + m.liveStreams.count().toStr() + " total)"
    print "🔗 Sanitized Stream URL: " + cleanUrl
end sub

sub moveToNextStreamer()
    print "➡️ Moving to next streamer"
    m.currentStreamerIndex++
    
    ' Small delay before next request
    timer = createObject("roSGNode", "Timer")
    timer.duration = 0.3
    timer.observeField("fire", "onTimerFire")
    timer.control = "start"
    m.delayTimer = timer
end sub

sub onTimerFire()
    ' Clean up timer
    if m.delayTimer <> invalid
        m.delayTimer.control = "stop"
        m.delayTimer.unobserveField("fire")
        m.delayTimer = invalid
    end if
    
    ' Continue to next streamer
    checkNextStreamer()
end sub

sub finishLoading()
    print "=== Loading Complete ==="
    print "🎯 Found " + m.liveStreams.count().toStr() + " live streams"
    
    ' Hide loading indicator
    if m.loadingSpinner <> invalid
        m.loadingSpinner.visible = false
    end if
    
    if m.liveStreams.count() > 0
        ' Update UI and play first stream
        updateStreamList()
        playStream(0)
    else
        ' Show no streams message
        showNoStreamsMessage()
    end if
end sub

sub showNoStreamsMessage()
    if m.errorMessage <> invalid
        m.errorMessage.text = "No live streams found." + chr(10) + "All streamers appear to be offline." + chr(10) + "Press OK to refresh."
        m.errorMessage.visible = true
    end if
    
    if m.streamInfo <> invalid
        m.streamInfo.text = "No live streams available" + chr(10) + "Try refreshing in a moment"
    end if
end sub

sub updateStreamList()
    if m.streamList <> invalid and m.liveStreams.count() > 0
        content = createObject("roSGNode", "ContentNode")
        
        for i = 0 to m.liveStreams.count() - 1
            stream = m.liveStreams[i]
            item = createObject("roSGNode", "ContentNode")
            item.title = "@" + stream.username
            item.description = stream.viewers + " • " + stream.category
            item.hdPosterUrl = stream.thumbnail
            content.appendChild(item)
        end for
        
        m.streamList.content = content
        print "📊 Stream list updated with " + m.liveStreams.count().toStr() + " streams"
    end if
end sub

sub playStream(index as integer)
    if index >= 0 and index < m.liveStreams.count()
        m.currentStreamIndex = index
        stream = m.liveStreams[index]
        m.playbackRetries = 0
        
        print "=== 🔴 GOING LIVE ==="
        print "🎮 @" + stream.username
        print "🔗 " + stream.playback_url
        
        ' Update stream info
        updateStreamInfo(stream)
        
        ' Configure video player with enhanced settings
        setupVideoPlayer(stream)
    else
        print "❌ Invalid stream index: " + index.toStr()
    end if
end sub

sub setupVideoPlayer(stream as object)
    if m.videoPlayer <> invalid
        ' Stop current playback first
        m.videoPlayer.control = "stop"
        
        ' Ensure video player is visible and correctly positioned
        m.videoPlayer.visible = true
        print "📺 Video player visibility set to true, position: [" + m.videoPlayer.translation[0].toStr() + ", " + m.videoPlayer.translation[1].toStr() + "]"
        
        ' Remove existing observers
        m.videoPlayer.unobserveField("state")
        m.videoPlayer.unobserveField("position")
        
        ' Create enhanced video content
        videoContent = createObject("roSGNode", "ContentNode")
        videoContent.url = stream.playback_url
        videoContent.title = "@" + stream.username + " - LIVE"
        videoContent.description = "Live stream from Kick.com"
        
        ' Set stream format explicitly
        videoContent.streamFormat = "hls"
        
        ' Add additional metadata for better compatibility
        videoContent.live = true
        videoContent.contentType = "episode"
        
        ' Debug video content setup
        print "🎬 Setting up video player with URL: " + videoContent.url
        print "🎯 Format: " + videoContent.streamFormat
        
        ' Set content and observe state changes
        m.videoPlayer.content = videoContent
        m.videoPlayer.observeField("state", "onVideoPlayerState")
        m.videoPlayer.observeField("error", "onVideoError") ' Add error observer
        
        ' Start playback
        m.videoPlayer.control = "play"
        
        print "🚀 Starting stream for @" + stream.username
    end if
end sub

sub updateStreamInfo(stream as object)
    if m.streamInfo <> invalid
        infoText = "@" + stream.username + " - LIVE" + chr(10)
        infoText += stream.title + chr(10)
        infoText += stream.category + " • " + stream.viewers + chr(10) + chr(10)
        
        ' Show current stream info
        infoText += "Stream " + (m.currentStreamIndex + 1).toStr() + " of " + m.liveStreams.count().toStr() + chr(10)
        infoText += "Retries: " + m.playbackRetries.toStr() + "/" + m.maxRetries.toStr() + chr(10) + chr(10)
        
        infoText += "Controls:" + chr(10)
        infoText += "◀ ▶ Previous/Next Stream" + chr(10)
        infoText += "OK: Play/Pause/Retry" + chr(10)
        infoText += "🔄 Refresh Streams"
        
        m.streamInfo.text = infoText
    end if
end sub

sub onVideoPlayerState(event as object)
    state = event.getData()
    
    if m.liveStreams.count() > 0 and m.currentStreamIndex < m.liveStreams.count()
        stream = m.liveStreams[m.currentStreamIndex]
        
        if state = "playing"
            print "✅ 🔴 LIVE: @" + stream.username + " is now playing! 🎉"
            m.playbackRetries = 0
            updateStreamInfo(stream)
        else if state = "buffering"
            print "⏳ Buffering @" + stream.username + "..."
        else if state = "error"
            print "❌ Playback error for @" + stream.username + " (Retry " + (m.playbackRetries + 1).toStr() + "/" + m.maxRetries.toStr() + ")"
            handlePlaybackError(stream)
        else if state = "stopped"
            print "⏹️ Stream stopped for @" + stream.username
        else if state = "paused"
            print "⏸️ Stream paused for @" + stream.username
        else if state = "finished"
            print "🏁 Stream finished for @" + stream.username
        end if
    end if
end sub

sub onVideoError(event as object)
    errorMsg = event.getData()
    if m.liveStreams.count() > 0 and m.currentStreamIndex < m.liveStreams.count()
        stream = m.liveStreams[m.currentStreamIndex]
        print "❌ Video error for @" + stream.username + ": " + errorMsg
    end if
end sub

sub handlePlaybackError(stream as object)
    m.playbackRetries++
    
    if m.playbackRetries <= m.maxRetries
        print "🔄 Retrying playback for @" + stream.username + " in 2 seconds..."
        updateStreamInfo(stream)
        
        ' Wait and retry
        timer = createObject("roSGNode", "Timer")
        timer.duration = 2.0
        timer.observeField("fire", "onRetryTimer")
        timer.control = "start"
        m.retryTimer = timer
    else
        print "❌ Max retries reached for @" + stream.username + ". Trying next stream..."
        
        ' Try next stream automatically
        if m.currentStreamIndex < m.liveStreams.count() - 1
            playStream(m.currentStreamIndex + 1)
        else
            ' Show error message
            if m.errorMessage <> invalid
                m.errorMessage.text = "Unable to play any streams." + chr(10) + "All streams may be incompatible or offline." + chr(10) + "Press OK to refresh."
                m.errorMessage.visible = true
            end if
        end if
    end if
end sub

sub onRetryTimer()
    ' Clean up timer
    if m.retryTimer <> invalid
        m.retryTimer.control = "stop"
        m.retryTimer.unobserveField("fire")
        m.retryTimer = invalid
    end if
    
    ' Retry current stream
    if m.currentStreamIndex < m.liveStreams.count()
        stream = m.liveStreams[m.currentStreamIndex]
        print "🔄 Retrying @" + stream.username + "..."
        setupVideoPlayer(stream)
    end if
end sub

sub onVideoPlayerPosition()
    ' Removed unused 'event' parameter to fix warning
end sub

sub onButtonSelected(event as object)
    buttonIndex = event.getData()
    
    if buttonIndex = 0 and m.currentStreamIndex > 0
        ' Previous stream
        playStream(m.currentStreamIndex - 1)
    else if buttonIndex = 1 and m.currentStreamIndex < m.liveStreams.count() - 1
        ' Next stream
        playStream(m.currentStreamIndex + 1)
    else if buttonIndex = 2
        ' Refresh streams
        refreshStreams()
    end if
end sub

sub refreshStreams()
    print "🔄 Refreshing streams..."
    
    ' Stop current video
    if m.videoPlayer <> invalid
        m.videoPlayer.control = "stop"
    end if
    
    ' Hide error message
    if m.errorMessage <> invalid
        m.errorMessage.visible = false
    end if
    
    ' Restart loading
    loadLiveStreams()
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if press
        if key = "left" and m.liveStreams.count() > 0 and m.currentStreamIndex > 0
            playStream(m.currentStreamIndex - 1)
            return true
        else if key = "right" and m.liveStreams.count() > 0 and m.currentStreamIndex < m.liveStreams.count() - 1
            playStream(m.currentStreamIndex + 1)
            return true
        else if key = "OK"
            ' Handle OK button based on context
            if m.errorMessage <> invalid and m.errorMessage.visible
                ' Refresh if error is showing
                refreshStreams()
            else if m.liveStreams.count() = 0
                ' Refresh if no streams
                refreshStreams()
            else if m.videoPlayer <> invalid
                ' Toggle play/pause or retry on error
                if m.videoPlayer.state = "playing"
                    m.videoPlayer.control = "pause"
                else if m.videoPlayer.state = "paused"
                    m.videoPlayer.control = "play"
                else if m.videoPlayer.state = "error"
                    ' Retry current stream
                    if m.currentStreamIndex < m.liveStreams.count()
                        stream = m.liveStreams[m.currentStreamIndex]
                        m.playbackRetries = 0
                        setupVideoPlayer(stream)
                    end if
                else
                    m.videoPlayer.control = "play"
                end if
            end if
            return true
        else if key = "back"
            ' Handle back button - could exit app or go to menu
            return true
        end if
    end if
    
    return false
end function