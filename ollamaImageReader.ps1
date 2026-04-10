$model = "gemma3:4b"
$imagePath = "C:\Users\under\OneDrive - Washburn University\Pictures\Screenshots\me.jpg"
#For the image path, we need to link it to the photo that is taken every ?? seconds
$prompt = "Describe this image as an output for a security system" 

#Read image as bytes and convert to Base64
$imageBytes = [System.IO.File]::ReadAllBytes($imagePath)
$base64Image = [Convert]::ToBase64String($imageBytes)

Write-Host "Reading image..." 

#Build the JSON body
$body = @{
    model = $model
    prompt = $prompt
    images = @($base64Image)
    stream = $false
} | ConvertTo-Json

#Send the request to Ollama's local API
try {
    $response = Invoke-RestMethod -Method Post -Uri "http://localhost:11434/api/generate" -Body $body -ContentType "application/json" 
    $response.response
} catch {
    Write-Error "Failed to connect to Ollama: $_"
} 