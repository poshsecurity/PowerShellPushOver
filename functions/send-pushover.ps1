Add-Type -TypeDefinition @"
	public enum PushoverPriorityLevel
	{
		Low,
		Normal,
		High,
		Emergency
	}
"@

function Send-PushOver 
{
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

.PARAMETER Timestamp

.PARAMETER Sound

.PARAMETER retry

.PARAMETER expire

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
String containing status code returned from PushOver API server OR...{}{}{}{}{}

.NOTES
NAME: Send-PushOver
AUTHOR: kieran@thekgb.su
LASTEDIT: 2012-10-14 9:15:00
KEYWORDS:

.LINK
http://aperturescience.su/

.LINK
http://pushover.net/
#>
[CMDLetBinding()]
param
(
  [Parameter(mandatory=$true)] [String] $APIToken,
  [Parameter(mandatory=$true)] [String] $User,
  [Parameter(mandatory=$true)] [String] $Message,
  [String] $MessageTitle,
  [String] $DeviceID,
  [String] $MessageURL,
  [String] $MessageURLTitle,
  [PushoverPriorityLevel] $priority,
  [string] $timestamp,
  [string] $sound,
  [int] $ConfirmationRetry=60,
  [int] $ConfirmationExpire=3600,
  [string] $ConfirmationCallback,
  [System.Net.IWebProxy] $WebProxy,
  [String] $PushOverAPIURL = 'https://api.pushover.net/1/messages.json'
)

#check if we can access the upload values method
if ((Get-Command Send-WebPage -ErrorAction silentlycontinue) -eq $null) 
{
	throw "Could not find the function Send-WebPage"
}

#collection containing the parameters we will be sending
$reqparams = new-object System.Collections.Specialized.NameValueCollection

#add the mandatory parameters (token, user identifier and the message)
$reqparams.Add("token",$APIToken)
$reqparams.Add("user",$user)

if ($Message.length -gt 512)
{
	throw "Message length is greater than 512"
}

$reqparams.Add("message",$message)

#add the optional parameters if they have been specified (We will not process messageurltitle if no message url specified)
if ($MessageTitle) 
{
	$reqparams.Add("title",$MessageTitle)
}
if ($DeviceID) 
{
	$reqparams.Add("device",$DeviceID)
}
if ($MessageURL)
{
	if ($MessageURL.length -gt 500)
	{
		throw "Supplementary Message URL is longer than 500"
	}
	
	$reqparams.Add("url",$MessageURL)
	if ($MessageURLTitle) 
	{
		if ($MessageURLTitle.length -gt 50)
		{
			throw "Supplementary Message URL Title is longer than 50"
		}
		$reqparams.Add("url_title",$MessageURLTitle)
	}
}
if ($priority)
{
	if (($priority.value__ -1) -eq 2)
	{
		Write-Verbose "Retry $Confirmationretry, Expire $Confirmationexpire"
		if ($ConfirmationRetry -lt 30)
		{
			throw "retry period is less than 30 seconds, must be longer than 30 seconds"
		}
		
		if ($Confirmationexpire -gt 86400)
		{
			throw "Expiry period is larger than 86400 seconds (24 hours), must be less than 24 hours"
		}
		$reqparams.Add("retry", $ConfirmationRetry)
		$reqparams.Add("expire", $Confirmationexpire)
		if ($ConfirmationCallback)
		{
			$reqparams.Add("callback", $ConfirmationCallback)
		}
	}
	
	$reqparams.Add("priority",($priority.value__ -1))
}

if ($timestamp)
{
	$reqparams.Add("timestamp", $timestamp)
}

if ($sound)
{
	if (test-pushoversound -APIToken $APIToken -sound $sound -webproxy $WebProxy)
	{
		Write-Verbose "Will be playing the following sound on the device: $($sounds.$sound)"
		$reqparams.Add("sound", $sound)
	}
	else
	{
		throw "Invalid sound has been specified, confirm sound is valid by checking it against the get-PushoverSounds cmdlet"
	}
}

#pushover require a specific content-type header
$headers = New-Object System.net.webheadercollection
$headers.Add("Content-Type", "application/x-www-form-urlencoded")

#send the request to the pushover server, capture the response, throw any error
try 
{
	Write-Verbose "Sending message: $message"
	$response = Send-WebPage -URL $PushOverAPIURL -Values $reqparams -Headers $headers -WebProxy $WebProxy
} 
catch 
{
	throw $_
}

#write the response in full for vebose output
Write-Verbose " Writing response:"
Write-Verbose "--------------------"
Write-Verbose "$response"
Write-Verbose "--------------------"

#convert response to xml
$jsonresponse = ConvertFrom-Json $response

if ($jsonresponse.receipt -eq $null)
{
	#return response code form PushOver
	return $jsonresponse.status
}
else
{
	return $jsonresponse.receipt
}

}
