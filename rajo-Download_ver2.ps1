#
# Author: Rasmus Johansson
# Level: Novice
# Version: 2.0
#
#
#
#

function GetSeriesOnWebsite {
# Hämtar hem alla serier som matchar $seriesNeeded
# Namnen läggs i $seriesWebsite medan magneterna läggs i $seriesMagnets som är globala variabler

$HTML = $null
$name = $null
$magnet = $null
$csv = $null # Making sure that the variable is fresh when the script is run
$csv = Import-Csv "D:\Git\Powershell\rajo-metadata.csv"

    $script:seriesMagnets = New-Object System.Collections.ArrayList
    [array]$Script:seriesWebsite = $null
    [array]$Script:seriesMagnets = $null

                
        :first foreach($serie in $csv.URL){
            :second foreach($season in $csv.Season){
                :third foreach($episode in $csv.Episode){            
                    $uri = "https://thepiratebay.org/search/$serie$season$episode/0/7" # URL to the source of download
                    $HTML = Invoke-WebRequest -Uri $uri
                       
                        if($HTML.StatusCode -eq 200){
                            foreach ($names in $csv.Name){       
                                [array]$name = $HTML.Links | ?{$_.innerHTML -match "$names"} | ?{$_.innerHTML -match "ettv"}
                                #[array]$magnet = $HTML.Links | ?{$_.href -like "magnet*$names*"}
                                    if($name -eq $null -and $episode -eq "E01"){
                                        echo "breaking"
                                        echo "$season"
                                        echo "$episode"
                                        #break :first
                                        continue                                   
                                    }
                                [array]$Script:seriesWebsite += $name
                                #[array]$Script:seriesMagnets += $magnet
                                $name.innerHTML
                            }
                        }else{
                            Write-Host "Failed to Invoke-Webrequest.. Something went wrong.."
                            Write-Host $HTML.statusCode
                        }
                }
            }
         
        }
    
}         
#test av Git
function MatchSeriesToDownload {
    
    [int]$num1 = 0
    [int]$num2 = 1
    $childItem = $null
    $ChilditemEdisode = $null
    $episode = $null
    $seriesPath = "D:\Series"
    $csv = $null # Making sure that the variable is fresh when the script is run
    $csv = Import-Csv "D:\Git\Powershell\rajo-metadata.csv"
    $SeasonCSV = Import-Csv "D:\Git\Powershell\rajo-season.csv"
    $EpisodeCSV = Import-Csv "D:\Git\Powershell\rajo-episode.csv"

        [array]$location = (Get-ChildItem -Path $seriesPath -Recurse | ?{$_.PSIsContainer})

        foreach($serie in $csv.FolderName){
            foreach($season in $SeasonCSV.Season){
            #$season
                foreach($episode in $EpisodeCSV.Episode){
                #$episode
                    foreach($loc in $location.name){
                        if($loc -match "$episode"){
                            #echo "hellooo"
                                #Add-Content -Path "D:\text.txt" -Value $loc
                            }else{
                            #echo "damn it"
                            }
                              
                    }
                }
            }
        }



<#
        foreach($serie in $csv.FolderName) {
           #$childitem = $null
           $childItem = (Get-ChildItem -Path "$seriesPath\$serie")
           #$childItem
           #echo "hey"
                foreach($season in $childItem.name){
                    $ChilditemEpisode = Get-ChildItem -LiteralPath "$seriesPath\$serie\$season" 
                    #$ChilditemEpisode
                    [int]$num1 = 0
                    [int]$num2 = 1
                        foreach($episodeName in $ChilditemEpisode){
                            $episode = $episodeName | ?{$_ -match "[E][$num1][$num2]"}
                            $episode.name
                            $num2++
                            #echo "helloooooo"
                                if($num2 -eq 10){
                                    $num2 = 0
                                    $num1++
                                }
                            
                                

                        }
                }
           
        }
#>

}


function MatchSeriesOnDiskWithWebsite { 
# Matchar serier som finns lokalt på disken med vad som finns att laddas hem 
# från hemsidan och skapar upp ett dokument med serierna som inte ska laddas hem

    

    $contentLoc = "D:\Downloads\ScriptDoc\SkipDownload.txt"
    [array]$Script:Matched = $null
    Clear-Content -Path $contentLoc # Rensar SkipDownload.txt av allt som kan finnas i den

    [array]$series = $seriesWebsite.innerHTML
    [array]$location = (Get-ChildItem -Path "D:\Series" -Recurse | ?{$_.PSIsContainer}).FullName
    
        foreach($loc in $location){
            foreach($serie in $series){
                if(test-path -LiteralPath "$loc\$serie"){
                    Write-Host "This path already exists $loc\$serie"
                    if(!((Get-Content -Path $contentLoc) -contains $serie)){
                            Add-Content -Path $contentLoc -Value $serie                        
                    }                                                                                      
                }               
            }
        }

    $Content = Get-Content -Path $contentLoc #Names the series that should not be downloaded
    $Script:cleanContent = $Content.replace("[ettv]","") #Removes "[ettv]" from $content
    Set-Content -Path $contentLoc -Value $cleanContent #Set the new names in the file
           
}

function DownloadMagnets {
# Laddar hem alla serier som finns i $seriesMagnets som inte matchar $cleanContent

    $shouldexit = $false
    $matchedseries = $null
    foreach($magnet in $seriesMagnets.href){
        foreach($row in $cleanContent){
            if($magnet -like "*$row*" ){
                $shouldexit = $true
                $matchedseries = $row
            }
        }
        if($shouldexit){            
            $shouldexit = $false           
        }
        else{            
            Write-Host "Downloading"
            start $magnet
        }
        $matchedseries = $null
       
    } 

}

function MoveDownloadedMaterial {
# Flyttar allt från Downloaded mappen till den korrekta strukturen med serier 
# Den tar reda på serie namnet beroende på mappen och sedan flyttar den in den till korrekt Säsong

    $source = $null
    $pathDest = $null

    do{
        $source = Get-ChildItem -Path "D:\Downloads\Downloaded" 
        $pathDest = (Get-ChildItem -Path "D:\Series" | ?{$_.PSIsContainer}).FullName    
        $loc = "D:\Series"
        $sourceLoc = "D:\Downloads\Downloaded"

            $shouldexit = $false
            $shouldexit2 = $false
            foreach($folder in $source.name){  
                       
                if($folder -match '.+?(?=.S..E..)'){
                    #echo "Working with $folder"
                    $match = $matches | select values -ExpandProperty values                          
                }
                    foreach($path in $pathDest){
                        if($path -like "D:\Scripts\Test\$match"){
                            $shouldexit = $true
                        }
                   }
                   if($shouldexit){
                        echo "Breaking --"
                        $shouldexit = $false
                   }else{
                        if(!(Test-Path $loc\$match)){
                            Write-Host "Making directory -- $match"
                            Set-Location $loc
                            mkdir $match
                        }
                   }
                if($folder -match '[S][0123456789][0123456789]'){
                
                foreach($path2 in "$pathDest\$folder"){

                   $match2 = $matches | select values -ExpandProperty values
                   #Write-Host "-- Working $folder -- $match2"
                   $shouldexit2 = $true
                   }
                }
                    if($shouldexit2){
                    if(!(Test-Path $loc\$match\$match2)){
                            echo "Making directory $match\$match2"
                            Set-Location $loc\$match
                            mkdir $match2                        
                   }else{
                        echo "Season directory already exists.. skipping this part.."
                        $shouldexit2 = $false
                        }       
            }
            if(Test-Path "$loc\$match\$match2"){
                Set-Location $sourceLoc
                Move-Item -LiteralPath "$sourceLoc\$folder" -Destination "$loc\$match\$match2\" -Force                
                echo "Moving -- $sourceLoc\$folder -- to -- $loc\$match\$match2\ --"  
            }                   
        }
          
    }While((Get-ChildItem "D:\Downloads\Temp") -ne $null)
    
}

function changeSigns{
    #Byter ut alla "[" mot "(" och "]" mot ")" i Get-childitem pathen.
    Get-ChildItem -Path "D:\Series" -Recurse | Rename-Item -NewName {$_.name -replace [regex]::Escape("("),"[" -replace [regex]::Escape(")"),"]"} -ErrorAction SilentlyContinue
}