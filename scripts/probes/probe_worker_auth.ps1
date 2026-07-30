# FILE_18 Task B — the Worker's auth gate, driven against a LOCAL `wrangler dev`
# instance (local mode needs no Cloudflare login). The 401 rows are provable
# here because they are decided before the Worker ever touches its service
# account; the customer-403 row needs the deployed Worker with its
# FIREBASE_SERVICE_ACCOUNT secret, so whatever it returns locally is recorded
# as-is rather than scored.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$key = 'AIzaSyCUK3v6U6ExiwyfzERYU_XFUDFspxUPBfI'
$w = 'http://127.0.0.1:8787'

function Call($method, $url, $headers, $body) {
  $p = @{ Method = $method; Uri = $url; UseBasicParsing = $true; ContentType = 'application/json' }
  if ($headers) { $p['Headers'] = $headers }
  if ($body) { $p['Body'] = $body }
  try { $r = Invoke-WebRequest @p; return @{ code = [int]$r.StatusCode; body = $r.Content } }
  catch {
    $resp = $_.Exception.Response
    if ($resp) { $s = New-Object IO.StreamReader($resp.GetResponseStream()); return @{ code = [int]$resp.StatusCode; body = $s.ReadToEnd() } }
    return @{ code = -1; body = $_.Exception.Message }
  }
}

$signUp = Call POST "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$key" $null `
  (@{ email = "probe-worker-$(Get-Random)@dukkan.dev"; password = 'probe12345'; returnSecureToken = $true } | ConvertTo-Json)
$acct = $signUp.body | ConvertFrom-Json
$tok = $acct.idToken

$script:rows = New-Object System.Collections.ArrayList
function Row($name, $method, $path, $headers, $expect) {
  $r = Call $method "$w$path" $headers '{}'
  $verdict = if ($expect -eq 'n/a') { 'INFO' } elseif ($r.code -eq $expect) { 'PASS' } else { 'FAIL' }
  $short = if ($r.body -and $r.body.Length -gt 60) { $r.body.Substring(0, 60) } else { $r.body }
  [void]$script:rows.Add([pscustomobject]@{ Row = $name; Expect = $expect; HTTP = $r.code; Verdict = $verdict; Body = $short })
}

Row '/admin/ping  no Authorization header'    POST '/admin/ping' $null 401
Row '/admin/ping  malformed bearer'           POST '/admin/ping' @{ Authorization = 'Bearer not-a-jwt' } 401
Row '/admin/ping  bearer with junk signature' POST '/admin/ping' @{ Authorization = 'Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6Inh4In0.eyJzdWIiOiJhIn0.zzz' } 401
Row '/admin/users/set-disabled  no token'     POST '/admin/users/set-disabled' $null 401
Row '/admin/impersonate  no token'            POST '/admin/impersonate' $null 401
Row '/admin/admins/set  no token'             POST '/admin/admins/set' $null 401
Row '/upload  no token'                       POST '/upload' $null 401
Row '/notify  no token'                       POST '/notify' $null 401
Row '/admin/ping  real CUSTOMER id token'     POST '/admin/ping' @{ Authorization = "Bearer $tok" } 'n/a'
Row 'unknown route, no token (auth runs first)' POST '/does-not-exist' $null 401
Row 'unknown route, real token'                POST '/does-not-exist' @{ Authorization = "Bearer $tok" } 'n/a'

$rows | Format-Table -AutoSize -Wrap
$fails = ($rows | Where-Object { $_.Verdict -eq 'FAIL' }).Count
Write-Output "SCORED $(($rows | Where-Object { $_.Verdict -ne 'INFO' }).Count) rows, FAILS = $fails"

Call POST "https://identitytoolkit.googleapis.com/v1/accounts:delete?key=$key" $null (@{ idToken = $tok } | ConvertTo-Json) | Out-Null
Write-Output "probe Auth account deleted (it never wrote any Firestore doc)"
