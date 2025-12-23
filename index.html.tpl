<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Minecraft Server Control</title>
</head>
<body>
    <h1>Minecraft Server Control</h1>
    <button id="startButton" style="padding: 20px; font-size: 20px; cursor: pointer;">
        🚀 Start Minecraft Server
    </button>
    <p id="status"></p>

<script>
    const API_URL = "${api_url}";
    const API_KEY = "${api_key}";
    
    document.getElementById('startButton').onclick = async () => {
        const status = document.getElementById('status');
        status.innerText = "Sending wake-up signal...";
        try {
            const response = await fetch(API_URL, { 
                method: 'POST',
                headers: {
                    'x-api-key': API_KEY
                }
            });
            const text = await response.text();
            status.innerText = text;
        } catch (err) {
            status.innerText = "Error: " + err;
        }
    };
</script>
</body>
</html>