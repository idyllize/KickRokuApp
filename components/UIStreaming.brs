sub init()
  print "UIStreaming: Initializing..."
  
  ' Get UI elements
  m.videoPlayer = m.top.findNode("videoPlayer")
  m.loadingOverlay = m.top.findNode("loadingOverlay")
  m.loadingText = m.top.findNode("loadingText")
  m.streamInfoBg = m.top.findNode("streamInfoBg")
  m.streamTitle = m.top.findNode("streamTitle")
  m.streamStatus = m.top.findNode("streamStatus")
  
  ' Set up video player observers
  if m.videoPlayer <> invalid
      m.videoPlayer.observeField("state", "onVideoStateChanged")
      m.videoPlayer.observeField("position", "onVideoPositionChanged")
      print "UIStreaming: ✅ Video player observers set"
  end if
  
  m.isSwitching = false
  m.switchCooldown = 500  ' Reduced from 2000ms
  m.switchTimer = invalid  ' Initialize timer reference
  
  print "UIStreaming: ✅ Initialization complete"
end sub


sub onStreamUrlChanged()
  streamUrl = m.top.streamUrl
  if streamUrl <> invalid and streamUrl <> ""
      print "UIStreaming: streamUrl changed to: " + left(streamUrl, 100) + "..."
      loadStream(streamUrl)
  end if
end sub

sub onStreamNameChanged()
  streamName = m.top.streamName
  if streamName <> invalid and streamName <> ""
      print "UIStreaming: Stream name set to: " + streamName
      if m.streamTitle <> invalid
          m.streamTitle.text = streamName
      end if
  end if
end sub

sub loadStream(url as string)
  print "UIStreaming: ðŸ”„ Loading HLS stream URL: " + left(url, 100) + "..."
  
  ' Show loading overlay
  showLoadingOverlay()
  
  if m.videoPlayer <> invalid
      ' âœ… FIXED: Clean URL by removing player_version parameter
      cleanUrl = cleanStreamUrl(url)
      
      print "UIStreaming: âœ… URL cleaned successfully"
      print "UIStreaming: ðŸŽ¯ Original URL: " + left(url, 100) + "..."
      print "UIStreaming: âœ… Cleaned URL: " + left(cleanUrl, 100) + "..."
      
      ' âœ… FIXED: Create HLS content with working headers
      videoContent = createObject("roSGNode", "ContentNode")
      videoContent.url = cleanUrl
      videoContent.streamFormat = "hls"
      videoContent.title = "Kick Live Stream"
      
      ' âœ… WORKING: These headers allow successful playback
      videoContent.HttpHeaders = {
          "User-Agent": "Mozilla/5.0 (compatible; RokuOS)",
          "Accept": "application/vnd.apple.mpegurl, */*"
      }
      
      print "UIStreaming: âœ… Created HLS video content with working headers"
      
      ' âœ… Set video content and play
      m.videoPlayer.content = videoContent
      m.videoPlayer.control = "play"
      
      print "UIStreaming: âœ… Video content set and play command sent"
  else
      print "UIStreaming: âŒ Video player not available"
  end if
end sub

' âœ… FIXED: Clean problematic URL parameters
function cleanStreamUrl(url as string) as string
  cleanUrl = url
  
  ' Remove player_version parameter that causes issues
  if cleanUrl.inStr("&player_version=") > -1
      parts = cleanUrl.split("&player_version=")
      cleanUrl = parts[0]
      print "UIStreaming: âœ… REMOVED player_version parameter"
  end if
  
  return cleanUrl
end function

sub onVideoStateChanged()
  state = m.videoPlayer.state
  print "UIStreaming: 🔄 Video state changed to: " + state
  
  if state = "playing"
    hideLoadingOverlay()
    showStreamInfo()
    print "UIStreaming: ✅ Loading overlay hidden - Stream playing!"
    
    ' **FIX: Reset switching flag when stream successfully starts**
    m.isSwitching = false
    print "UIStreaming: ✅ Stream loaded - switching enabled"
    
    ' Update status
    if m.streamStatus <> invalid
        m.streamStatus.text = "• LIVE | " + getQualityFromUrl(m.top.streamUrl)
    end if
      
      
  else if state = "buffering"
      showLoadingOverlay()
      if m.loadingText <> invalid
          m.loadingText.text = "BUFFERING..."
          m.loadingText.color = "0x53FC18FF"
      end if
      print "UIStreaming: ðŸ”„ Stream is buffering..."
      
  else if state = "paused"
      print "UIStreaming: â¸ï¸ Stream is paused"
      if m.streamStatus <> invalid
          m.streamStatus.text = "â¸ PAUSED"
      end if
      
  else if state = "stopped"
      hideStreamInfo()
      print "UIStreaming: â¹ï¸ Stream has stopped"
      
  else if state = "error"
      hideLoadingOverlay()
      print "UIStreaming: âŒ Video player error occurred"
      showErrorMessage()
      
  else if state = "finished"
      print "UIStreaming: ðŸ Stream finished"
      hideStreamInfo()
  end if
end sub

sub onVideoPositionChanged()
  ' Track playback position for debugging
  position = m.videoPlayer.position
  if position > 0 and position mod 30 = 0  ' Log every 30 seconds
      print "UIStreaming: âœ… Video position: " + position.toStr() + "s (Stream playing normally!)"
  end if
end sub

function getQualityFromUrl(url as string) as string
  ' Try to determine quality from URL or default to HD
  if url.inStr("4k") > -1 or url.inStr("2160") > -1
      return "4K"
  else if url.inStr("1080") > -1 or url.inStr("fhd") > -1
      return "FHD"
  else
      return "HD"
  end if
end function

sub showErrorMessage()
  if m.loadingText <> invalid
      m.loadingText.text = "STREAM UNAVAILABLE"
      m.loadingText.color = "0xFF0000FF"
      showLoadingOverlay()
  end if
  
  ' Show helpful message
  if m.streamStatus <> invalid
      m.streamStatus.text = "Stream may require authentication or be geo-blocked"
  end if
end sub

sub showLoadingOverlay()
  if m.loadingOverlay <> invalid and m.loadingText <> invalid
      m.loadingOverlay.visible = true
      m.loadingText.visible = true
      print "UIStreaming: âœ… Loading overlay shown"
  end if
end sub

sub hideLoadingOverlay()
  if m.loadingOverlay <> invalid and m.loadingText <> invalid
      m.loadingOverlay.visible = false
      m.loadingText.visible = false
      print "UIStreaming: âœ… Loading overlay hidden"
  end if
end sub

sub showStreamInfo()
  if m.streamInfoBg <> invalid and m.streamTitle <> invalid and m.streamStatus <> invalid
      m.streamInfoBg.visible = true
      m.streamTitle.visible = true
      m.streamStatus.visible = true
      print "UIStreaming: âœ… Stream info shown"
  end if
end sub

sub hideStreamInfo()
  if m.streamInfoBg <> invalid and m.streamTitle <> invalid and m.streamStatus <> invalid
      m.streamInfoBg.visible = false
      m.streamTitle.visible = false
      m.streamStatus.visible = false
      print "UIStreaming: âœ… Stream info hidden"
  end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
  if not press then return false
  print "UIStreaming: ✅ Key pressed: " + key
  
  if key = "OK"
      print "UIStreaming: ✅ OK key - toggle play/pause"
      if m.videoPlayer <> invalid
          if m.videoPlayer.state = "playing"
              m.videoPlayer.control = "pause"
          else if m.videoPlayer.state = "paused"
              m.videoPlayer.control = "resume"
          else
              m.videoPlayer.control = "play"
          end if
      end if
      return true
      
  else if key = "left"
      ' **FIX: Check if we're already switching**
      if m.isSwitching
          print "UIStreaming: ⏳ Switch in progress, ignoring left key"
          return true
      end if
      
      print "UIStreaming: ⬅️ Left pressed - switching to previous stream"
      m.isSwitching = true
      m.top.switchStream = "left"
      
      ' **FIX: Start cooldown timer**
      if m.switchTimer <> invalid
          m.switchTimer.unobserveField("fire")
          m.switchTimer.control = "stop"
      end if
      
      m.switchTimer = createObject("roSGNode", "Timer")
      m.switchTimer.duration = m.switchCooldown / 1000.0
      m.switchTimer.observeField("fire", "onSwitchCooldownComplete")
      m.switchTimer.control = "start"
      
      return true
      
  else if key = "right"
      ' **FIX: Check if we're already switching**
      if m.isSwitching
          print "UIStreaming: ⏳ Switch in progress, ignoring right key"
          return true
      end if
      
      print "UIStreaming: ➡️ Right pressed - switching to next stream"
      m.isSwitching = true
      m.top.switchStream = "right"
      
      ' **FIX: Start cooldown timer**
      if m.switchTimer <> invalid
          m.switchTimer.unobserveField("fire")
          m.switchTimer.control = "stop"
      end if
      
      m.switchTimer = createObject("roSGNode", "Timer")
      m.switchTimer.duration = m.switchCooldown / 1000.0
      m.switchTimer.observeField("fire", "onSwitchCooldownComplete")
      m.switchTimer.control = "start"
      
      return true
      
  else if key = "back"
      print "UIStreaming: 🔙 Back pressed - returning to home"
      m.top.backPressed = true
      return true
      
  else if key = "replay"
      print "UIStreaming: 🔄 Replay key - restarting stream"
      if m.top.streamUrl <> invalid and m.top.streamUrl <> ""
          loadStream(m.top.streamUrl)
      end if
      return true
  end if
  
  return false
end function

sub onSwitchCooldownComplete(event)
    print "UIStreaming: ✅ Switch cooldown complete - ready for next switch"
    m.isSwitching = false
    
    ' **FIX: Clear the switchStream field to prevent duplicate switches**
    m.top.switchStream = ""
    
    ' **FIX: Properly clean up the timer**
    if event <> invalid
        timer = event.getRoSGNode()
        if timer <> invalid
            timer.unobserveField("fire")
            timer.control = "stop"
        end if
    end if
    
    ' **FIX: Clear timer reference**
    m.switchTimer = invalid
end sub