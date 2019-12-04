$vReduceValueCSVPath = "C:\Users\FEI\Dropbox\Big Data\Apps - QS\Insurance Analytics\SalesReps.csv"
$TemplateAppID = "1fe20e0a-89d9-4ba4-90fb-c52bd89b6449"
$BaseAppName = "Insurance Analytics"
$AppOwner = "SENSEDEMO7\Fady"
$CustomProperty = "LoopAndReduce"
$CustomPropertyValue = "YES"
$PublishToStream = "Loop and Reduce"

Connect-Qlik sensedemo7

<# Check if custom property exists, if not then create it. #>
$CustomPropertyExistsTest = Get-QlikCustomProperty -filter "name eq '$CustomProperty'" -full
if(!$CustomPropertyExistsTest) {
$NewCustomProperty = New-QlikCustomProperty -name "$CustomProperty" -choiceValues "$CustomPropertyValue" -objectTypes "App","Stream"
"Created New Custom Property: $($CustomProperty)"
}

<# Check if stream exists, if not then create it. #>
$StreamExistsTest = Get-QlikStream -filter "name eq '$PublishToStream'" -full
if(!$StreamExistsTest) {
$NewStream = New-QlikStream -name "$PublishToStream" -customProperties "$CustomProperty=$CustomPropertyValue"
"Created New Stream: $($PublishToStream)"
}

<# Loop over each value in the CSV. #>
Import-Csv $vReduceValueCSVPath | Foreach-Object { 

    foreach ($property in $_.PSObject.Properties){
        $vReduceValueField = $property.Name
        $vReduceValue = $property.Value
    }

    "Running through value: $($vReduceValue)"
    $AppName = "$($BaseAppName) - $($vReduceValue)"

    $AppExistsTest = Get-QlikApp -filter "name eq '$AppName'" -full
    if(!$AppExistsTest) {
        <#
        If app doesn't exist:
        copy Template app, rename, update owner and custom property, publish to stream, create task, and run it.
        #>
        $NewApp =  Copy-QlikApp -id "$TemplateAppID" -name "$AppName"
        $AppID = $NewApp."id"
        $UpdatedApp = Update-QlikApp -id "$AppID" -owner "$AppOwner" -customProperties "$CustomProperty=$CustomPropertyValue" -description "This app contains only $($vReduceValue)'s data."
        $PublishedApp = Publish-QlikApp -id "$AppID" -stream "$PublishToStream"
        
        $NewTask = New-QlikTask -appId "$AppID" -name "$($CustomProperty)-$($AppName)"
        $TaskID = $NewTask."id"
        $UpdatedTask = Update-QlikReloadTask -id "$TaskID" -Enabled $true -TaskSessionTimeout 1440 -MaxRetries 0 
        $StartedTask = Start-QlikTask -id "$TaskID"

        "App didn't exist: created app, published it, created task, and ran it."
    }
    else {
        <#
        If app does exist:
        check if task exists and if so, run it.
        #>
        $TaskExistsTest = Get-QlikTask -filter "name eq '$($CustomProperty)-$($AppName)'" -full
        if(!$TaskExistsTest) {
            $AppID = $AppExistsTest."id"
            $NewTask = New-QlikTask -appId "$AppID" -name "$($CustomProperty)-$($AppName)"
            $TaskID = $NewTask."id"
            $UpdatedTask = Update-QlikReloadTask -id "$TaskID" -Enabled $true -TaskSessionTimeout 1440 -MaxRetries 0
        }
        else{
            $TaskID = $TaskExistsTest."id"
        }
        $StartedTask = Start-QlikTask -id "$TaskID"
    }
}