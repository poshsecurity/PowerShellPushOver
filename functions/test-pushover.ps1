#requires -Version 3
function Test-PushOver 
{
    <#
            .SYNOPSIS
            Tests if the API, User, Group or Device Tokens are Valid

            .DESCRIPTION
            As an optional step in collecting user keys for users of your application, you may verify those keys to ensure that a user has copied them properly, that the account is valid, and that there is at least one active device on the account. User and group identifiers may be verified as can Device Identifiers.

            .EXAMPLE
            Test-PushOver -APIToken 'KzGDORePK8gMaC0QOYAMyEEuzJnyUi' -User 'pQiRzpo4DXghDmr9QzzfQu27cmVRsG'
            tests if token and user are valid

            .EXAMPLE
            Send-PushOver -APIToken 'KzGDORePK8gMaC0QOYAMyEEuzJnyUi' -User 'pQiRzpo4DXghDmr9QzzfQu27cmVRsG' -DeviceID 'droid2'
            Tests if token, user and device are valid

            .NOTES
            AUTHOR: Kieran Jacobsen <code@poshsecurity.com>
            LASTEDIT: 2016/02/20

            .LINK
            http://poshsecurity.com/

            .LINK
            http://pushover.net/

            .LINK
            https://github.com/PoshSecurity/PowerShellPushOver
    #>
    [CMDLetBinding()]
    param
    (
        # Your application's API token.
        [Parameter(Mandatory = $true, 
                    Position = 0)]
        [ValidateLength(30,30)]
        [String] 
        $Token,

        # The user key (not e-mail address) of your user (or you), viewable when logged into our dashboard (often referred to as USER_KEY).
        [Parameter(Mandatory = $true, 
            ParameterSetName = 'User',
                    Position = 1)]
        [ValidateLength(30,30)]
        [String] 
        $User,

        # The group key (not e-mail address) of your user (or you).
        [Parameter(Mandatory = $true, 
            ParameterSetName = 'Group',
                    Position = 1)]
        [ValidateLength(30,30)]
        [String] 
        $Group,

        # Your user's device name to send the message directly to that device, rather than all of the user's devices (multiple devices may be separated by a comma).
        [Parameter(Mandatory = $false, 
                    Position = 2)]
        [ValidateLength(0,25)]
        [String]
        $DeviceID
    )

    # Add the default/mandatory parameters
    $Parameters = @{}
    $Parameters.Add('token', $Token)
    if ($PSBoundParameters.ContainsKey('User')) 
    {
        $Parameters.Add('user', $User)
    }
    else
    {
        $Parameters.Add('user', $Group)
    }

    if ($PSBoundParameters.ContainsKey('DeviceID')) 
    {
        $Parameters.Add('device', $DeviceID)
    }

    try 
    {
        $Response = Invoke-RestMethod -Uri 'https://api.pushover.net/1/users/validate.json' -Body $Parameters -ContentType 'application/x-www-form-urlencoded' -Method POST
    }
    catch 
    {
        $MyError = $_
        if ($null -ne $MyError.Exception.Response)
        { 
            # Recieved an error from the API, lets get it out
            $result = $MyError.Exception.Response.GetResponseStream()
            $reader = New-Object -TypeName System.IO.StreamReader -ArgumentList ($result)
            $responseBody = $reader.ReadToEnd()
            $JSONResponse = $responseBody | ConvertFrom-Json
                
            # Throw the error message from API to caller
            Throw ($JSONResponse.Errors)
        }
        else
        {
            # No response from API, throw the error as is
            Throw $MyError
        }
    }

    # if we got back a status of 1, return true, else false
    return ($Response.status -eq 1)
}
