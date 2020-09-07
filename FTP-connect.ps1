function FTPConnect($ftpURL, $cred, $storeAt) {
    $request = [Net.WebRequest]::Create($url)
    $request.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectoryDetails
    $request.Credentials = $cred

    $lines = New-Object System.Collections.ArrayList

    $response = $request.GetResponse()
    $stream = $response.GetResponseStream()
    $streamReader = New-Object System.IO.StreamReader($stream)
    while (!$streamReader.EndOfStream) {
        $line = $streamReader.ReadLine()
        $lines.Add($line) | Out-Null
    }
    $streamReader.Dispose()
    $stream.Dispose()
    $response.Dispose()

    foreach ($line in $lines) {
        $tokens = $line.Split(" ", 9, [StringSplitOptions]::RemoveEmptyEntries)
        $name = $tokens[8]
        $permissions = $tokens[0]

        $localFilePath = Join-Path $localPath $name
        $fileUrl = ($url)

        if ($permissions[0] -eq 'd') {
            if (!(Test-Path $localFilePath -PathType container)) {
                Write-Host "Creating directory $localFilePath"
                New-Item $localFilePath -Type directory | Out-Null
            }

            DownloadFtpDirectory ($fileUrl + "/") $credentials $localFilePath
        }
        else {
            Write-Host "Downloading $fileUrl to $localFilePath"

            $downloadRequest = [Net.WebRequest]::Create($fileUrl)
            $downloadRequest.Method = [System.Net.WebRequestMethods+Ftp]::DownloadFile
            $downloadRequest.Credentials = $cred

            $downloadResponse = $downloadRequest.GetResponse()
            $sourceStream = $downloadResponse.GetResponseStream()
            $targetStream = [System.IO.File]::Create($storeAt)
            $buffer = New-Object byte[] 10240
            while (($read = $sourceStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                $targetStream.Write($buffer, 0, $read);
            }
            $targetStream.Dispose()
            $sourceStream.Dispose()
            $downloadResponse.Dispose()
        }
    }
}

$cred = New-Object System.Net.NetworkCredential("username", "password") 
$ftpURL = "ftp://connection.com/folder/file"
FTPConnect $url $cred $storeAt
