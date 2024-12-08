Fetches TTS audio from a couple of free services. By default, the resulting audio is returned in base64 encoded format wrapped in JSON. TTS audio can also be played using [phiola](https://github.com/stsaz/phiola).

# Basic Usage

```
gets TTS audio for given service, returns base64 encoded audio

results are output in JSON format

Usage:
  > nuTTS <voice> <service> <text>

Subcommands:
  nuTTS list (custom) - gets JSON list of TTS voices
  nuTTS play (custom) - plays TTS audio using phiola, returns playback status

Flags:
  -h, --help: Display the help message for this command

Parameters:
  voice <string>: voice ID for TTS
  service <string>: service voice is from
  text <string>: text to speek
```

Example:

`nuTTS Brian Streamlabs "test message"`

```json
{
  "audioUrl": "data:audio/mp3;base64,<base64 encoded audio here>",
  "success": true,
  "audio_url": "https://lazypy.ro/tts/assets/audio/Streamlabs_Brian_c72b9698fa1927e1dd12d3cf26ed84b2.mp3",
  "info": "HTTP status: 200; Total transfer time: 0.333263 seconds.",
  "error_msg": null,
  "service_response": "{\"success\":true,\"message\":\"OK\",\"speak_url\":\"https:\\/\\/polly.streamlabs.com\\/v1\\/speech?OutputFormat=mp3&Text=test%20message&VoiceId=Brian&Engine=standard&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAURHYCFGLCVRRFGR5%2F20241208%2Fus-west-2%2Fpolly%2Faws4_request&X-Amz-Date=20241208T050441Z&X-Amz-SignedHeaders=host&X-Amz-Expires=900&X-Amz-Signature=c2627c4f334b9f4e1460d44460713b1d794c8aee1e828019c64ba3dfc146548f\"}",
  "meta": {
    "service": "Streamlabs",
    "voice_id": "Brian",
    "voice_name": "",
    "text": "test message",
    "playlist_index": 0
  }
}
```

# TTS Voice List

```
gets JSON list of TTS voices

Usage:
  > nuTTS list {flags}

Flags:
  -s, --service <string>: get voices for specific service (default: 'all')
  -h, --help: Display the help message for this command
```

Example:

`nuTTS list --service TikTok`

```json
{
  "charLimit": 300,
  "countBytes": true,
  "voices": [
    {
      "vid": "en_uk_001",
      "name": "Narrator (Chris)",
      "flag": "GB",
      "lang": "English",
      "accent": "England",
      "gender": "M"
    },
    {
      "vid": "rest_of_voices_here",
      "name": "Rest Of Voices Here",
      "flag": "GB",
      "lang": "English",
      "accent": "England",
      "gender": "M"
    }
  ]
}
```

# Play TTS Audio With phiola

```
plays TTS audio using phiola, returns playback status

results are output in JSON format

Usage:
  > nuTTS play {flags} <voice> <service> <text>

Flags:
  -d, --device <int>: device number for TTS playback (default: 1)
  -t, --timeout <int>: max playback seconds for TTS (default: 60)
  -v, --volume <int>: playback volume for TTS (0-100) (default: 100)
  -h, --help: Display the help message for this command

Parameters:
  voice <string>: voice ID for TTS
  service <string>: service voice is from
  text <string>: text to speek
```

Example:

`nuTTS play --device 2 --volume 10 --timeout 20 Brian Streamlabs "test message"`

```json
{
  "stdout": "\n#1 \" - \" \"@stdin\" 0MB 0:20.000 (441,000 samples) 48kbps MPEG1-L3 float32 22050Hz mono\n\n[................................................................] 0:00 / 0:20\r[===.............................................................] 0:01 / 0:20\n",
  "stderr": "φphiola v2.2.8 (linux-amd64)\n",
  "exit_code": 0
}
```
