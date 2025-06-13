sub main()
  print "    === KICK 4K PROFESSIONAL APP IGNITION ==="
  
  ' **ROKU: Get display info properly**
  displayInfo = CreateObject("roDeviceInfo")
  if displayInfo <> invalid
      displayMode = displayInfo.GetDisplayMode()
      displaySize = displayInfo.GetDisplaySize()
      
      print "    === DISPLAY MODE: " + displayMode + " ==="
      print "    === DISPLAY SIZE: " + displaySize.w.toStr() + "x" + displaySize.h.toStr() + " ==="
      
      if displaySize.w < 1920 or displaySize.h < 1080
          print "      === NON-4K DISPLAY DETECTED, OPTIMIZING ==="
      end if
  else
      print "    === DISPLAY INFO: Using defaults ==="
  end if
  
  ' **ENTERPRISE: Create and show main scene**
  screen = CreateObject("roSGScreen")
  m.port = CreateObject("roMessagePort")
  screen.setMessagePort(m.port)
  
  ' **ENTERPRISE: Load main scene**
  screen.CreateScene("StreamScene")
  screen.show()
  
  print "    === STREAM SCENE LAUNCHED SUCCESSFULLY ==="
  
  ' **ENTERPRISE: Main event loop**
  while true
      msg = wait(0, m.port)
      msgType = type(msg)
      
      if msgType = "roSGScreenEvent"
          if msg.isScreenClosed()
              return
          end if
      end if
  end while
end sub