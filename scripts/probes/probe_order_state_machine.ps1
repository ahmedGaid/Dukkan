# FILE_18 Task B/C — order state machine + cross-role denials, LIVE against the
# deployed firestore.rules. Highest-risk rule surface in the app and nothing had
# ever driven it end to end. Three self-signed-up accounts (owner, courier,
# customer) + one extra customer for the cross-user read. No seed, no Worker, no
# device needed. Cleans up after itself as far as the rules permit (orders can
# never be client-deleted; the probe shop is left inactive and clearly labelled).

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$key = 'AIzaSyCUK3v6U6ExiwyfzERYU_XFUDFspxUPBfI'
$base = 'https://firestore.googleapis.com/v1/projects/dukkan-93042/databases/(default)/documents'
# EVERY doc id is per-run, and that is not cosmetic: the accounts are new each
# run, so a reused shop id belongs to the previous run's owner and the whole
# owner path 403s; a reused order can only move forward once; and a reused shop's
# ratingCount no longer matches the +1 the rating rule demands. Every doc this
# script creates carries `fake: true`, which is what the console's own devtools
# cleanup (FC15, /admin/devtools/fake-cleanup) deletes — so a founder can sweep
# every probe artefact in one click.
$run = -join (1..6 | ForEach-Object { '{0:x}' -f (Get-Random -Maximum 16) })
$shopId = "probe-shop-$run"
$o1 = "probe-order-$run-1"
$o2 = "probe-order-$run-2"

function Call($method, $url, $bodyObj, $token) {
  $headers = @{}
  if ($token) { $headers['Authorization'] = "Bearer $token" }
  $p = @{ Method = $method; Uri = $url; Headers = $headers; ContentType = 'application/json'; UseBasicParsing = $true }
  if ($bodyObj) { $p['Body'] = ($bodyObj | ConvertTo-Json -Depth 10 -Compress) }
  try { $r = Invoke-WebRequest @p; return @{ code = [int]$r.StatusCode; body = $r.Content } }
  catch {
    $resp = $_.Exception.Response
    if ($resp) { $s = New-Object IO.StreamReader($resp.GetResponseStream()); return @{ code = [int]$resp.StatusCode; body = $s.ReadToEnd() } }
    return @{ code = -1; body = $_.Exception.Message }
  }
}

function Account($email) {
  $b = @{ email = $email; password = 'probe12345'; returnSecureToken = $true }
  $r = Call POST "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$key" $b $null
  if ($r.code -ne 200) { $r = Call POST "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$key" $b $null }
  if ($r.code -ne 200) { throw "auth failed for $email : $($r.body)" }
  $j = $r.body | ConvertFrom-Json
  return @{ tok = $j.idToken; uid = $j.localId; email = $email }
}

$results = @()
function Row($name, $method, $url, $body, $token, $expect) {
  $r = Call $method $url $body $token
  $ok = if ($expect -eq 'denied') { $r.code -eq 403 } else { $r.code -eq 200 }
  $script:results += [pscustomobject]@{ Row = $name; Expected = $expect; HTTP = $r.code; Verdict = if ($ok) { 'PASS' } else { 'FAIL' } }
  if (-not $ok) { Write-Output "  ^ unexpected: $($r.body)" }
}
function S($v) { @{ stringValue = $v } }
function I($v) { @{ integerValue = "$v" } }
function B($v) { @{ booleanValue = $v } }

$owner = Account 'probe-owner@dukkan.dev'
$courier = Account 'probe-courier@dukkan.dev'
$cust = Account 'probe-customer-a@dukkan.dev'
$cust2 = Account 'probe-customer-b@dukkan.dev'
Write-Output "owner=$($owner.uid) courier=$($courier.uid) customer=$($cust.uid)"
Write-Output ""

# --- setup (all must be ALLOWED under strict rules) --------------------------
Row 'owner: own /users doc' PATCH "$base/users/$($owner.uid)" @{ fields = @{ role = S 'owner'; name = S 'Probe Owner'; email = S $owner.email } } $owner.tok 'allowed'
Row 'owner: create own shop' PATCH "$base/shops/$shopId" @{ fields = @{ ownerUid = S $owner.uid; name = S 'TEST - rules probe (safe to delete)'; isActive = B $false; status = S 'suspended'; fake = B $true } } $owner.tok 'allowed'
Row 'courier: own /users doc' PATCH "$base/users/$($courier.uid)" @{ fields = @{ role = S 'courier'; name = S 'Probe Courier'; email = S $courier.email } } $courier.tok 'allowed'
Row 'courier: self /drivers doc (suspended)' POST "$base/drivers?documentId=$($courier.uid)" @{ fields = @{ isSuspended = B $true; activeOrdersCount = I 0; name = S 'Probe Courier' } } $courier.tok 'allowed'
Row 'customer: own /users doc' PATCH "$base/users/$($cust.uid)" @{ fields = @{ role = S 'customer'; name = S 'Probe Customer'; email = S $cust.email } } $cust.tok 'allowed'
Row 'customer2: own /users doc' PATCH "$base/users/$($cust2.uid)" @{ fields = @{ role = S 'customer'; name = S 'Probe Customer B'; email = S $cust2.email } } $cust2.tok 'allowed'
$order = @{ fields = @{ customerUid = S $cust.uid; shopId = S $shopId; status = S 'pending'; totalMinor = I 5000; fake = B $true } }
Row 'customer: place order 1' PATCH "$base/orders/$o1" $order $cust.tok 'allowed'
Row 'customer: place order 2' PATCH "$base/orders/$o2" $order $cust.tok 'allowed'

# --- shop / rating rules ------------------------------------------------------
Row 'customer edits someone else shop name' PATCH "$base/shops/$shopId`?updateMask.fieldPaths=name" @{ fields = @{ name = S 'hijacked' } } $cust.tok 'denied'
Row 'customer steals shop ownerUid' PATCH "$base/shops/$shopId`?updateMask.fieldPaths=ownerUid" @{ fields = @{ ownerUid = S $cust.uid } } $cust.tok 'denied'
Row 'customer rating bump of 6 stars' PATCH "$base/shops/$shopId`?updateMask.fieldPaths=ratingSum&updateMask.fieldPaths=ratingCount" @{ fields = @{ ratingSum = I 6; ratingCount = I 1 } } $cust.tok 'denied'
Row 'customer rating bump of 3 stars (by design)' PATCH "$base/shops/$shopId`?updateMask.fieldPaths=ratingSum&updateMask.fieldPaths=ratingCount" @{ fields = @{ ratingSum = I 3; ratingCount = I 1 } } $cust.tok 'allowed'

# --- order state machine ------------------------------------------------------
Row 'customer jumps own order pending->delivered' PATCH "$base/orders/$o1`?updateMask.fieldPaths=status" @{ fields = @{ status = S 'delivered' } } $cust.tok 'denied'
Row 'customer cancels own pending order (legal)' PATCH "$base/orders/$o2`?updateMask.fieldPaths=status" @{ fields = @{ status = S 'cancelled' } } $cust.tok 'allowed'
Row 'unassigned courier advances order' PATCH "$base/orders/$o1`?updateMask.fieldPaths=status" @{ fields = @{ status = S 'preparing' } } $courier.tok 'denied'
Row 'owner: pending->accepted (legal)' PATCH "$base/orders/$o1`?updateMask.fieldPaths=status" @{ fields = @{ status = S 'accepted' } } $owner.tok 'allowed'
Row 'owner: accepted->delivered (illegal jump)' PATCH "$base/orders/$o1`?updateMask.fieldPaths=status" @{ fields = @{ status = S 'delivered' } } $owner.tok 'denied'
Row 'owner: assign driver while accepted (legal)' PATCH "$base/orders/$o1`?updateMask.fieldPaths=driverUid&updateMask.fieldPaths=driverName&updateMask.fieldPaths=driverPhone" @{ fields = @{ driverUid = S $courier.uid; driverName = S 'Probe Courier'; driverPhone = S '01000000000' } } $owner.tok 'allowed'
Row 'assigned driver: accepted->outForDelivery (illegal)' PATCH "$base/orders/$o1`?updateMask.fieldPaths=status" @{ fields = @{ status = S 'outForDelivery' } } $courier.tok 'denied'
Row 'owner: accepted->preparing (legal)' PATCH "$base/orders/$o1`?updateMask.fieldPaths=status" @{ fields = @{ status = S 'preparing' } } $owner.tok 'allowed'
Row 'assigned driver: preparing->outForDelivery (legal)' PATCH "$base/orders/$o1`?updateMask.fieldPaths=status" @{ fields = @{ status = S 'outForDelivery' } } $courier.tok 'allowed'
Row 'assigned driver: deliver + commission flip (legal)' PATCH "$base/orders/$o1`?updateMask.fieldPaths=status&updateMask.fieldPaths=commissionPayable" @{ fields = @{ status = S 'delivered'; commissionPayable = B $true } } $courier.tok 'allowed'
Row 'customer rates delivered order once (legal)' PATCH "$base/orders/$o1`?updateMask.fieldPaths=rating" @{ fields = @{ rating = I 5 } } $cust.tok 'allowed'
Row 'customer rates the same order twice' PATCH "$base/orders/$o1`?updateMask.fieldPaths=rating" @{ fields = @{ rating = I 1 } } $cust.tok 'denied'
Row 'customer deletes own order' DELETE "$base/orders/$o1" $null $cust.tok 'denied'
Row 'other customer reads this order' GET "$base/orders/$o1" $null $cust2.tok 'denied'

# --- driver self-service limits ----------------------------------------------
Row 'courier flips own isOnline (legal)' PATCH "$base/drivers/$($courier.uid)`?updateMask.fieldPaths=isOnline" @{ fields = @{ isOnline = B $true } } $courier.tok 'allowed'
Row 'courier un-suspends self' PATCH "$base/drivers/$($courier.uid)`?updateMask.fieldPaths=isSuspended" @{ fields = @{ isSuspended = B $false } } $courier.tok 'denied'
Row 'courier raises own maxActiveOrders' PATCH "$base/drivers/$($courier.uid)`?updateMask.fieldPaths=maxActiveOrders" @{ fields = @{ maxActiveOrders = I 99 } } $courier.tok 'denied'
Row 'customer edits the courier driver doc' PATCH "$base/drivers/$($courier.uid)`?updateMask.fieldPaths=isSuspended" @{ fields = @{ isSuspended = B $false } } $cust.tok 'denied'

$results | Format-Table -AutoSize
$fails = ($results | Where-Object { $_.Verdict -eq 'FAIL' }).Count
Write-Output ""
Write-Output "TOTAL $($results.Count) rows, FAILS = $fails"

# --- cleanup (as far as rules allow) -----------------------------------------
Call PATCH "$base/drivers/$($courier.uid)?updateMask.fieldPaths=isOnline" @{ fields = @{ isOnline = B $false } } $courier.tok | Out-Null
foreach ($a in @($owner, $courier, $cust, $cust2)) {
  Call PATCH "$base/users/$($a.uid)?updateMask.fieldPaths=deleted&updateMask.fieldPaths=name&updateMask.fieldPaths=fake" `
    @{ fields = @{ deleted = B $true; name = S 'security probe (ignore)'; fake = B $true } } $a.tok | Out-Null
  Call POST "https://identitytoolkit.googleapis.com/v1/accounts:delete?key=$key" @{ idToken = $a.tok } $null | Out-Null
}
Write-Output "cleanup: probe /users docs soft-deleted, Auth accounts removed, courier offline."
Write-Output "LEFT BEHIND (client rules forbid deleting these - remove from Firebase console):"
Write-Output "  /shops/$shopId (inactive, labelled TEST), /orders/$o1, /orders/$o2, /drivers/$($courier.uid)"
