# Enum type defining PushOver priority levels, will be converted to apprpriate codes prior to transmission.
Add-Type -TypeDefinition @"
	public enum PushoverPriorityLevel
	{
		Low,
		Normal,
		High,
		Emergency
	}
"@

function Send-PushOver {
<#
.SYNOPSIS
Sends a push notification alert to a specific user using PushOver.net

.DESCRIPTION
Use this function to send push notification alerts using the PushOver.net framework, see their page for more details.

.PARAMETER APIToken
your application's API token

.PARAMETER User
the identifier of your user (or you), viewable when logged into the dashboard

.PARAMETER Message
your message

.PARAMETER MessageTitle
[Optional] your message's title, otherwise uses your app's name

.PARAMETER DeviceID
[Optional] your user's device identifier to send the message directly to that device, rather than all of the user's devices

.PARAMETER MessageURL
[Optional] a supplementary URL to show with your message

.PARAMETER MessageURLTitle
[Optional] a title for your supplementary URL (not used unless MessageURL specified)

.PARAMETER Priority
[Optional]

.PARAMETER Timestamp
[Optional]

.PARAMETER Sound
[Optional]

.PARAMETER ConfirmationRetry
[Optional]

.PARAMETER ConfirmationExpire
[Optional]

.PARAMETER ConfirmationCallback
[Optional] 

.PARAMETER WebProxy
[Optional] 

.PARAMETER PushOverAPIURL
[Optional] Overwrite stored URL for API

.INPUTS
Nothing can be piped directly into this function

.EXAMPLE
Send-PushOver -APIToken 'KzGDORePK8gMaC0QOYAMyEEuzJnyUi' -User 'pQiRzpo4DXghDmr9QzzfQu27cmVRsG' -Message "Test Alert"
Sends message "test alert" to user with token specified

.EXAMPLE
Send-PushOver -APIToken 'KzGDORePK8gMaC0QOYAMyEEuzJnyUi' -User 'pQiRzpo4DXghDmr9QzzfQu27cmVRsG' -Message "Test Alert" -DeviceID 'droid2'

.OUTPUTS
String containing status code returned from PushOver API server or recipt ID

.NOTES
NAME: Send-PushOver
AUTHOR: kieran@thekgb.su
LASTEDIT: 2014/03/10
KEYWORDS:

.LINK
http://aperturescience.su/

.LINK
http://pushover.net/

.LINK
https://github.com/kjacobsen/PowerShellPushOver

#>
[CMDLetBinding()]
param (
  [Parameter(mandatory=$true)] [String] $APIToken,
  [Parameter(mandatory=$true)] [Alias("Group")] [String] $User,
  [Parameter(mandatory=$true)] [String] $Message,
  [String] $MessageTitle,
  [String] $DeviceID,
  [String] $MessageURL,
  [String] $MessageURLTitle,
  [PushoverPriorityLevel] $priority,
  [string] $timestamp,
  [string] $sound,
  [int] $ConfirmationRetry=60,
  [int] $Confirmationexpire=3600,
  [string] $ConfirmationCallback,
  [System.Net.IWebProxy] $WebProxy,
  [String] $PushOverAPIURL = 'https://api.pushover.net/1/messages.json'
)

#check if we can access the upload values method
if ((Get-Command Send-WebPage -ErrorAction silentlycontinue) -eq $null) {
	throw "Could not find the function Send-WebPage"
}

#collection containing the parameters we will be sending
$reqparams = new-object System.Collections.Specialized.NameValueCollection

#check API token has valid length, then add it to request parameters
if ($APIToken.Length -eq 30) {
	$reqparams.Add("token",$APIToken)
} else {
	throw "ApiToken length is not 30 characters long"
}

#check user/group has valid length, then add it to request parameters
if ($user.length -eq 30) {
	$reqparams.Add("user",$user)
} else {
	throw "User length is not 30 characters long"
}

#check message has valid length, then add it to request parameters
if ($Message.length -le 512) {
	$reqparams.Add("message",$message)
} else {
	throw "Message length is greater than 512"
}

#if we have specified a message title (length greater than 0) and its not too long (less than 100 chars), then add it to request parameters
if ($MessageTitle.length -gt 0) {
	if ($MessageTitle.length -le 100) {
		$reqparams.Add("title",$MessageTitle)
	} else {
		throw "Message Title is longer than 100"
	}
}

#if we have specified a device id (length greater than 0) and its not too long (less than 25 chars), then add it to request parameters
if ($DeviceID.length -gt 0) {
	if ($DeviceID.length -le 25) {
		$reqparams.Add("device",$DeviceID)
	} else {
		throw "DeviceID length is greater than 25"
	}
}

# if we have specified a message url (length greater than 0) and its not too long (512 characters max), then we will add that.
# 	if a title has been specified of valid length (less than 100 chars), add it too.
if ($MessageURL.length -gt 0) {
	if ($MessageURL.length -le 512) {
		$reqparams.Add("url",$MessageURL)
	} else {
		throw "Supplementary Message URL is longer than 500"
	}
	
	if ($MessageURLTitle.length -gt 0) {
		if ($MessageURLTitle.length -le 100) {
			$reqparams.Add("url_title",$MessageURLTitle)
		} else {
			throw "Supplementary Message URL Title is longer than 50"
		}
	}
}

<#
	priority field, if specified, can be complicated.
	
	Normal (0) will be the priority level if none is specified. You can specify Normal, Low, High and Emergency.
	
	If emergency, then we also need to specify a confirmation retry and Message expiry period (defaults set in paramerters). We can also specify a URL for the call backs to be sent to.
#>
if ($priority.length -gt 0) {
	if (($priority.value__ -1) -eq 2) {
		Write-Verbose "Retry $Confirmationretry, Expire $Confirmationexpire"
		if ($ConfirmationRetry -lt 30) {
			throw "retry period is less than 30 seconds, must be longer than 30 seconds"
		}
		if ($Confirmationexpire -gt 86400)	{
			throw "Expiry period is larger than 86400 seconds (24 hours), must be less than 24 hours"
		}
		$reqparams.Add("retry", $ConfirmationRetry)
		$reqparams.Add("expire", $Confirmationexpire)
		if ($ConfirmationCallback.length -gt 0)	{
			$reqparams.Add("callback", $ConfirmationCallback)
		}
	}
	$reqparams.Add("priority",($priority.value__ -1))
}

#optional timestamp
if ($timestamp.length -gt 0) {
	$reqparams.Add("timestamp", $timestamp)
}

#optional sound. We will test to confirm a valid sound is specified.
if ($sound.length -gt 0) {
	if (test-pushoversound -APIToken $APIToken -sound $sound -webproxy $WebProxy) {
		$reqparams.Add("sound", $sound)
	} else {
		throw "Invalid sound has been specified, confirm sound is valid by checking it against the get-PushoverSounds cmdlet"
	}
}

#pushover require a specific content-type header
$headers = New-Object System.net.webheadercollection
$headers.Add("Content-Type", "application/x-www-form-urlencoded")

#send the request to the pushover server, capture the response, throw any error
try {
	Write-Verbose "Sending message: $message"
	$response = Send-WebPage -URL $PushOverAPIURL -Values $reqparams -Headers $headers -WebProxy $WebProxy
} catch {
	$senderror = $error[0]
	throw $senderror
}

#write the response in full for vebose output
Write-Verbose " Writing response:"
Write-Verbose "--------------------"
Write-Verbose "$response"
Write-Verbose "--------------------"

#convert response to xml
$jsonresponse = ConvertFrom-Json $response

#if the response contains a receipt number, return that, otherwise just return the response status code
if ($jsonresponse.receipt -eq $null) {
	return $jsonresponse.status
} else {
	return $jsonresponse.receipt
}

}
