sub init()
  print "StreamListItem: === ENTERPRISE CARD INITIALIZATION ==="
  
  ' **FIXED: Get UI elements that actually exist in XML**
  m.streamerName = m.top.findNode("streamerName")
  m.focusRing = m.top.findNode("focusRing")
  m.cardBackground = m.top.findNode("cardBackground")
  m.cardShadow = m.top.findNode("cardShadow")
  m.qualityText = m.top.findNode("qualityText")
  m.infoSection = m.top.findNode("infoSection")
  m.liveText = m.top.findNode("liveText")
  m.platformText = m.top.findNode("platformText")
  
  print "StreamListItem: UI elements found - Name:" + (m.streamerName <> invalid).toStr() + " Focus:" + (m.focusRing <> invalid).toStr()
  
  ' **ENTERPRISE: Make component focusable**
  m.top.focusable = true
  
  ' **ENTERPRISE: Set up comprehensive focus handling**
  m.top.observeField("focusedChild", "onFocusChanged")
  m.top.observeField("hasFocus", "onFocusChanged")
  
  ' **ENTERPRISE: Set professional default content**
  setEnterpriseDefaults()
  
  print "StreamListItem: === ENTERPRISE CARD READY ==="
end sub

sub setEnterpriseDefaults()
  ' **ENTERPRISE: Set professional default values**
  if m.streamerName <> invalid
      m.streamerName.text = "@STREAMER"
  end if
  if m.qualityText <> invalid
      m.qualityText.text = "HD"
  end if
  if m.liveText <> invalid
      m.liveText.text = "LIVE"
  end if
  if m.platformText <> invalid
      m.platformText.text = "KICK"
  end if
  
  print "StreamListItem: ✅ Enterprise defaults set"
end sub

sub onContentChanged()
  print "StreamListItem: === ENTERPRISE CONTENT UPDATE ==="
  
  content = m.top.itemContent
  if content <> invalid and content.title <> invalid
      streamName = content.title
      
      print "StreamListItem: ✅ Setting up enterprise card for: " + streamName
      
      ' **ENTERPRISE: Update streamer name with validation**
      if m.streamerName <> invalid
          m.streamerName.text = "@" + streamName
          print "StreamListItem: ✅ Name set to: @" + streamName
      end if
      
      ' **ENTERPRISE: Set dynamic quality (NOT username specific)**
      if m.qualityText <> invalid
          quality = getDynamicQuality()
          m.qualityText.text = quality
          print "StreamListItem: ✅ Quality set to: " + quality
      end if
      
      print "StreamListItem: ✅ Enterprise card setup complete for " + streamName
  else
      print "StreamListItem: ⚠️ Invalid content - keeping enterprise defaults"
  end if
end sub

sub onFocusChanged()
  ' **ENTERPRISE: Advanced focus detection**
  isFocused = m.top.hasFocus() or (m.top.focusedChild <> invalid)
  
  if isFocused
      ' **ENTERPRISE: FOCUSED STATE - KICK PREMIUM THEME**
      print "StreamListItem: 🎯 ENTERPRISE FOCUSED - Applying premium Kick theme"
      
      ' **ENTERPRISE: Premium green focus ring**
      if m.focusRing <> invalid
          m.focusRing.color = "0x53FC18FF"
      end if
      
      ' **ENTERPRISE: Premium card lighting**
      if m.cardBackground <> invalid
          m.cardBackground.color = "0x2A2A45FF"
      end if
      
      ' **ENTERPRISE: Premium shadow with green glow**
      if m.cardShadow <> invalid
          m.cardShadow.color = "0x53FC1888"
      end if
      
      ' **ENTERPRISE: Premium info section highlight**
      if m.infoSection <> invalid
          m.infoSection.color = "0x1A1A35FF"
      end if
      
  else
      ' **ENTERPRISE: UNFOCUSED STATE - PROFESSIONAL COLORS**
      print "StreamListItem: ⭕ ENTERPRISE UNFOCUSED - Professional state"
      
      ' **ENTERPRISE: Hide focus ring**
      if m.focusRing <> invalid
          m.focusRing.color = "0x00000000"
      end if
      
      ' **ENTERPRISE: Professional card color**
      if m.cardBackground <> invalid
          m.cardBackground.color = "0x1E1E35FF"
      end if
      
      ' **ENTERPRISE: Professional shadow**
      if m.cardShadow <> invalid
          m.cardShadow.color = "0x000000AA"
      end if
      
      ' **ENTERPRISE: Professional info section**
      if m.infoSection <> invalid
          m.infoSection.color = "0x0F0F25FF"
      end if
  end if
end sub

' **DYNAMIC: Quality assignment not based on specific usernames**
function getDynamicQuality() as string
  ' **ENTERPRISE: Random quality assignment for variety**
  qualities = ["HD", "FHD", "4K"]
  randomIndex = rnd(qualities.count()) - 1
  if randomIndex < 0 then randomIndex = 0
  return qualities[randomIndex]
end function
