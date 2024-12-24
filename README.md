nuTTS fetches text-to-speech audio from free services such as [lazypy.ro](https://lazypy.ro/tts), [Uberduck.ai](https://www.uberduck.ai/), and a few services that offer TikTok TTS voices. By default, the resulting audio is returned in base64 encoded format wrapped in JSON. TTS audio can also be played using [phiola](https://github.com/stsaz/phiola). nuTTS is intended to be used with Twitch bots such as [Firebot](https://firebot.app/) to provide TTS for alerts.

# Basic Usage

```
Gets TTS audio for given service, returns base64 encoded audio

Results are output in JSON format

Usage:
  > nuTTS {flags} <text>

Subcommands:
  nuTTS config (custom) - Configures default settings for nuTTS
  nuTTS list (custom) - Gets JSON list of TTS voices
  nuTTS play (custom) - Plays TTS audio using phiola, returns playback status

Flags:
  -s, --service <string>: service to use for TTS voice (default: Streamlabs)
  -v, --voice <string>: voice ID for TTS (default: Brian)
  -h, --help: Display the help message for this command

Parameters:
  text <string>: text to speek
```

Example:

`nuTTS --service Streamlabs --voice Emma "test message"`

```json
{
  "audioUrl": "data:audio/mp3;base64,<base64 encoded audio here>",
  "success": true,
  "audio_url": "https://lazypy.ro/tts/assets/audio/Streamlabs_Emma_c72b9698fa1927e1dd12d3cf26ed84b2.mp3",
  "info": "HTTP status: 200; Total transfer time: 0.333263 seconds.",
  "error_msg": null,
  "service_response": "{\"success\":true,\"message\":\"OK\",\"speak_url\":\"https:\\/\\/polly.streamlabs.com\\/v1\\/speech?OutputFormat=mp3&Text=test%20message&VoiceId=Emma&Engine=standard&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAURHYCFGLCVRRFGR5%2F20241208%2Fus-west-2%2Fpolly%2Faws4_request&X-Amz-Date=20241208T050441Z&X-Amz-SignedHeaders=host&X-Amz-Expires=900&X-Amz-Signature=c2627c4f334b9f4e1460d44460713b1d794c8aee1e828019c64ba3dfc146548f\"}",
  "meta": {
    "service": "Streamlabs",
    "voice_id": "Emma",
    "voice_name": "",
    "text": "test message",
    "playlist_index": 0
  }
}
```

# Configure nuTTS Settings

```
Configures default settings for nuTTS

If no flags are used, interactive configuration will be ran
Results are output in JSON format unless ran in interactive mode

Usage:
  > nuTTS config {flags}

Flags:
  -s, --service <string>: set default TTS service (must be used with --voice flag)
  -v, --voice <string>: set default TTS voice (must be used with --service flag)
  -d, --device <int>: set default playback device for 'play' subcommand
  -t, --timeout <int>: set default playback timeout for 'play' subcommand
  -V, --volume <int>: set default playback volume for 'play' subcommand
  -w, --wait <duration>: set default time to wait before playback for 'play' subcommand
  -h, --help: Display the help message for this command
```

Example:

`nuTTS config --service Streamlabs --voice Emma --device 2 --timeout 20 --volume 10 --wait 0sec`

```json
{
  "service": "Streamlabs",
  "voice": "Emma",
  "device": 2,
  "timeout": 20,
  "volume": 10,
  "wait": "0sec"
}
```

# TTS Voice List

```
Gets JSON list of TTS voices

Usage:
  > nuTTS list {flags}

Flags:
  -s, --service <string>: get voices for specific service
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
Plays TTS audio using phiola, returns playback status

Results are output in JSON format by default

Usage:
  > nuTTS play {flags} <text>

Flags:
  -s, --service <string>: service to use for TTS voice (default: Streamlabs)
  -v, --voice <string>: voice ID for TTS (default: Brian)
  -d, --device <int>: device number for TTS playback; 0 is system default (default: 0)
  -e, --exit-code: output phiola exit code instead of JSON (default: JSON)
  -t, --timeout <int>: max playback seconds for TTS (default: 60)
  -V, --volume <int>: playback volume for TTS (0-100) (default: 100)
  -w, --wait <duration>: seconds to wait before starting TTS playback (default: 0sec)
  -h, --help: Display the help message for this command

Parameters:
  text <string>: text to speek
```

Example:

`nuTTS play --device 2 --volume 10 --timeout 20 --wait 5sec --service Streamlabs --voice Emma "test message"`

```json
{
  "stdout": "\n#1 \" - \" \"@stdin\" 0MB 0:20.000 (441,000 samples) 48kbps MPEG1-L3 float32 22050Hz mono\n\n[................................................................] 0:00 / 0:20\r[===.............................................................] 0:01 / 0:20\n",
  "stderr": "φphiola v2.2.8 (linux-amd64)\n",
  "exit_code": 0
}
```
