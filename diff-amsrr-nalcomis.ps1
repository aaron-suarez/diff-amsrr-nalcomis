<# 
  This script takes one report generated by NALCOMIS 
  and another report generated by AMSRR and displays
  the relevant information about requisitions that 
  are on one report but not the other.
#>

# Convert the file into a csv
$file = 'H:\AMSRR_NMC-PMC_Hi-Pri_Report.xls'
$newname =  $file -replace '\.xls$', '.csv'
$ExcelWB = new-object -comobject excel.application
$Workbook = $ExcelWB.Workbooks.Open($file) 
$Workbook.SaveAs($newname,6)
$Workbook.Close($false)
$ExcelWB.quit()

# Open each report
$file = 'H:\AMSRR_NMC-PMC_Hi-Pri_Report.csv'
$file2 = 'H:\NMCS.txt'
$reader = [System.IO.File]::OpenText($file)
$reader2 = [System.IO.File]::OpenText($file2)

# Create arrays to store document numbers
$docNums = New-Object System.Collections.ArrayList($null) 
$docNumbers = New-Object System.Collections.ArrayList($null)

# Encase the following in a try/finally 
# block to ensure the file is always closed
try {
  # Loop repeats to read each line from each text file
  for(;;) {

    # Read a line of text from each file        
    $line = $reader.ReadLine() 
    $line2 = $reader2.ReadLine()

    # Get the BUNO from the AMSRR report        
    if (!($line -eq $null)) {        
      if ($line.substring(0,7) -eq "VFA-204") {         
        $buno = $line.split(",") -match "16\d\d\d\d"  
      }

      # Collect the status and fill the AMSRR array with the info  
      if($docNumber = $line.split(",") -match "\d\d\d\dG\d\d\d") {   
        if ($status = $line.split(",") -match "\d\d\d/\w\w/\w\w\w") {    
          $status = $status -replace ‘[/]’,""     
          $line = "Document: $docNumber`t BUNO: $buno`t Status: $status"    
          $docNums.Add($line + " in AMSRR")      
        }  
      }   
    }

    # Parse the info from the NALCOMIS report 
    if (!($line2 -eq $null)) {  
      if ($line2.length -gt 2) {
        $orgCode = $line2.Substring(0, 3)
      } Else {
          $orgCode = ""
      }   
      if ($orgCode -eq "KA2"){    
        if(!($line2.split() -match "162873")){  # Ignore this aircraft, it's out of reporting   
          if($docNumber2 = $line2.split() -match "\d\d\d\dG\d\d\d") {

            # Add the BUNO and status for the document in this line    
            $buno2 = $line2.substring(46,6)      
            $status2 = $line2.substring(112,8)
            
            # Only collect doc number that are in a shipping status      
            if($status2 -match "\d\d\dBA\w\w\w" -or $status2 -match "\d\d\dJ\w\w\w") {       
              $docNumber2 = -join $docNumber2

              # Add UIC and suffix to complete the doc number for the array       
              if($docNumber2.length -eq 8){        
                $docNumbers.Add("N54076" + $docNumber2 + "xxx")       
              } elseif($docNumber2.length -eq 9) {        
                $docNumbers.Add("N54076" + $docNumber2 + "xx")       
              }
            }

            # Add docs that are not an outstanding suffix doc to the array     
            if (!($status2 -match "\d\d\dOSSUF")) {      
              $line2 = "Document: $docNumber2`t BUNO: $buno2`t Status: $status2"       
              $docNums.Add($line2 + " in NALCOMIS")      
            }     
          }     
        }    
      } 
    }

    # Break out of the loop when the end of each file is reached 
    if ($line -eq $null -And $line2 -eq $null) {
      break
    }    
  }
}

# Always close the text file streams
finally {    
  $reader.Close() 
  $reader2.Close()
}

# Sort the array 
$docNums.Sort()

# Create a text file and add a header
"*****************************************" > $HOME\AMSRRdifferences.txt
"`n`n`n " >>  $HOME\AMSRRdifferences.txt

# Print only the lines that are different to the differences file
for($i=0; $i -lt $docNums.Count; $i+=1) { 
  $string1 = $docNums[$i-1] 
  $string2 = $docNums[$i+1] 
  if (!($string1 -eq $null -or $string2 -eq $null)) {  
    if ($docNums[$i].substring(0,50).CompareTo($string2.substring(0,50)) -ne 0 -and $docNums[$i].substring(0,50).CompareTo($string1.substring(0,50)) -ne 0) {   
      echo $docNums[$i]`n | Out-File $HOME\AMSRRdifferences.txt -append  
    } 
  }
}

# Finish the formatting
"`n`n`n*****************************************`n`n" >>  $HOME\AMSRRdifferences.txt

# Print out the URLs for FedEx Tracking for each of the documents that are different between the two files
"Tracking Numbers`n" >> $HOME\AMSRRdifferences.txt
$url = "https://www.fedex.com/apps/fedextrack/?action=tcn&trackingnumber=n540766082g715xxx&cntry_code=us&shipdate=2016-03-24"
$date = get-date -format u$date = $date.substring(0, 10)
for ($j=0; $j -lt $docNumbers.Count; $j+=1) { 
  $trackingURL = $url.substring(0, 65) + $docNumbers[$j] + $url.substring(82, 24) + $date echo $trackingURL`n | Out-File $HOME\AMSRRdifferences.txt -append
}

# Open the file in the text editor
& 'H:\AMSRRdifferences.txt'
