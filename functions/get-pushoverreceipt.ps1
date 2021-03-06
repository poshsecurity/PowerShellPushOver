#requires -Version 3
function Get-PushoverReceipt
{
    <#
            .SYNOPSIS
            Get's Pushover Receipt information in regards to an Emergency notification.

            .DESCRIPTION
            Applications sending emergency-priority notifications will receive a receipt parameter from our API when a notification has been queued. This parameter is a case-sensitive, 30 character string containing the character set [A-Za-z0-9]. This receipt can be used to periodically poll our receipts API to get the status of your notification, up to 1 week after your notification has been received.

            .NOTES
            AUTHOR: Kieran Jacobsen <code@poshsecurity.com>
            LASTEDIT: 2016/02/21

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

        # API Receipt from the emergency message you sent
        [Parameter(Mandatory = $true, 
                    Position = 1)]
        [ValidateLength(30,30)]
        [String] 
        $Receipt
    )

    $RequestURL = 'https://api.pushover.net/1/receipts/{0}.json' -f $Receipt
    $Parameters = @{}
    $Parameters.Add('token', $Token)
    
    try 
    {
        $Response = Invoke-RestMethod -Uri $RequestURL -Body $Parameters -ContentType 'application/x-www-form-urlencoded' -Method GET
    }
    catch 
    {
        $MyError = $_
        if ($null -ne $MyError.Exception.Response)
        { 
            try
            {
                # Recieved an error from the API, lets get it out
                $result = $MyError.Exception.Response.GetResponseStream()
                $reader = New-Object -TypeName System.IO.StreamReader -ArgumentList ($result)
                $responseBody = $reader.ReadToEnd()
                $JSONResponse = $responseBody | ConvertFrom-Json
                
                # Throw the error message from API to caller
                Throw $JSONResponse.message
            }
            catch
            {
                # Something went wrong, throw the original error
                Throw $MyError
            }
        }
        else
        {
            # No response from API, throw the error as is
            Throw $MyError
        }
    } 

    # Unix Origin
    $origin = Get-Date -Year 1970 -Month 1 -Day 1 -Hour 0 -Minute 0 -Second 0 -Millisecond 0

    # Clean up the response object so the whole thing is more PS friendly, DateTime for timestamps, Boolean etc.
    Add-Member -InputObject $Response -MemberType NoteProperty -Name 'success' -Value ($Response.status -eq 1)
    Add-Member -InputObject $Response -MemberType NoteProperty -Name 'acknowledged' -Value ($Response.acknowledged -eq 1) -Force
    Add-Member -InputObject $Response -MemberType NoteProperty -Name 'acknowledged_at' -Value ($origin.AddSeconds($Response.acknowledged_at)) -Force
    Add-Member -InputObject $Response -MemberType NoteProperty -Name 'expired' -Value ($Response.expired -eq 1) -Force
    Add-Member -InputObject $Response -MemberType NoteProperty -Name 'expires_at' -Value ($origin.AddSeconds($Response.expires_at)) -Force
    Add-Member -InputObject $Response -MemberType NoteProperty -Name 'last_delivered_at' -Value ($origin.AddSeconds($Response.last_delivered_at)) -Force
    Add-Member -InputObject $Response -MemberType NoteProperty -Name 'called_back' -Value ($Response.called_back -eq 1) -Force
    if ($Response.called_back_at -ne 0)
    {
        Add-Member -InputObject $Response -MemberType NoteProperty -Name 'called_back_at' -Value ($origin.AddSeconds($Response.called_back_at)) -Force
    }
    else
    {
        Add-Member -InputObject $Response -MemberType NoteProperty -Name 'called_back_at' -Value $null -Force
    }

    # Return the reponse object to the caller, they can decide if the want process it
    $Response
}
