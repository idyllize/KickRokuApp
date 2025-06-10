sub init()
    print "INFO: KickOAuthComponent initializing"
    
    ' OAuth Configuration (keep your existing values)
    m.oauthClientId = "01JXAMX23D37C9RQF9ZR1R3T75"
    m.oauthRedirectUri = "http://localhost:8080/oauth/callback"
    m.oauthScopes = "user:read channels:read"
    m.oauthBaseUrl = "https://id.kick.com"
    
    ' PKCE variables
    m.codeVerifier = ""
    m.oauthState = ""
    
    ' UI references
    m.dialogContainer = m.top.findNode("dialogContainer")
    m.loadingGroup = m.top.findNode("loadingGroup")
    m.loadingLabel = m.top.findNode("loadingLabel")
    
    ' Initialize OAuth components
    initializeOAuthHelper()
    initializeHttpTask()
    
    ' Observe field changes
    m.top.observeField("startAuth", "onStartAuth")
    m.top.observeField("authCode", "onAuthCodeReceived")
    m.top.observeField("signOut", "onSignOut")
    
    ' Load existing tokens on startup
    loadSavedTokens()
    
    ' Set initial state
    m.top.isAuthenticated = false
    m.top.isInitialized = true
    
    print "SUCCESS: KickOAuthComponent ready"
end sub

' ========================================
' PUBLIC INTERFACE METHODS
' ========================================
' ========================================
' COMPONENT INITIALIZATION
' ========================================

sub initializeOAuthHelper()
    ' Create OAuth helper task
    m.oauthHelper = CreateObject("roSGNode", "OAuthHelper")
    if m.oauthHelper <> invalid then
        ' Set OAuth configuration
        m.oauthHelper.clientId = m.oauthClientId
        m.oauthHelper.redirectUri = m.oauthRedirectUri
        m.oauthHelper.scopes = m.oauthScopes
        m.oauthHelper.baseUrl = m.oauthBaseUrl
        
        ' Observe completion
        m.oauthHelper.observeField("isComplete", "onOAuthHelperComplete")
        
        print "SUCCESS: OAuthHelper component initialized"
    else
        print "ERROR: Failed to create OAuthHelper component"
    end if
end sub

sub initializeHttpTask()
    ' Create HTTP task for API requests
    m.httpTask = CreateObject("roSGNode", "HttpTask")
    if m.httpTask <> invalid then
        m.httpTask.observeField("isComplete", "onHttpTaskComplete")
        print "SUCCESS: HttpTask component initialized"
    else
        print "ERROR: Failed to create HttpTask component"
    end if
end sub

' ========================================
' OAUTH HELPER CALLBACKS
' ========================================

sub onOAuthHelperComplete()
    if m.oauthHelper.isSuccess then
        action = m.oauthHelper.action
        print "SUCCESS: OAuth action completed: " + action
        
        if action = "generatePKCE" then
            handlePKCEGenerated()
        else if action = "buildAuthUrl" then
            handleAuthUrlBuilt()
        else if action = "exchangeCode" then
            handleTokensReceived()
        else if action = "refreshToken" then
            handleTokensRefreshed()
        else if action = "validateToken" then
            handleTokenValidated()
        end if
    else
        print "ERROR: OAuth operation failed: " + m.oauthHelper.error
        handleOAuthError(m.oauthHelper.error)
    end if
end sub

sub onHttpTaskComplete()
    if m.httpTask.isSuccess then
        print "SUCCESS: HTTP request completed"
        handleHttpResponse(m.httpTask.response, m.httpTask.responseCode)
    else
        print "ERROR: HTTP request failed: " + m.httpTask.error
        handleHttpError(m.httpTask.error)
    end if
end sub

' ========================================
' OAUTH FLOW HANDLERS
' ========================================

sub handlePKCEGenerated()
    ' Store PKCE values
    m.codeVerifier = m.oauthHelper.codeVerifier
    m.oauthState = m.oauthHelper.state
    
    ' Build authorization URL
    m.oauthHelper.action = "buildAuthUrl"
    m.oauthHelper.control = "RUN"
end sub

sub handleAuthUrlBuilt()
    authUrl = m.oauthHelper.authUrl
    print "INFO: Authorization URL ready: " + authUrl
    
    ' Update UI state
    m.top.authState = "url_ready"
    m.top.authUrl = authUrl
    
    ' Show instructions to user
    showAuthDialog(authUrl)
end sub

sub handleTokensReceived()
    ' Store tokens
    m.top.accessToken = m.oauthHelper.accessToken
    m.top.refreshToken = m.oauthHelper.refreshToken

    ' Calculate expiration time (default 1 hour)
    expiresIn = 3600
    if m.oauthHelper.expiresIn <> invalid then
        expiresIn = m.oauthHelper.expiresIn
    end if
    expiration = CreateObject("roDateTime").AsSeconds() + expiresIn

    ' Save tokens persistently
    saveTokens(m.top.accessToken, m.top.refreshToken, expiration)
    
    ' Update authentication state
    m.top.isAuthenticated = true
    m.top.authState = "authenticated"
    
    ' Hide loading UI
    hideLoading()
    
    print "SUCCESS: User authenticated successfully"
end sub

sub handleTokensRefreshed()
    ' Update tokens
    m.top.accessToken = m.oauthHelper.accessToken
    if m.oauthHelper.refreshToken <> "" then
        m.top.refreshToken = m.oauthHelper.refreshToken
    end if
    
    ' Save updated tokens
    saveTokens(m.top.accessToken, m.top.refreshToken, CreateObject("roDateTime").AsSeconds() + 3600)
    
    print "SUCCESS: Tokens refreshed successfully"
end sub

sub handleTokenValidated()
    print "SUCCESS: Access token is valid"
    m.top.isAuthenticated = true
end sub

sub handleOAuthError(errorMessage as String)
    ' Update UI state
    m.top.authState = "error"
    m.top.error = errorMessage
    
    ' Hide loading UI
    hideLoading()
    
    ' Show error to user
    handleAuthError(errorMessage)
end sub

sub handleHttpResponse(response as String, responseCode as Integer)
    ' Handle API responses here
    print "DEBUG: HTTP Response (" + responseCode.toStr() + "): " + response
end sub

sub handleHttpError(errorMessage as String)
    print "ERROR: HTTP Error: " + errorMessage
    ' Handle HTTP errors here
end sub

sub onStartAuth()
    if m.top.startAuth then
        print "INFO: Starting OAuth authentication flow"
        m.top.authState = "starting"
        startOAuthFlow()
        m.top.startAuth = false ' Reset trigger
    end if
end sub

sub onAuthCodeReceived()
    if m.top.authCode <> "" then
        print "INFO: Authorization code received"
        exchangeAuthCode(m.top.authCode)
        m.top.authCode = "" ' Clear sensitive data
    end if
end sub

sub onSignOut()
    if m.top.signOut then
        print "INFO: User sign out requested"
        clearAuthTokens()
        m.top.signOut = false ' Reset trigger
    end if
end sub

' ========================================
' OAUTH FLOW IMPLEMENTATION
' ========================================

sub startOAuthFlow()
    print "INFO: Initiating PKCE OAuth 2.0 flow"
    
    showLoading("Preparing authentication...")
    m.top.authState = "generating_challenge"
    
    ' Generate PKCE challenge
    generatePKCEChallenge()
end sub

sub generatePKCEChallenge()
    print "INFO: Generating PKCE code challenge"
    
    ' Generate code verifier (128 characters)
    m.codeVerifier = generateCodeVerifier()
    
    ' Create SHA256 hash of code verifier
    digest = CreateObject("roEVPDigest")
    digest.Setup("sha256")
    
    ba = CreateObject("roByteArray")
    ba.FromAsciiString(m.codeVerifier)
    hashBytes = digest.Process(ba)
    
    ' Base64 URL encode the hash
    codeChallenge = base64UrlEncode(hashBytes)
    
    ' Generate random state for security
    m.oauthState = generateRandomState()
    
    print "DEBUG: PKCE challenge generated successfully"
    
    ' Build authorization URL
    buildAuthorizationUrl(codeChallenge)
end sub

sub buildAuthorizationUrl(codeChallenge as String)
    print "INFO: Building OAuth authorization URL"
    
    ' Construct OAuth authorization URL with PKCE
    authUrl = m.oauthBaseUrl + "/oauth/authorize"
    authUrl = authUrl + "?client_id=" + m.oauthClientId
    authUrl = authUrl + "&redirect_uri=" + m.oauthRedirectUri
    authUrl = authUrl + "&response_type=code"
    authUrl = authUrl + "&scope=" + m.oauthScopes
    authUrl = authUrl + "&code_challenge=" + codeChallenge
    authUrl = authUrl + "&code_challenge_method=S256"
    authUrl = authUrl + "&state=" + m.oauthState
    
    hideLoading()
    m.top.authState = "awaiting_user"
    
    ' Show authentication dialog to user
    showAuthDialog(authUrl)
end sub

sub exchangeAuthCode(authCode as String)
    print "INFO: Exchanging authorization code for access token"
    
    showLoading("Completing authentication...")
    m.top.authState = "exchanging_token"
    
    ' Prepare token exchange request
    tokenUrl = m.oauthBaseUrl + "/oauth/token"
    
    ' Build POST data for token exchange
    postData = "grant_type=authorization_code"
    postData = postData + "&client_id=" + m.oauthClientId
    postData = postData + "&code=" + authCode
    postData = postData + "&redirect_uri=" + m.oauthRedirectUri
    postData = postData + "&code_verifier=" + m.codeVerifier
    
    ' Create HTTP request
    request = CreateObject("roUrlTransfer")
    request.SetUrl(tokenUrl)
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.InitClientCertificates()
    request.EnableEncodings(true)
    
    ' Set headers
    request.AddHeader("Content-Type", "application/x-www-form-urlencoded")
    request.AddHeader("Accept", "application/json")
    request.AddHeader("User-Agent", "Roku-KickApp/1.0")
    
    ' Set up async request
    request.SetMessagePort(CreateObject("roMessagePort"))
    
    ' Execute token exchange
    if request.AsyncPostFromString(postData) then
        ' Wait for response
        msg = wait(15000, request.GetMessagePort())
        if type(msg) = "roUrlEvent" then
            handleTokenResponse(msg)
        else
            handleAuthError("Token exchange timeout")
        end if
    else
        handleAuthError("Failed to initiate token exchange")
    end if
end sub

sub handleTokenResponse(msg as Object)
    responseCode = msg.GetResponseCode()
    responseString = msg.GetString()
    
    print "DEBUG: Token response code: " + responseCode.toStr()
    
    if responseCode = 200 then
        ' Parse JSON response
        json = ParseJson(responseString)
        if json <> invalid and json.access_token <> invalid then
            ' Extract tokens
            accessToken = json.access_token
            refreshToken = ""
            if json.refresh_token <> invalid then
                refreshToken = json.refresh_token
            end if
            
            ' Calculate expiration time
            expiresIn = 3600 ' Default 1 hour
            if json.expires_in <> invalid then
                expiresIn = json.expires_in
            end if
            expiration = CreateObject("roDateTime").AsSeconds() + expiresIn
            
            ' Save tokens securely
            saveTokens(accessToken, refreshToken, expiration)
            
            hideLoading()
            m.top.authState = "authenticated"
            showAuthSuccess()
            
        else
            handleAuthError("Invalid token response format")
        end if
    else
        handleAuthError("Token exchange failed: " + responseCode.toStr())
    end if
end sub

' ========================================
' TOKEN MANAGEMENT
' ========================================

sub saveTokens(accessToken as String, refreshToken as String, expiration as Integer)
    print "INFO: Saving OAuth tokens securely"
    
    ' Save to secure registry
    registry = CreateObject("roRegistrySection", "KickAuth")
    registry.Write("access_token", accessToken)
    registry.Write("refresh_token", refreshToken)
    registry.Write("token_expiration", expiration.toStr())
    registry.Flush()
    
    ' Update component state
    m.top.accessToken = accessToken
    m.top.refreshToken = refreshToken
    m.top.isAuthenticated = true
    
    print "SUCCESS: OAuth tokens saved successfully"
end sub

sub loadSavedTokens()
    print "INFO: Loading saved OAuth tokens"
    
    registry = CreateObject("roRegistrySection", "KickAuth")
    
    savedAccessToken = registry.Read("access_token")
    savedRefreshToken = registry.Read("refresh_token")
    savedExpiration = registry.Read("token_expiration")
    
    if savedAccessToken <> "" and savedExpiration <> "" then
        currentTime = CreateObject("roDateTime").AsSeconds()
        expirationTime = Val(savedExpiration)
        
        if currentTime < expirationTime then
            ' Token is still valid
            m.top.accessToken = savedAccessToken
            m.top.refreshToken = savedRefreshToken
            m.top.isAuthenticated = true
            m.top.authState = "authenticated"
            print "SUCCESS: Valid saved tokens loaded"
        else if savedRefreshToken <> "" then
            ' Token expired, try refresh
            print "INFO: Access token expired, attempting refresh"
            refreshAccessToken(savedRefreshToken)
        else
            print "INFO: No valid saved tokens found"
            m.top.authState = "unauthenticated"
        end if
    else
        print "INFO: No saved tokens found"
        m.top.authState = "unauthenticated"
    end if
end sub

sub refreshAccessToken(refreshToken as String)
    print "INFO: Refreshing access token"
    
    showLoading("Refreshing authentication...")
    m.top.authState = "refreshing"
    
    ' For demo purposes, simulate successful refresh
    ' In production, make actual API call to refresh endpoint
    newAccessToken = "refreshed_" + CreateObject("roDateTime").AsSeconds().toStr()
    newExpiration = CreateObject("roDateTime").AsSeconds() + 3600
    
    saveTokens(newAccessToken, refreshToken, newExpiration)
    hideLoading()
    
    print "SUCCESS: Access token refreshed"
end sub

sub clearAuthTokens()
    print "INFO: Clearing authentication tokens"
    
    ' Clear from registry
    registry = CreateObject("roRegistrySection", "KickAuth")
    registry.Delete("access_token")
    registry.Delete("refresh_token")
    registry.Delete("token_expiration")
    registry.Flush()
    
    ' Clear component state
    m.top.accessToken = ""
    m.top.refreshToken = ""
    m.top.isAuthenticated = false
    m.top.authState = "signed_out"
    
    showSignOutSuccess()
    
    print "SUCCESS: Authentication cleared"
end sub

' ========================================
' UI MANAGEMENT
' ========================================

sub showLoading(message as String)
    if m.loadingLabel <> invalid then
        m.loadingLabel.text = message
    end if
    if m.loadingGroup <> invalid then
        m.loadingGroup.visible = true
    end if
end sub

sub hideLoading()
    if m.loadingGroup <> invalid then
        m.loadingGroup.visible = false
    end if
end sub

sub showAuthDialog(authUrl as String)
    print "INFO: Displaying authentication dialog"
    
    nl = Chr(10)
    dialog = CreateObject("roSGNode", "Dialog")
    dialog.title = "🔐 Kick.com Authentication"
    
    msg = "To access your personalized content:" + nl + nl
    msg = msg + "1. Visit this URL on your phone/computer:" + nl
    msg = msg + authUrl + nl + nl
    msg = msg + "2. Sign in to your Kick.com account" + nl
    msg = msg + "3. Copy the authorization code" + nl
    msg = msg + "4. Return here to enter the code" + nl + nl
    msg = msg + "This is a secure, one-time setup process."
    
    dialog.message = msg
    dialog.buttons = ["Enter Code", "Cancel"]
    dialog.observeField("buttonSelected", "onAuthDialogResponse")
    
    m.dialogContainer.appendChild(dialog)
    m.dialogContainer.visible = true
    dialog.visible = true
end sub

sub showAuthSuccess()
    nl = Chr(10)
    dialog = CreateObject("roSGNode", "Dialog")
    dialog.title = "🎉 Authentication Successful!"
    
    msg = "Welcome to Kick.com!" + nl + nl
    msg = msg + "You now have access to:" + nl
    msg = msg + "• Personalized stream recommendations" + nl
    msg = msg + "• Subscriber-only content" + nl
    msg = msg + "• Enhanced viewing features" + nl
    msg = msg + "• Your followed channels" + nl + nl
    msg = msg + "Your login is securely saved."
    
    dialog.message = msg
    dialog.buttons = ["Continue"]
    dialog.observeField("buttonSelected", "onDialogClose")
    
    m.dialogContainer.appendChild(dialog)
    dialog.visible = true
end sub

sub showSignOutSuccess()
    nl = Chr(10)
    dialog = CreateObject("roSGNode", "Dialog")
    dialog.title = "👋 Signed Out"
    
    msg = "You have been signed out of Kick.com." + nl + nl
    msg = msg + "You can still browse public streams." + nl
    msg = msg + "Sign in again anytime for full features."
    
    dialog.message = msg
    dialog.buttons = ["OK"]
    dialog.observeField("buttonSelected", "onDialogClose")
    
    m.dialogContainer.appendChild(dialog)
    dialog.visible = true
end sub

' ========================================
' DIALOG EVENT HANDLERS
' ========================================

sub onAuthDialogResponse()
    dialog = m.dialogContainer.getChild(m.dialogContainer.getChildCount() - 1)
    buttonIndex = dialog.buttonSelected
    
    closeDialog()
    
    if buttonIndex = 0 then
        ' User chose to enter code
        showCodeInputDialog()
    else
        ' User cancelled
        m.top.authState = "cancelled"
        m.top.errorMessage = "Authentication cancelled by user"
    end if
end sub

sub onDialogClose()
    closeDialog()
end sub

sub closeDialog()
    if m.dialogContainer.getChildCount() > 0 then
        dialog = m.dialogContainer.getChild(m.dialogContainer.getChildCount() - 1)
        dialog.visible = false
        m.dialogContainer.removeChild(dialog)
    end if
    m.dialogContainer.visible = false
end sub

sub showCodeInputDialog()
    nl = Chr(10)
    dialog = CreateObject("roSGNode", "Dialog")
    dialog.title = "Enter Authorization Code"
    
    msg = "Please enter the code from Kick.com:" + nl + nl
    msg = msg + "For testing, you can use: DEMO_CODE_123" + nl + nl
    msg = msg + "In production, this would use a custom" + nl
    msg = msg + "keyboard component for secure entry."
    
    dialog.message = msg
    dialog.buttons = ["Use Demo Code", "Manual Entry", "Cancel"]
    dialog.observeField("buttonSelected", "onCodeInputResponse")
    
    m.dialogContainer.appendChild(dialog)
    dialog.visible = true
end sub

sub onCodeInputResponse()
    dialog = m.dialogContainer.getChild(m.dialogContainer.getChildCount() - 1)
    buttonIndex = dialog.buttonSelected
    
    closeDialog()
    
    if buttonIndex = 0 then
        ' Use demo code
        m.top.authCode = "DEMO_CODE_123"
    else if buttonIndex = 1 then
        ' Manual entry (would show keyboard in production)
        showManualEntryInfo()
    else
        ' Cancel
        m.top.authState = "cancelled"
    end if
end sub

sub showManualEntryInfo()
    nl = Chr(10)
    dialog = CreateObject("roSGNode", "Dialog")
    dialog.title = "Manual Code Entry"
    
    msg = "In a production app, this would show:" + nl + nl
    msg = msg + "• Custom on-screen keyboard" + nl
    msg = msg + "• Secure text input field" + nl
    msg = msg + "• Real-time validation" + nl + nl
    msg = msg + "For now, using demo authentication."
    
    dialog.message = msg
    dialog.buttons = ["OK"]
    dialog.observeField("buttonSelected", "onDialogClose")
    
    m.dialogContainer.appendChild(dialog)
    dialog.visible = true
    
    ' Auto-use demo code for testing
    m.top.authCode = "DEMO_CODE_123"
end sub

sub handleAuthError(errorMsg as String)
    print "ERROR: OAuth authentication failed: " + errorMsg
    
    hideLoading()
    m.top.authState = "error"
    m.top.errorMessage = errorMsg
    
    nl = Chr(10)
    dialog = CreateObject("roSGNode", "Dialog")
    dialog.title = "❌ Authentication Error"
    
    msg = "Authentication failed:" + nl + nl
    msg = msg + errorMsg + nl + nl
    msg = msg + "Please try again or check your connection."
    
    dialog.message = msg
    dialog.buttons = ["Retry", "Cancel"]
    dialog.observeField("buttonSelected", "onErrorDialogResponse")
    
    m.dialogContainer.appendChild(dialog)
    m.dialogContainer.visible = true
    dialog.visible = true
end sub

sub onErrorDialogResponse()
    dialog = m.dialogContainer.getChild(m.dialogContainer.getChildCount() - 1)
    buttonIndex = dialog.buttonSelected
    
    closeDialog()
    
    if buttonIndex = 0 then
        ' Retry authentication
        m.top.startAuth = true
    else
        ' Cancel
        m.top.authState = "cancelled"
    end if
end sub

' ========================================
' UTILITY FUNCTIONS
' ========================================

function generateCodeVerifier() as String
    chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
    verifier = ""
    
    for i = 1 to 128
        randomIndex = Rnd(chars.Len()) - 1
        verifier = verifier + Mid(chars, randomIndex + 1, 1)
    end for
    
    return verifier
end function

function base64UrlEncode(bytes as Object) as String
    ba = CreateObject("roByteArray")
    ba.Append(bytes)
    
    encodedString = ba.ToBase64String()
    
    ' Make URL safe
    urlSafe = encodedString.Replace("+", "-")
    urlSafe = urlSafe.Replace("/", "_")
    urlSafe = urlSafe.Replace("=", "")
    
    return urlSafe
end function

function generateRandomState() as String
    chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    state = ""
    for i = 1 to 32
        randomIndex = Rnd(chars.Len()) - 1
        state = state + Mid(chars, randomIndex + 1, 1)
    end for
    return state
end function