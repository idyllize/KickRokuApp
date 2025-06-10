' StreamItemComponent.brs - Component logic for stream item display

function init() as void
    ' Initialize component
    m.background = m.top.findNode("background")
    m.selectionIndicator = m.top.findNode("selectionIndicator")
    m.streamerName = m.top.findNode("streamerName")
    m.streamTitle = m.top.findNode("streamTitle")
    m.viewerCount = m.top.findNode("viewerCount")
    m.category = m.top.findNode("category")
    m.statusIndicator = m.top.findNode("statusIndicator")
    
    ' Set initial state
    m.top.focusable = true
    
    ' Set up observers
    m.top.observeField("focusedChild", "onFocusChanged")
end function

' Handle stream data updates - FIXED: Added proper return
function updateDisplay() as void
    streamData = m.top.streamData
    if streamData = invalid then 
        print "StreamItemComponent: No stream data provided"
        return
    end if
    
    ' Update streamer name
    if streamData.streamerName <> invalid then
        m.streamerName.text = streamData.streamerName
    else
        m.streamerName.text = "Unknown Streamer"
    end if
    
    ' Update stream title
    if streamData.streamTitle <> invalid and streamData.streamTitle <> "" then
        m.streamTitle.text = streamData.streamTitle
    else
        m.streamTitle.text = "No title available"
    end if
    
    ' Update viewer count
    if streamData.viewerCount <> invalid then
        m.viewerCount.text = formatViewerCount(streamData.viewerCount)
    else
        m.viewerCount.text = "0 viewers"
    end if
    
    ' Update category
    if streamData.category <> invalid and streamData.category <> "" then
        m.category.text = streamData.category
    else
        m.category.text = "Just Chatting"
    end if
    
    ' Update status indicator
    if streamData.isLive <> invalid and streamData.isLive = true then
        m.statusIndicator.text = "LIVE"
        m.statusIndicator.color = "0xff0000"
    else
        m.statusIndicator.text = "OFFLINE"
        m.statusIndicator.color = "0x666666"
    end if
    
    print "StreamItemComponent: Updated display for " + m.streamerName.text
end function

' Handle selection state changes - FIXED: Added proper return
function updateSelection() as void
    isSelected = m.top.isSelected
    
    if isSelected = true then
        ' Show selection indicator
        if m.selectionIndicator <> invalid then
            m.selectionIndicator.visible = true
        end if
        if m.background <> invalid then
            m.background.color = "0x2a2a2a"
        end if
        
        ' Animate selection (optional)
        animateSelection(true)
        print "StreamItemComponent: Item selected"
    else
        ' Hide selection indicator
        if m.selectionIndicator <> invalid then
            m.selectionIndicator.visible = false
        end if
        if m.background <> invalid then
            m.background.color = "0x1a1a1a"
        end if
        
        ' Animate deselection (optional)
        animateSelection(false)
        print "StreamItemComponent: Item deselected"
    end if
end function

' Handle focus changes
function onFocusChanged() as void
    if m.top.hasFocus() then
        ' Component gained focus
        m.top.isSelected = true
    else
        ' Component lost focus
        m.top.isSelected = false
    end if
end function

' Format viewer count for display
function formatViewerCount(count as Integer) as String
    if count >= 1000000 then
        return str(int(count / 1000000)) + "M viewers"
    else if count >= 1000 then
        return str(int(count / 1000)) + "K viewers"
    else if count > 0 then
        return str(count) + " viewers"
    else
        return "No viewers"
    end if
end function

' Animate selection state (optional enhancement)
function animateSelection(selected as Boolean) as void
    ' Only animate if we have valid nodes
    if m.top = invalid then return
    
    if selected then
        ' Scale up slightly when selected
        scaleAnimation = createObject("roSGNode", "Animation")
        if scaleAnimation <> invalid then
            scaleAnimation.duration = 0.2
            scaleAnimation.easeFunction = "outCubic"
            
            scaleField = createObject("roSGNode", "Vector2DFieldInterpolator")
            if scaleField <> invalid then
                scaleField.key = [0.0, 1.0]
                scaleField.keyValue = [[1.0, 1.0], [1.05, 1.05]]
                scaleField.fieldToInterp = "scale"
                
                scaleAnimation.appendChild(scaleField)
                m.top.appendChild(scaleAnimation)
                scaleAnimation.control = "start"
            end if
        end if
    else
        ' Scale back to normal when deselected
        scaleAnimation = createObject("roSGNode", "Animation")
        if scaleAnimation <> invalid then
            scaleAnimation.duration = 0.2
            scaleAnimation.easeFunction = "outCubic"
            
            scaleField = createObject("roSGNode", "Vector2DFieldInterpolator")
            if scaleField <> invalid then
                scaleField.key = [0.0, 1.0]
                scaleField.keyValue = [[1.05, 1.05], [1.0, 1.0]]
                scaleField.fieldToInterp = "scale"
                
                scaleAnimation.appendChild(scaleField)
                m.top.appendChild(scaleAnimation)
                scaleAnimation.control = "start"
            end if
        end if
    end if
end function

' Key event handler
function onKeyEvent(key as String, press as Boolean) as Boolean
    if press then
        if key = "OK" then
            ' Handle selection
            if m.streamerName <> invalid then
                print "Stream item selected: " + m.streamerName.text
                ' Fire custom event or handle selection logic
                m.top.streamSelected = m.top.streamData
            end if
            return true
        end if
    end if
    
    return false
end function