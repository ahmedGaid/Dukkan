# FILE_18 Task B — customer-row deny matrix, run LIVE against the deployed
# firestore.rules. Firestore's REST API enforces the same security rules as the
# SDK when called with a Firebase ID token, so this needs no seed, no Worker and
# no device. Lives outside the repo on purpose (plan says "no new files").

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$key = 'AIzaSyCUK3v6U6ExiwyfzERYU_XFUDFspxUPBfI'
$project = 'dukkan-93042'
$base = "https://firestore.googleapis.com/v1/projects/$project/databases/(default)/documents"
$email = 'probe-customer@dukkan.dev'
$password = 'probe12345'

function Call-Json($method, $url, $bodyObj, $token) {
  $headers = @{}
  if ($token) { $headers['Authorization'] = "Bearer $token" }
  $params = @{ Method = $method; Uri = $url; Headers = $headers; ContentType = 'application/json'; UseBasicParsing = $true }
  if ($bodyObj) { $params['Body'] = ($bodyObj | ConvertTo-Json -Depth 10 -Compress) }
  try {
    $r = Invoke-WebRequest @params
    return @{ code = [int]$r.StatusCode; body = $r.Content }
  } catch {
    $resp = $_.Exception.Response
    if ($resp) {
      $code = [int]$resp.StatusCode
      $reader = New-Object IO.StreamReader($resp.GetResponseStream())
      return @{ code = $code; body = $reader.ReadToEnd() }
    }
    return @{ code = -1; body = $_.Exception.Message }
  }
}

# --- 1. get a real customer ID token -----------------------------------------
$signUp = Call-Json POST "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$key" `
  @{ email = $email; password = $password; returnSecureToken = $true } $null
if ($signUp.code -ne 200) {
  $signUp = Call-Json POST "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$key" `
    @{ email = $email; password = $password; returnSecureToken = $true } $null
}
if ($signUp.code -ne 200) { Write-Output "AUTH FAILED: $($signUp.code) $($signUp.body)"; exit 1 }
$auth = $signUp.body | ConvertFrom-Json
$tok = $auth.idToken
$uid = $auth.localId
Write-Output "customer uid = $uid"
Write-Output ""

$str = { param($v) @{ stringValue = $v } }
$results = @()
function Probe($name, $method, $url, $body, $expect) {
  $r = Call-Json $method $url $body $script:tok
  $ok = if ($expect -eq 'denied') { $r.code -eq 403 } else { $r.code -eq 200 }
  $script:results += [pscustomobject]@{
    Row = $name; Expected = $expect; HTTP = $r.code
    Verdict = if ($ok) { 'PASS' } else { 'FAIL' }
  }
}

$doc = @{ fields = @{ probe = @{ stringValue = 'x' } } }

# sanity: a customer CAN create their own /users doc (rule: isSelf + role/name/email)
Probe 'own /users doc create (sanity, must be ALLOWED)' PATCH "$base/users/$uid" `
  @{ fields = @{ role = @{ stringValue = 'customer' }; name = @{ stringValue = 'Probe' };
                 email = @{ stringValue = $email }; status = @{ stringValue = 'active' };
                 fake = @{ booleanValue = $true } } } 'allowed'

# the deny matrix (FILE_18 Task B, customer row)
Probe 'write /admins/{self}'            POST  "$base/admins?documentId=$uid"        $doc 'denied'
Probe 'write /roles/probe'              POST  "$base/roles?documentId=probe"        $doc 'denied'
Probe 'write /auditLogs/probe'          POST  "$base/auditLogs?documentId=probe"    $doc 'denied'
Probe 'update /config/platform'         PATCH "$base/config/platform?updateMask.fieldPaths=commissionPercent" `
  @{ fields = @{ commissionPercent = @{ integerValue = '0' } } } 'denied'
Probe 'write /categories/probe'         POST  "$base/categories?documentId=probe"   $doc 'denied'
Probe 'write /areas/probe'              POST  "$base/areas?documentId=probe"        $doc 'denied'
Probe 'write /coupons/PROBE (create)'   POST  "$base/coupons?documentId=PROBE"      $doc 'denied'
Probe 'write /banners/probe'            POST  "$base/banners?documentId=probe"      $doc 'denied'
Probe 'write /notificationTemplates'    POST  "$base/notificationTemplates?documentId=probe" $doc 'denied'
Probe 'write another user /users doc'   PATCH "$base/users/someone-elses-uid-000?updateMask.fieldPaths=name" `
  @{ fields = @{ name = @{ stringValue = 'hacked' } } } 'denied'
Probe 'create /drivers/{self} unsuspended' POST "$base/drivers?documentId=$uid" `
  @{ fields = @{ isSuspended = @{ booleanValue = $false }; activeOrdersCount = @{ integerValue = '0' } } } 'denied'
Probe 'self /users role escalation -> owner' PATCH "$base/users/$uid`?updateMask.fieldPaths=role" `
  @{ fields = @{ role = @{ stringValue = 'owner' } } } 'denied'
Probe 'read /auditLogs (list)'          GET   "$base/auditLogs"                     $null 'denied'
Probe 'read /orders (list, cross-user)' GET   "$base/orders"                        $null 'denied'
Probe 'read /admins/{someone else}'     GET   "$base/admins/someone-elses-uid-000"  $null 'denied'
Probe 'read /roles (list)'              GET   "$base/roles"                         $null 'denied'

# the KNOWN residual looseness — expected ALLOWED, documents the finding live
Probe 'self /users status mirror write (known looseness)' PATCH "$base/users/$uid`?updateMask.fieldPaths=status" `
  @{ fields = @{ status = @{ stringValue = 'banned' } } } 'allowed'

$results | Format-Table -AutoSize
$fails = ($results | Where-Object { $_.Verdict -eq 'FAIL' }).Count
Write-Output ""
Write-Output "TOTAL $($results.Count) rows, FAILS = $fails"
