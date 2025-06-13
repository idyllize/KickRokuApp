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
  print "StreamScene: 🔄 Stream switch requested: " + switchDirection
  
  if m.streamList.count() = 0
      print "StreamScene: ❌ No streams available for switching"
      return
  end if
  
  ' **ENTERPRISE: Calculate new stream index**
  if switchDirection = "right"
      ' **NEXT STREAM**
      m.currentStreamIndex = m.currentStreamIndex + 1
      if m.currentStreamIndex >= m.streamList.count()
          m.currentStreamIndex = 0  ' Loop back to first stream
      end if
      print "StreamScene: ➡️ Switching to NEXT stream (index " + m.currentStreamIndex.toStr() + ")"
      
  else if switchDirection = "left"
      ' **PREVIOUS STREAM**
      m.currentStreamIndex = m.currentStreamIndex - 1
      if m.currentStreamIndex < 0
          m.currentStreamIndex = m.streamList.count() - 1  ' Loop to last stream
      end if
      print "StreamScene: ⬅️ Switching to PREVIOUS stream (index " + m.currentStreamIndex.toStr() + ")"
  end if
  
  ' **ENTERPRISE: Load the new stream**
  if m.currentStreamIndex >= 0 and m.currentStreamIndex < m.streamList.count()
      newStream = m.streamList[m.currentStreamIndex]
      print "StreamScene: 🔄 Loading new stream: " + newStream.name
      print "StreamScene: 🔄 New URL: " + left(newStream.url, 100) + "..."
      
      ' **ENTERPRISE: Update streaming with new stream**
      m.streaming.streamUrl = newStream.url
      m.streaming.streamName = "@" + newStream.name
      
      print "StreamScene: ✅ Stream switch complete!"
  end if
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