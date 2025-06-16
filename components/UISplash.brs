sub init()
  print "UISplash: Initializing..."
  
  ' **ENTERPRISE: Initialize stream checking**
  m.streamersToCheck = ["cheesur", "cuffem", "Adinross", "iceposeidon", "BigEx", "fishtank", "JakeFuture27", "chickenandy", "n3on", "tectone", "Kaysan", "Konvy", "Trainwreckstv", "LosPollosTV", "asmongold", "sweatergxd"]
  m.currentStreamerIndex = 0
  m.liveStreamers = []
  m.streamData = {}
  
  ' Get UI elements
  m.streamerProgress = m.top.findNode("streamerProgress")
  
  ' **ENTERPRISE: Start checking streams**
  checkStreams()
  
  print "UISplash: Initialization complete"
end sub

sub checkStreams()
  print "=== STARTING STREAM CHECK ==="
  checkNextStreamer()
  ' **NEW: Set up loading animation**
  m.animationTimer = m.top.findNode("animationTimer")
  m.dots = [
      m.top.findNode("dot1"),
      m.top.findNode("dot2"), 
      m.top.findNode("dot3"),
      m.top.findNode("dot4"),
      m.top.findNode("dot5")
  ]
  m.currentDot = 0
  
  if m.animationTimer <> invalid
      m.animationTimer.observeField("fire", "onAnimationTimer")
      m.animationTimer.control = "start"
      print "UISplash: ✅ Loading animation started"
  end if
end sub

sub onAnimationTimer()
  ' Reset all dots to dim
  for i = 0 to m.dots.count() - 1
      if m.dots[i] <> invalid
          m.dots[i].color = "0x53FC1822"  ' Dim green
      end if
  end for
  
  ' Highlight current dot
  if m.dots[m.currentDot] <> invalid
      m.dots[m.currentDot].color = "0x53FC18FF"  ' Bright green
  end if
  
  ' Move to next dot
  m.currentDot = m.currentDot + 1
  if m.currentDot >= m.dots.count()
      m.currentDot = 0
  end if
end sub

sub checkNextStreamer()
  if m.currentStreamerIndex < m.streamersToCheck.count()
      streamerName = m.streamersToCheck[m.currentStreamerIndex]
      print "=== Checking: @" + streamerName + " (" + (m.currentStreamerIndex + 1).toStr() + "/" + m.streamersToCheck.count().toStr() + ") ==="
      
      ' Update streamer progress display
      if m.streamerProgress <> invalid
          m.streamerProgress.text = "@" + streamerName + " " + (m.currentStreamerIndex + 1).toStr() + "/" + m.streamersToCheck.count().toStr()
      end if
      
      ' **ENTERPRISE: Create HTTP task**
      m.httpTask = createObject("roSGNode", "HttpTask")
      m.httpTask.url = "https://kickapi-dev.strayfade.com/api/v1/" + streamerName
      
      ' **ENTERPRISE: Set up observer**
      m.httpTask.observeField("isComplete", "onHttpTaskComplete")
      
      ' **ENTERPRISE: Start request**
      m.httpTask.control = "RUN"
      print "   HttpTask started for @" + streamerName
  else
      ' **ENTERPRISE: All streamers checked**
      finishStreamCheck()
  end if
end sub

sub onHttpTaskComplete()
  print "     onHttpTaskComplete() triggered"
  
  if m.httpTask.isSuccess
      ' **FIXED: API returns raw URL, not JSON - NO ParseJSON needed!**
      rawResponse = m.httpTask.response
      print "     Response for @" + m.streamersToCheck[m.currentStreamerIndex] + ": " + left(rawResponse, 100) + "..."
      
      ' **FIXED: Check if response is a valid m3u8 URL**
      if rawResponse <> invalid and rawResponse <> "" and rawResponse.inStr(".m3u8") > -1
          streamerName = m.streamersToCheck[m.currentStreamerIndex]
          
          ' **ENTERPRISE: Store real stream URL**
          m.streamData[streamerName] = {
              url: rawResponse,
              viewers: "LIVE",
              quality: "4K"
          }
          
          m.liveStreamers.push(streamerName)
          print "     ✅ Added live stream: @" + streamerName + " (" + m.liveStreamers.count().toStr() + " total)"
      else
          print "    @" + m.streamersToCheck[m.currentStreamerIndex] + " - No valid stream URL"
      end if
  else
      print "    HTTP request failed for @" + m.streamersToCheck[m.currentStreamerIndex]
      ' **FIXED: Handle response safely - NO "or" operator!**
      if m.httpTask.response <> invalid
          print "    Response: " + m.httpTask.response
      else
          print "    Response: No response data"
      end if
  end if
  
  ' **ENTERPRISE: Move to next streamer**
  m.currentStreamerIndex = m.currentStreamerIndex + 1
  
  ' **ENTERPRISE: Check next or finish**
  checkNextStreamer()
end sub

sub finishStreamCheck()
  print "=== STREAM CHECK COMPLETE ==="
  print "=== LIVE STREAMERS FOUND: " + m.liveStreamers.count().toStr() + " ==="
  
  for each streamer in m.liveStreamers
      print "     ✅ @" + streamer + " - " + left(m.streamData[streamer].url, 80) + "..."
  end for
  
  ' **ENTERPRISE: Update status**
  statusText = m.top.findNode("statusText")
  if statusText <> invalid
      if m.liveStreamers.count() > 0
          statusText.text = "🔴 Found " + m.liveStreamers.count().toStr() + " live streams!"
      else
          statusText.text = "❌ No live streams found"
      end if
  end if
  
  ' Stop animation
  if m.animationTimer <> invalid
      m.animationTimer.control = "stop"
      print "UISplash: ✅ Loading animation stopped"
  end if
  
  ' **ENTERPRISE: Pass data to parent and complete splash**
  m.top.streamData = m.streamData
  m.top.splashComplete = true
  
  print "=== SPLASH COMPLETE - SWITCHING TO HOME ==="
end sub

sub onStreamerProgressChanged()
  if m.streamerProgress <> invalid
      m.streamerProgress.text = m.top.streamerProgress
  end if
end sub