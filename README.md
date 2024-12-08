fetches TTS audio from a couple of free services and returns the result encoded in base64 format or plays using phiola

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
