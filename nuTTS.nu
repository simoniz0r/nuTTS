#!/usr/bin/env nu
# Name: nuTTS
# Author: Syretia
# License: MIT
# Dependencies: nushell, phiola
# Description: fetches TTS audio from a couple of free services and returns the result encoded in base64 format or plays using phiola

# fetch and base64 encode audio URLs
def audiourl [voice text] {
    # url encode text and prepend url
    let enc_url = $text | url encode | prepend $voice | str join ""
    # fetch and base64 encode audio url
    let base64 = try { http get -m 5sec $enc_url | encode base64 } catch { |e| return ($e.json | from json | wrap error) }
    # wrap result for json output
    return ($base64 | prepend "data:audio/mp3;base64," | str join "" | wrap audioUrl | merge ($enc_url | wrap originalUrl))
}

# get TikTok TTS audio from weilnet
def weilnet [voice text] {
    # setup body json
    let body = $text | wrap text | merge ($voice | wrap voice) | to json -r
    # make http post request, fallback to weilbyte
    let req_json = try {
        http post -m 6sec -H [content-type application/json] "https://tiktok-tts.weilnet.workers.dev/api/generation" $body
    } catch {
        return (weilbyte $voice $text)
    }
    # prepend audio info and rename column
    let json = try {
        $req_json | upsert data { |row| $row.data | prepend "data:audio/mp3;base64," | str join ""} | rename -c {data: audioUrl}
    } catch {
        return (weilbyte $voice $text)
    }
    # output json result
    return $json
}

# get TikTok TTS audio from weilbyte
def weilbyte [voice text] {
    # setup body json
    let body = $text | wrap text | merge ($voice | wrap voice) | to json -r
    # make http post request and bas64 encode result, fallback to cursecode
    let base64 = try {
        http post -m 6sec -H [content-type application/json] "https://tiktok-tts.weilbyte.dev/api/generate" $body | encode base64
    } catch {
        return (cursecode $voice $text)
    }
    # wrap result for json otuput
    return ($base64 | prepend "data:audio/mp3;base64," | str join "" | wrap audioUrl)
}

# get TikTok TTS audio from cursecode
def cursecode [voice text] {
    # setup body json
    let body = $text | wrap text | merge ($voice | wrap voice) | to json -r
    # make http post request, fallback to gesserit
    let req_json = try {
        http post -m 6sec -H [content-type application/json] "https://tts.cursecode.me/api/tts" $body
    } catch {
        return (gesserit $voice $text)
    }
    # rename column
    let json = try { $req_json | rename -c { audio: audioUrl } } catch { return (gesserit $voice $text) }
    # output json result
    return $json
}

# get TikTok TTS audio from gesserit
def gesserit [voice text] {
    # setup body json
    let body = $text | wrap text | merge ($voice | wrap voice) | to json -r
    # make http post request, fallback to lazypy
    let json = try { http post -m 6sec "https://gesserit.co/api/tiktok-tts" $body } catch { return (lazypy $voice "TikTok" $text) }
    # output json result
    return $json
}

# get TTS audio from uberduck
def uberduck [voice text] {
    # setup body json
    let body = $text | wrap text | merge ($voice | wrap voice) | to json -r
    # make http post request
    let audio_json = try {
        http post -m 10sec -H [content-type application/json] "https://www.uberduck.ai/splash-tts" $body
    } catch {
        |e| return ($e.json | from json | wrap error)
    }
    let audio_url = try { $audio_json | get response.path } catch { |e| return ($e.json | from json | wrap error) }
    # fetch and base64 encode result
    let base64 = try { http get -m 5sec ($audio_url) | encode base64 } catch { |e| return ($e.json | from json | wrap error) }
    # wrap result for json otuput
    return ($base64 | prepend "data:audio/wav;base64," | str join "" | wrap audioUrl | merge $audio_json)
}

# get TTS audio from lazypy
def lazypy [voice service text] {
    # create body using url build-query
    let body = $text | wrap text | merge ($service | wrap service) | merge ($voice | wrap voice) | url build-query
    # post body to lazypy and get audio_url
    let audio_json = try {
        http post -m 10sec -H [content-type application/x-www-form-urlencoded] "https://lazypy.ro/tts/request_tts.php" $body
    } catch {
        |e| return ($e.json | from json | wrap error)
    }
    # return response if success is not true
    if ($audio_json | get success) != true {
        return ($audio_json | wrap error)
    }
    let audio_url = try { $audio_json | get audio_url } catch { |e| return ($e.json | from json | wrap error) }
    # fetch and base64 encode result
    let base64 = try { http get -m 5sec $audio_url | encode base64 } catch { |e| return ($e.json | from json | wrap error) }
    return ($base64 | prepend "data:audio/mp3;base64," | str join "" | wrap audioUrl | merge $audio_json)
}

# gets JSON list of TTS voices
def "main list" [
    --service (-s):string = all # get voices for specific service
]: nothing -> string {
    # if no --service input, list all services from tts_list.json
    if $service == "all" {
        let list = try {
            http get -r "https://raw.githubusercontent.com/simoniz0r/nuTTS/main/tts_list.json"
        } catch {
            |e| return ($e.json | from json | wrap error | to json)
        }
        return $list
    # else get list for --service input from tts_list.json
    } else {
        let list = try {
            http get "https://raw.githubusercontent.com/simoniz0r/nuTTS/main/tts_list.json" | get $service | to json
        } catch {
            |e| return ($e.json | from json | wrap error | to json)
        }
        return $list
    }
}

# plays TTS audio using phiola, returns playback status
#
# results are output in JSON format by default
def "main play" [
    voice:string # voice ID for TTS
    service:string # service voice is from
    text:string # text to speek
    --device (-d):int = 0 # device number for TTS playback; 0 is system default
    --exit-code (-e) = false # output phiola exit code instead of JSON
    --timeout (-t):int = 60 # max playback seconds for TTS
    --volume (-v):int = 100 # playback volume for TTS (0-100)
    --wait (-w):duration = 0sec # seconds to wait before starting TTS playback
]: nothing -> string {
    # get default device
    if $device == 0 {
        # get device list
        let device_list = try {
            phiola device list | complete
        } catch {
            |e| return ($e.json | from json | wrap error | to json)
        }
        # return if exit code not 0
        if ($device_list | get exit_code) != 0 {
            return ($device_list | wrap error | to json)
        }
        # try to find default in device list
        let device = try {
            $device_list | get stdout | lines | find "- Default" | get 0 | str snake-case | split row "_" | get 1
        # fallback to device 1 if cannot find default
        } catch { 1 }
    }
    # decode text
    let detext = $text | url decode
    # route based on service
    let result = match ($service | str downcase) {
        audiourl => { audiourl $voice $detext },
        tiktok => { weilnet $voice $detext },
        uberduck => { uberduck $voice $detext },
        _ => { lazypy $voice $service $detext }
    }
    # get base64 from result
    let base64 = try { $result | get audioUrl | split row "base64," | get 1 } catch { return ($result | to json) }
    # sleep for $wait before playing
    sleep $wait
    # decode base64 and play with phiola
    let playback = try {
        $base64 | decode base64 | phiola play -device $device -until $timeout -volume $volume @stdin | complete
    } catch {
        |e| return ($e.json | from json | wrap error | to json)
    }
    # return phiola result as json if $exit_code is false
    if $exit_code == false {
        return ($playback | to json)
    # else output only exit code
    } else {
        let phiola_exit = try { $playback | get exit_code } catch { |e| return ($e.json | from json | wrap error | to json) }
        return $phiola_exit
    }
}

# gets TTS audio for given service, returns base64 encoded audio
#
# results are output in JSON format
def main [
    voice:string # voice ID for TTS
    service:string # service voice is from
    text:string # text to speek
]: nothing -> string {
    # decode text
    let detext = $text | url decode
    # route based on service
    let result = match ($service | str downcase) {
        audiourl => { audiourl $voice $detext },
        tiktok => { weilnet $voice $detext },
        uberduck => { uberduck $voice $detext },
        _ => { lazypy $voice $service $detext }
    }
    # return result in json format
    return ($result | to json)
}
