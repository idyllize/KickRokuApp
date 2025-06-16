sub init()
  print "StreamScene: Initializing main scene..."
  
  ' **ENTERPRISE: Get UI components**
  m.splash = m.top.findNode("splash")
  m.home = m.top.findNode("home") 
  m.streaming = m.top.findNode("streaming")
  
  print "StreamScene: Found components - splash:" + (m.splash <> invalid).toStr() + " home:" + (m.home <> invalid).toStr() + " streaming:" + (m.streaming <> invalid).toStr()
  
  ' **ENTERPRISE: Set up observers**
  if m.splash <> invalid
      m.splash.observeField("splashComplete", "onSplashComplete")
      print "StreamScene: ✅ Splash screen observer set"
  end if
  
  if m.home <> invalid
      m.home.observeField("selectedStream", "onStreamSelected")
      print "StreamScene: ✅ Home screen observer set"
  end if
  
  if m.streaming <> invalid
      m.streaming.observeField("backPressed", "onStreamingBack")
      m.streaming.observeField("switchStream", "onStreamSwitch")
      print "StreamScene: ✅ Streaming screen observers set"
  end if
  
  ' **ENTERPRISE: Initialize state**
  m.currentState = "splash"
  m.streamList = []
  m.currentStreamIndex = -1
  
  ' **ENTERPRISE: Show splash screen**
  showSplash()
  
  print "StreamScene: ✅ Scene initialization complete"
  print "    === STREAM SCENE LAUNCHED SUCCESSFULLY ==="
end sub

sub showSplash()
  print "StreamScene: Showing splash screen"
  m.splash.visible = true
  m.home.visible = false
  m.streaming.visible = false
  m.splash.setFocus(true)
  m.currentState = "splash"
end sub

sub onSplashComplete()
  print "StreamScene: Splash completed, transitioning to home..."
  
  ' **ENTERPRISE: Get stream data from splash**
  streamData = m.splash.streamData
  if streamData <> invalid
      ' **ENTERPRISE: Build stream list for switching**
      m.streamList = []
      for each streamerName in streamData
          streamInfo = streamData[streamerName]
          streamEntry = {
              name: streamerName,
              url: streamInfo.url,
              quality: streamInfo.quality
          }
          m.streamList.push(streamEntry)
          print "StreamScene: ✅ Added " + streamerName + " with REAL URL: " + left(streamInfo.url, 80) + "..."
      end for
      
      print "StreamScene: ✅ Built stream list with " + m.streamList.count().toStr() + " REAL streams"
      
      ' **ENTERPRISE: Pass data to home**
      m.home.streamData = streamData
      print "StreamScene: ✅ REAL streamData passed to home with " + streamData.count().toStr() + " streams"
  end if
  
  showHome()
end sub

sub showHome()
  print "StreamScene: Showing home screen"
  m.splash.visible = false
  m.home.visible = true
  m.streaming.visible = false
  m.home.setFocus(true)
  m.currentState = "home"
end sub

sub onStreamSelected()
  selectedStream = m.home.selectedStream
  if selectedStream <> invalid
      streamName = selectedStream.name
      streamUrl = selectedStream.url
      
      print "StreamScene: ✅ Stream selected: " + streamName
      print "StreamScene: ✅ Stream URL: " + left(streamUrl, 100) + "..."
      
      ' **ENTERPRISE: Find stream index in our list**
      for i = 0 to m.streamList.count() - 1
          if m.streamList[i].name = streamName
              m.currentStreamIndex = i
              print "StreamScene: ✅ Set current stream index to: " + i.toStr()
              exit for
          end if
      end for
      
      ' **ENTERPRISE: Load the stream**
      loadCurrentStream()
      showStreaming()
  end if
end sub

sub loadCurrentStream()
  if m.currentStreamIndex >= 0 and m.currentStreamIndex < m.streamList.count()
      currentStream = m.streamList[m.currentStreamIndex]
      
      print "StreamScene: 🔄 Loading stream: " + currentStream.name
      print "StreamScene: 🔄 Real URL: " + left(currentStream.url, 100) + "..."
      
      ' **ENTERPRISE: Set streaming fields**
      m.streaming.streamUrl = currentStream.url
      m.streaming.streamName = "@" + currentStream.name
      
      print "StreamScene: ✅ Fields set with REAL data"
  end if
end sub

sub showStreaming()
  print "StreamScene: Showing streaming screen"
  m.splash.visible = false
  m.home.visible = false
  m.streaming.visible = true
  m.streaming.setFocus(true)
  m.currentState = "streaming"
  print "StreamScene: ✅ Streaming screen is now visible and focused"
  print "StreamScene: ✅ Stream should now be loading with REAL m3u8!"
end sub

sub onStreamingBack()
  print "StreamScene: ⬅️ Back from streaming - returning to home"
  showHome()
end sub
sub onStreamSwitch()
  switchDirection = m.streaming.switchStream
  print "StreamScene: Stream switch requested: " + switchDirection
debugStreamList()  
  
  ' **COMPREHENSIVE VALIDATION**
  if m.streamList = invalid or m.streamList.count() = 0
      print "StreamScene: ❌ No streams available for switching"
      return
  end if
  
  ' **FIX: Ensure current index is valid before switching**
  if m.currentStreamIndex < 0
      m.currentStreamIndex = 0
      print "StreamScene: 🔧 Reset invalid index to 0"
  else if m.currentStreamIndex >= m.streamList.count()
      m.currentStreamIndex = m.streamList.count() - 1
      print "StreamScene: 🔧 Reset out-of-bounds index to last stream"
  end if
  
  ' **DEBUG: Show current state**
  print "StreamScene: 🔍 BEFORE - Index: " + m.currentStreamIndex.toStr() + " of " + m.streamList.count().toStr() + " streams"
  print "StreamScene: 🔍 BEFORE - Current stream: " + m.streamList[m.currentStreamIndex].name
  
  ' **CALCULATE NEW INDEX WITH PROPER BOUNDS CHECKING**
  newIndex = m.currentStreamIndex
  
  if switchDirection = "right"
      ' **NEXT STREAM**
      newIndex = newIndex + 1
      if newIndex >= m.streamList.count()
          newIndex = 0  ' Loop back to first stream
      end if
      print "StreamScene: ➡️ Switching RIGHT from " + m.currentStreamIndex.toStr() + " to " + newIndex.toStr()
      
  else if switchDirection = "left"
      ' **PREVIOUS STREAM**
      newIndex = newIndex - 1
      if newIndex < 0
          newIndex = m.streamList.count() - 1  ' Go to last stream
      end if
      print "StreamScene: ⬅️ Switching LEFT from " + m.currentStreamIndex.toStr() + " to " + newIndex.toStr()
  else
      print "StreamScene: ❌ Invalid switch direction: " + switchDirection
      return
  end if
  
  ' **VALIDATE NEW INDEX**
  if newIndex < 0 or newIndex >= m.streamList.count()
      print "StreamScene: ❌ Calculated invalid new index: " + newIndex.toStr()
      return
  end if
  
  ' **UPDATE CURRENT INDEX**
  m.currentStreamIndex = newIndex
  
  ' **DEBUG: Show new state**
  print "StreamScene: 🎯 AFTER - New index: " + m.currentStreamIndex.toStr()
  print "StreamScene: 🎯 AFTER - New stream: " + m.streamList[m.currentStreamIndex].name
  
  ' **LOAD THE NEW STREAM - GUARANTEED VALID INDEX**
  currentStream = m.streamList[m.currentStreamIndex]
  
  print "StreamScene: 🔄 Loading stream: " + currentStream.name
  print "StreamScene: 🔄 Stream URL: " + left(currentStream.url, 100) + "..."
  
  ' **SET THE NEW STREAM DATA**
    m.streaming.streamUrl = currentStream.url
    m.streaming.streamName = "@" + currentStream.name
    
    print "StreamScene: ✅ Stream switch complete! Now on stream " + (m.currentStreamIndex + 1).toStr() + " of " + m.streamList.count().toStr()
    
    ' **FIX: Clear the switch request to prevent duplicate processing**
    m.streaming.switchStream = ""
end sub

function onKeyEvent(key as string, press as boolean) as boolean
  if press
      print "StreamScene: Key pressed: " + key
      
      ' **ENTERPRISE: Handle keys based on current state**
      if m.currentState = "home"
          if key = "OK"
              print "StreamScene: ✅ OK pressed on home - triggering selection"
              return false  ' Let home handle it
          end if
      else if m.currentState = "streaming"
          if key = "left" or key = "right"
              print "StreamScene: 🔄 Stream switching key in streaming mode"
              return false  ' Let streaming handle it
          end if
      end if
  end if
  
  return false
end function

sub debugStreamList()
  print "StreamScene: === STREAM LIST DEBUG ==="
  if m.streamList <> invalid
      print "StreamScene: Total streams: " + m.streamList.count().toStr()
      for i = 0 to m.streamList.count() - 1
          stream = m.streamList[i]
          marker = ""
          if i = m.currentStreamIndex then marker = " <- CURRENT"
          print "StreamScene: [" + i.toStr() + "] " + stream.name + marker
      end for
  else
      print "StreamScene: ❌ Stream list is invalid"
  end if
  print "StreamScene: === END DEBUG ==="
end sub