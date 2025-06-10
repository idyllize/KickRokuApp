' OAuthHelper.brs - OAuth 2.0 PKCE Helper for Kick.com
' Handles all OAuth operations as background tasks

' ========================================
' INITIALIZATION
' ========================================

sub init()
    print "INFO: OAuthHelper Task initialized"
    m.top.functionName = "handleOAuthTask"
    m.top.isComplete = false
    m.top.isSuccess = false
end sub

' ========================================
' MAIN TASK HANDLER
' ========================================

sub handleOAuthTask()
    action = m.top.action
    print "INFO: Handling OAuth action: " + action
    
    ' Update progress
    m.top.progress = "Starting " + action + "..."
    
    try
        if action = "generatePKCE" then
            generatePKCEChallenge()
        else if action = "buildAuthUrl" then
            buildAuthorizationUrl()
        else if action = "exchangeCode" then
            exchangeAuthorizationCode()
        else if action = "refreshToken" then
            refreshAccessToken()
        else if action = "validateToken" then
            validateAccessToken()
        else
            setError("Unknown action: " + action)
        end if
    catch error
        setError("OAuth task failed: " + error.message)
    end try
end sub

' ========================================
' PKCE CHALLENGE GENERATION
' ========================================

sub generatePKCEChallenge()
    print "INFO: Generating PKCE challenge"
    m.top.progress = "Generating security challenge..."
    
    try
        ' Generate cryptographically secure code verifier (43-128 characters)
        codeVerifier = generateCodeVerifier()
        m.top.codeVerifier = codeVerifier
        
        ' Create SHA256 hash of code verifier
        codeChallenge = createCodeChallenge(codeVerifier)
        m.top.codeChallenge = codeChallenge
        
        ' Generate random state for CSRF protection
        state = generateRandomState()
        m.top.state = state
        
        print "SUCCESS: PKCE challenge generated"
        print "DEBUG: Code verifier length: " + codeVerifier.Len().toStr()
        
        setSuccess("PKCE challenge generated successfully")
        
    catch error
        setError("Failed to generate PKCE challenge: " + error.message)
    end try
end sub

function generateCodeVerifier() as String
    ' Generate 128 character random string using PKCE allowed characters
    ' RFC 7636: A-Z, a-z, 0-9, -, ., _, ~
    chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
    verifier = ""
    
    ' Generate cryptographically secure random string
    for i = 1 to 128
        randomIndex = Rnd(chars.Len()) - 1
        verifier = verifier + Mid(chars, randomIndex + 1, 1)
    end for
    
    return verifier
end function

function createCodeChallenge(codeVerifier as String) as String
    ' Create SHA256 hash of code verifier
    digest = CreateObject("roEVPDigest")
    if digest = invalid then
        throw {message: "Failed to create digest object"}
    end if
    
    digest.Setup("sha256")
    
    ' Convert string to byte array for hashing
    ba = CreateObject("roByteArray")
    ba.FromAsciiString(codeVerifier)
    
    ' Generate hash
    hashBytes = digest.Process(ba)
    if hashBytes = invalid then
        throw {message: "Failed to generate hash"}
    end if
    
    ' Base64 URL encode the hash (PKCE requirement)
    return base64UrlEncode(hashBytes)
end function

function base64UrlEncode(bytes as Object) as String
    ' Create byte array from hash bytes
    ba = CreateObject("roByteArray")
    ba.Append(bytes)
    
    ' Standard base64 encode
    encodedString = ba.ToBase64String()
    
    ' Convert to URL-safe base64 (RFC 4648 Section 5)
    ' Replace + with -, / with _, remove padding =
    urlSafe = encodedString.Replace("+", "-")
    urlSafe = urlSafe.Replace("/", "_")
    urlSafe = urlSafe.Replace("=", "")
    
    return urlSafe
end function

function generateRandomState() as String
    ' Generate random state for CSRF protection
    chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    state = ""
    
    for i = 1 to 32
        randomIndex = Rnd(chars.Len()) - 1
        state = state + Mid(chars, randomIndex + 1, 1)
    end for
    
    return state
end function

' ========================================
' AUTHORIZATION URL BUILDING
' ========================================

sub buildAuthorizationUrl()
    print "INFO: Building authorization URL"
    m.top.progress = "Building authorization URL..."
    
    try
        clientId = m.top.clientId
        redirectUri = m.top.redirectUri
        scopes = m.top.scopes
        baseUrl = m.top.baseUrl
        codeChallenge = m.top.codeChallenge
        state = m.top.state
        
        ' Validate required parameters
        if clientId = "" or redirectUri = "" or baseUrl = "" then
            throw {message: "Missing required OAuth parameters"}
        end if
        
        if codeChallenge = "" then
            throw {message: "Code challenge not generated - call generatePKCE first"}
        end if
        
        ' Build authorization URL
        authUrl = baseUrl + "/oauth/authorize"
        authUrl = authUrl + "?response_type=code"
        authUrl = authUrl + "&client_id=" + urlEncode(clientId)
        authUrl = authUrl + "&redirect_uri=" + urlEncode(redirectUri)
        authUrl = authUrl + "&code_challenge=" + urlEncode(codeChallenge)
        authUrl = authUrl + "&code_challenge_method=S256"
        authUrl = authUrl + "&state=" + urlEncode(state)
        
        if scopes <> "" then
            authUrl = authUrl + "&scope=" + urlEncode(scopes)
        end if
        
        m.top.authUrl = authUrl
        
        print "SUCCESS: Authorization URL built"
        print "DEBUG: Auth URL length: " + authUrl.Len().toStr()
        
        setSuccess("Authorization URL ready")
        
    catch error
        setError("Failed to build authorization URL: " + error.message)
    end try
end sub

function urlEncode(str as String) as String
    ' Basic URL encoding for OAuth parameters
    encoded = str.Replace(" ", "%20")
    encoded = encoded.Replace(":", "%3A")
    encoded = encoded.Replace("/", "%2F")
    encoded = encoded.Replace("?", "%3F")
    encoded = encoded.Replace("#", "%23")
    encoded = encoded.Replace("[", "%5B")
    encoded = encoded.Replace("]", "%5D")
    encoded = encoded.Replace("@", "%40")
    encoded = encoded.Replace("!", "%21")
    encoded = encoded.Replace("$", "%24")
    encoded = encoded.Replace("&", "%26")
    encoded = encoded.Replace("'", "%27")
    encoded = encoded.Replace("(", "%28")
    encoded = encoded.Replace(")", "%29")
    encoded = encoded.Replace("*", "%2A")
    encoded = encoded.Replace("+", "%2B")
    encoded = encoded.Replace(",", "%2C")
    encoded = encoded.Replace(";", "%3B")
    encoded = encoded.Replace("=", "%3D")
    
    return encoded
end function

' ========================================
' AUTHORIZATION CODE EXCHANGE
' ========================================

sub exchangeAuthorizationCode()
    print "INFO: Exchanging authorization code for tokens"
    m.top.progress = "Exchanging authorization code..."
    
    try
        authCode = m.top.authCode
        codeVerifier = m.top.codeVerifier
        clientId = m.top.clientId
        redirectUri = m.top.redirectUri
        baseUrl = m.top.baseUrl
        
        ' Validate required parameters
        if authCode = "" then
            throw {message: "Authorization code is required"}
        end if
        
        if codeVerifier = "" then
            throw {message: "Code verifier is required"}
        end if
        
        if clientId = "" or redirectUri = "" or baseUrl = "" then
            throw {message: "Missing OAuth configuration"}
        end if
        
        ' Prepare token exchange request
        tokenUrl = baseUrl + "/oauth/token"
        
        ' Create form data for token exchange
        postData = "grant_type=authorization_code"
        postData = postData + "&client_id=" + clientId
        postData = postData + "&code=" + authCode
        postData = postData + "&redirect_uri=" + redirectUri
        postData = postData + "&code_verifier=" + codeVerifier
        
        ' Execute token exchange
        response = executeTokenRequest(tokenUrl, postData)
        
        if response.success then
            parseTokenResponse(response.data)
        else
            throw {message: response.error}
        end if
        
    catch error
        setError("Token exchange failed: " + error.message)
    end try
end sub

' ========================================
' TOKEN REFRESH
' ========================================

sub refreshAccessToken()
    print "INFO: Refreshing access token"
    m.top.progress = "Refreshing access token..."
    
    try
        refreshToken = m.top.refreshToken
        clientId = m.top.clientId
        baseUrl = m.top.baseUrl
        
        ' Validate required parameters
        if refreshToken = "" then
            throw {message: "No refresh token available"}
        end if
        
        if clientId = "" or baseUrl = "" then
            throw {message: "Missing OAuth configuration"}
        end if
        
        ' Prepare token refresh request
        tokenUrl = baseUrl + "/oauth/token"
        
        postData = "grant_type=refresh_token"
        postData = postData + "&client_id=" + clientId
        postData = postData + "&refresh_token=" + refreshToken
        
        ' Execute token refresh
        response = executeTokenRequest(tokenUrl, postData)
        
        if response.success then
            parseTokenResponse(response.data)
        else
            throw {message: response.error}
        end if
        
    catch error
        setError("Token refresh failed: " + error.message)
    end try
end sub

' ========================================
' TOKEN VALIDATION
' ========================================

sub validateAccessToken()
    print "INFO: Validating access token"
    m.top.progress = "Validating access token..."
    
    try
        accessToken = m.top.accessToken
        baseUrl = m.top.baseUrl
        
        if accessToken = "" then
            throw {message: "No access token to validate"}
        end if
        
        ' Check token expiration
        currentTime = CreateObject("roDateTime").AsSeconds()
        if m.top.tokenExpiration > 0 and currentTime >= m.top.tokenExpiration then
            throw {message: "Access token has expired"}
        end if
        
        ' Optionally validate with API endpoint
        apiUrl = baseUrl.Replace("/oauth", "/api/v1") + "/user"
        
        request = CreateObject("roUrlTransfer")
        request.SetUrl(apiUrl)
        request.SetCertificatesFile("common:/certs/ca-bundle.crt")
        request.InitClientCertificates()
        request.EnableEncodings(true)
        
        request.AddHeader("Authorization", "Bearer " + accessToken)
        request.AddHeader("Accept", "application/json")
        request.AddHeader("User-Agent", "Roku-KickApp/1.0")
        
        request.SetMessagePort(CreateObject("roMessagePort"))
        
        if request.AsyncGetToString() then
            msg = wait(10000, request.GetMessagePort())
            if type(msg) = "roUrlEvent" then
                responseCode = msg.GetResponseCode()
                if responseCode = 200 then
                    print "SUCCESS: Access token is valid"
                    setSuccess("Access token validated successfully")
                else
                    throw {message: "Token validation failed: HTTP " + responseCode.toStr()}
                end if
            else
                throw {message: "Token validation timeout"}
            end if
        else
            throw {message: "Failed to start token validation request"}
        end if
        
    catch error
        setError("Token validation failed: " + error.message)
    end try
end sub

' ========================================
' HTTP REQUEST HELPER
' ========================================

function executeTokenRequest(url as String, postData as String) as Object
    print "DEBUG: Executing token request to: " + url
    
    request = CreateObject("roUrlTransfer")
    request.SetUrl(url)
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.InitClientCertificates()
    request.EnableEncodings(true)
    
    ' Set headers for token request
    request.AddHeader("Content-Type", "application/x-www-form-urlencoded")
    request.AddHeader("Accept", "application/json")
    request.AddHeader("User-Agent", "Roku-KickApp/1.0")
    request.AddHeader("Cache-Control", "no-cache")
    
    request.SetMessagePort(CreateObject("roMessagePort"))
    
    if request.AsyncPostFromString(postData) then
        msg = wait(15000, request.GetMessagePort()) ' 15 second timeout
        if type(msg) = "roUrlEvent" then
            responseCode = msg.GetResponseCode()
            responseString = msg.GetString()
            
            print "DEBUG: Token request response code: " + responseCode.toStr()
            
            if responseCode = 200 then
                return {success: true, data: responseString}
            else
                errorMsg = "HTTP " + responseCode.toStr()
                if responseString <> "" then
                    ' Try to parse error from response
                    json = ParseJson(responseString)
                    if json <> invalid and json.error <> invalid then
                        errorMsg = errorMsg + ": " + json.error
                        if json.error_description <> invalid then
                            errorMsg = errorMsg + " - " + json.error_description
                        end if
                    end if
                end if
                return {success: false, error: errorMsg}
            end if
        else
            return {success: false, error: "Request timeout"}
        end if
    else
        return {success: false, error: "Failed to start HTTP request"}
    end if
end function

' ========================================
' TOKEN RESPONSE PARSING
' ========================================

sub parseTokenResponse(responseString as String)
    print "DEBUG: Parsing token response"
    
    json = ParseJson(responseString)
    if json = invalid then
        throw {message: "Invalid JSON response from token endpoint"}
    end if
    
    ' Extract access token (required)
    if json.access_token = invalid or json.access_token = "" then
        errorMsg = "No access token in response"
        if json.error <> invalid then
            errorMsg = errorMsg + ": " + json.error
            if json.error_description <> invalid then
                errorMsg = errorMsg + " - " + json.error_description
            end if
        end if
        throw {message: errorMsg}
    end if
    
    ' Set access token
    m.top.accessToken = json.access_token
    
    ' Extract refresh token (optional)
    if json.refresh_token <> invalid and json.refresh_token <> "" then
        m.top.refreshToken = json.refresh_token
    end if
    
    ' Calculate token expiration
    if json.expires_in <> invalid then
        currentTime = CreateObject("roDateTime").AsSeconds()
        expirationTime = currentTime + json.expires_in - 300 ' 5 minute buffer
        m.top.tokenExpiration = expirationTime
        
        print "DEBUG: Token expires in " + json.expires_in.toStr() + " seconds"
    end if
    
    print "SUCCESS: OAuth tokens parsed successfully"
    setSuccess("OAuth tokens obtained successfully")
end sub

' ========================================
' UTILITY FUNCTIONS
' ========================================

sub setSuccess(message as String)
    print "SUCCESS: " + message
    m.top.progress = message
    m.top.isSuccess = true
    m.top.isComplete = true
    m.top.error = ""
end sub

sub setError(errorMessage as String)
    print "ERROR: " + errorMessage
    m.top.progress = "Error: " + errorMessage
    m.top.error = errorMessage
    m.top.isSuccess = false
    m.top.isComplete = true
end sub

function getCurrentTimestamp() as String
    dt = CreateObject("roDateTime")
    return dt.AsDateStringNoParam() + " " + dt.AsTimeStringNoParam()
end function

' ========================================
' CLEANUP
' ========================================

sub cleanup()
    print "INFO: OAuthHelper cleanup"
    
    ' Clear sensitive data
    m.top.codeVerifier = ""
    m.top.authCode = ""
    
    ' Note: Don't clear tokens here as they may be needed
    ' Token clearing should be handled by the parent component
end sub