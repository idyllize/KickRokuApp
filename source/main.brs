sub Main()
    print "========================================="
    print "🔴 Starting KickRoku App v1.0..."
    print "========================================="
    
    ' Initialize global variables
    m.screen = invalid
    m.scene = invalid
    m.port = invalid
    
    ' Create and configure the screen
    if not initializeScreen() then
        print "❌ ERROR: Failed to initialize screen"
        return
    end if
    
    ' Load and show the main scene
    if not loadMainScene() then
        print "❌ ERROR: Failed to load main scene"
        cleanup()
        return
    end if
    
    print "✅ SUCCESS: App initialized successfully"
    print "🎬 Scene loaded and ready for user interaction"
    
    ' Start the main event loop
    runEventLoop()
    
    ' Cleanup when app closes
    cleanup()
    print "👋 KickRoku App shutting down..."
end sub

' Initialize the screen object
function initializeScreen() as boolean
    try
        m.screen = CreateObject("roSGScreen")
        if m.screen = invalid then
            print "❌ ERROR: Could not create roSGScreen object"
            return false
        end if
        
        m.port = CreateObject("roMessagePort")
        if m.port = invalid then
            print "❌ ERROR: Could not create roMessagePort object"
            return false
        end if
        
        m.screen.setMessagePort(m.port)
        print "✅ Screen and message port initialized"
        return true
        
    catch error
        print "❌ EXCEPTION in initializeScreen(): "; error.message
        return false
    end try
end function

' Load the main scene
function loadMainScene() as boolean
    try
        ' Create the KickLinkScene
        m.scene = m.screen.CreateScene("KickLinkScene")
        if m.scene = invalid then
            print "❌ ERROR: Could not create KickLinkScene"
            print "🔍 Check if KickLinkScene.xml exists in components/scenes/"
            return false
        end if
        
        ' Show the screen
        m.screen.show()
        print "✅ KickLinkScene loaded and displayed"
        return true
        
    catch error
        print "❌ EXCEPTION in loadMainScene(): "; error.message
        return false
    end try
end function

' Main event loop with enhanced message handling
sub runEventLoop()
    print "🔄 Starting main event loop..."
    
    while true
        ' Wait for messages with timeout for better responsiveness
        msg = wait(100, m.port)
        
        if msg <> invalid then
            msgType = type(msg)
            print "📨 Received message: "; msgType
            
            ' Handle screen events
            if msgType = "roSGScreenEvent" then
                if msg.isScreenClosed() then
                    print "🚪 Screen closed by user"
                    exit while
                end if
                
            ' Handle scene graph node events
            else if msgType = "roSGNodeEvent" then
                handleSceneEvent(msg)
                
            ' Handle other message types
            else
                print "🔍 Unhandled message type: "; msgType
            end if
        end if
        
        ' Optional: Add periodic tasks here
        ' performPeriodicTasks()
    end while
    
    print "🛑 Event loop ended"
end sub

' Handle scene-specific events
sub handleSceneEvent(msg as object)
    try
        node = msg.getRoSGNode()
        field = msg.getField()
        
        if node <> invalid and field <> invalid then
            print "🎯 Scene event - Node: "; node.subtype(); " Field: "; field
            
            ' Add your scene event handling logic here
            ' Example: Handle button presses, list selections, etc.
            
        end if
        
    catch error
        print "❌ ERROR in handleSceneEvent(): "; error.message
    end try
end sub

' Optional: Periodic maintenance tasks
sub performPeriodicTasks()
    ' Add any periodic tasks here like:
    ' - Memory cleanup
    ' - Network status checks
    ' - Analytics updates
    ' - etc.
end sub

' Cleanup resources before app exit
sub cleanup()
    print "🧹 Cleaning up resources..."
    
    try
        if m.scene <> invalid then
            m.scene = invalid
            print "✅ Scene object cleaned up"
        end if
        
        if m.screen <> invalid then
            m.screen.close()
            m.screen = invalid
            print "✅ Screen object cleaned up"
        end if
        
        if m.port <> invalid then
            m.port = invalid
            print "✅ Message port cleaned up"
        end if
        
    catch error
        print "❌ ERROR during cleanup: "; error.message
    end try
end sub