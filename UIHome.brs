sub init()
  print "UIHome: === INITIALIZING ENTERPRISE HOME SCREEN ==="
  
  ' Get UI elements
  m.streamList = m.top.findNode("streamList")
  m.liveStatus = m.top.findNode("liveStatus")
  m.streamCount = m.top.findNode("streamCount")
  m.instructions = m.top.findNode("instructions")
  
  print "UIHome: Found elements - streamList:" + (m.streamList <> invalid).toStr()
  
  if m.streamList <> invalid
      print "UIHome: ✅ RowList found - Setting up enterprise configuration"
      
      ' **ENTERPRISE: Set up observers**
      m.streamList.observeField("itemFocused", "onStreamFocused")
      m.streamList.observeField("itemSelected", "onStreamSelected")
      
      ' **ENTERPRISE: Make focusable**
      m.streamList.setFocus(true)
      m.top.focusable = true
      
      print "UIHome: ✅ RowList observers and focus configured"
  end if
  
  ' **ENTERPRISE: Initialize with loading status**
  updateStatus("🔴 LOADING STREAMERS...", "Checking live streams...")
  
  ' **ENTERPRISE: Set up stream list**
  setupStreamList()
  
  print "UIHome: === ENTERPRISE HOME SCREEN READY ==="
end sub

sub updateStatus(statusText as string, countText as string)
  if m.liveStatus <> invalid
      m.liveStatus.text = statusText
  end if
  if m.streamCount <> invalid
      m.streamCount.text = countText
  end if
end sub

sub onStreamDataChanged()
  print "UIHome: ✅ Stream data changed - Refreshing list"
  
  streamData = m.top.streamData
  if streamData <> invalid
      liveCount = streamData.count()
      
      if liveCount > 0
          ' **ENTERPRISE: Update sexy status**
          statusText = "🔴 LIVE STREAMERS LOADED!"
          countText = "Found " + liveCount.toStr() + " live streams • Ready to watch!"
          updateStatus(statusText, countText)
          
          ' **ENTERPRISE: Update instructions**
          if m.instructions <> invalid
              m.instructions.text = "◀️ ▶️ Navigate • OK Select Stream • While Streaming: ◀️ ▶️ Switch Streams"
          end if
      else
          updateStatus("❌ NO LIVE STREAMS", "No streamers currently live")
      end if
  end if
  
  setupStreamList()
end sub

sub setupStreamList()
  print "UIHome: === ENTERPRISE STREAM LIST SETUP ==="
  
  streamData = m.top.streamData
  
  if streamData <> invalid and streamData.count() > 0
      print "UIHome: ✅ ENTERPRISE: Processing " + streamData.count().toStr() + " live streams"
      
      ' **ENTERPRISE: Create content for live streams**
      contentNode = createObject("roSGNode", "ContentNode")
      rowContent = createObject("roSGNode", "ContentNode")
      
      for each streamerName in streamData
          streamInfo = streamData[streamerName]
          print "UIHome: Processing enterprise stream: " + streamerName
          
          itemContent = createObject("roSGNode", "ContentNode")
          ' **FIXED: Use standard ContentNode fields - NO streamname/streamurl!**
          itemContent.title = streamerName
          itemContent.description = streamInfo.url
          itemContent.shortDescriptionLine1 = streamerName
          itemContent.shortDescriptionLine2 = "LIVE • " + streamInfo.quality
          
          print "UIHome: ✅ Set REAL URL for " + streamerName + ": " + left(streamInfo.url, 80) + "..."
          
          rowContent.appendChild(itemContent)
          print "UIHome: ✅ Added enterprise stream: " + streamerName
      end for
      
      contentNode.appendChild(rowContent)
      print "UIHome: ✅ ENTERPRISE: Created " + streamData.count().toStr() + " live stream cards"
      
      print "UIHome: 🔄 DEBUG: About to assign content to RowList"
      m.streamList.content = contentNode
      print "UIHome: ✅ ENTERPRISE: Content assigned to RowList"
      
      ' **ENTERPRISE: Focus first item**
      m.streamList.jumpToRowItem = [0, 0]
      print "UIHome: ✅ ENTERPRISE: Stream 0 focused"
      
  else
      print "UIHome: ⚠️ No live stream data - Creating enterprise test streams"
      
      ' **ENTERPRISE: Create test content**
      contentNode = createObject("roSGNode", "ContentNode")
      rowContent = createObject("roSGNode", "ContentNode")
      
      testStreams = [
          {name: "TestStream1", quality: "4K"},
          {name: "TestStream2", quality: "FHD"},
          {name: "TestStream3", quality: "HD"}
      ]
      
      for each stream in testStreams
          itemContent = createObject("roSGNode", "ContentNode")
          ' **FIXED: Use standard ContentNode fields - NO streamname/streamurl!**
          itemContent.title = stream.name
          itemContent.description = "https://example.com/stream/" + stream.name
          itemContent.shortDescriptionLine1 = stream.name
          itemContent.shortDescriptionLine2 = "TEST • " + stream.quality
          
          rowContent.appendChild(itemContent)
          print "UIHome: ✅ Added enterprise test stream: " + stream.name
      end for
      
      contentNode.appendChild(rowContent)
      print "UIHome: ✅ ENTERPRISE: Created " + testStreams.count().toStr() + " test stream cards"
      
      print "UIHome: 🔄 DEBUG: About to assign content to RowList"
      m.streamList.content = contentNode
      print "UIHome: ✅ ENTERPRISE: Content assigned to RowList"
      
      m.streamList.jumpToRowItem = [0, 0]
      print "UIHome: ✅ ENTERPRISE: Stream 0 focused"
      
      updateStatus("🧪 TEST MODE", "Using test streams for development")
  end if
  
  print "UIHome: === ENTERPRISE STREAM LIST SETUP COMPLETE ==="
end sub

sub onStreamFocused()
  ' **FIXED: itemFocused returns integer, not array!**
  focusedIndex = m.streamList.itemFocused
  print "UIHome: ✅ ENTERPRISE: Stream " + focusedIndex.toStr() + " focused"
end sub

sub onStreamSelected()
  print "UIHome: ✅ ENTERPRISE: Stream selection triggered!"
  
  ' **FIXED: Use itemFocused as integer index**
  focusedIndex = m.streamList.itemFocused
  if focusedIndex >= 0 and m.streamList.content <> invalid
      firstRow = m.streamList.content.getChild(0)
      if firstRow <> invalid and focusedIndex < firstRow.getChildCount()
          selectedItem = firstRow.getChild(focusedIndex)
          
          if selectedItem <> invalid
              streamName = selectedItem.title
              streamUrl = selectedItem.description
              
              print "UIHome: ✅ ENTERPRISE: Selected stream: " + streamName
              print "UIHome: ✅ ENTERPRISE: Stream URL: " + left(streamUrl, 100) + "..."
              
              ' **ENTERPRISE: Pass selection to parent**
              m.top.selectedStream = {
                  name: streamName,
                  url: streamUrl
              }
              
              print "UIHome: ✅ ENTERPRISE: Stream selection data passed to parent scene"
          end if
      end if
  end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
  if press and m.streamList <> invalid
      if key = "OK"
          print "UIHome: ✅ OK pressed - selecting stream"
          onStreamSelected()
          return true
      end if
  end if
  
  return false
end function