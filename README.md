# PowerShellPushOver
This module provides a simplified interface for PowerShell scripts and processes to send push notifications using PushOver to Android and iOS devices.

***
## Available CMDLets
###Send-Pushover
####SYNOPSIS
Sends a push notification alert to a specific user using PushOver.net
####DESCRIPTION
Use this function to send push notification alerts using the PushOver.net API.

###Test-Pushover
####SYNOPSIS
Tests if the API, User, Group or Device Tokens are Valid
####DESCRIPTION
As an optional step in collecting user keys for users of your application, you may verify those keys to ensure that a user has copied them properly, that the account is valid, and that there is at least one active device on the account. User and group identifiers may be verified as can Device Identifiers.

###Get-PushoverReceipt
####SYNOPSIS
Get's Pushover Receipt information in regards to an Emergency notification.
####DESCRIPTION
Applications sending emergency-priority notifications will receive a receipt parameter from our API when a notification has been queued. This parameter is a case-sensitive, 30 character string containing the character set [A-Za-z0-9]. This receipt can be used to periodically poll our receipts API to get the status of your notification, up to 1 week after your notification has been received.

***
## Installation
Installation from PowerShell Gallery:
<code>Install-Module -Name PowerShellPushOver </code>

Installation from GitHub:
Simply clone the repository to a location that is part of the PSModulePath.
