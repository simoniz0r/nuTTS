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

# interactive configuration for nuTTS settings
def config_interactive [] {
    # get full TTS voice list
    let list = main list | from json
    # get list of services
    let services = $list | columns
    # select service from list
    let service = try { $services | input list -f "Select Default TTS Service:" } catch { |e| return ($e.json | from json | wrap error) }
    # return if no service selected
    if $service == null { return ("No service selected" | wrap error) }
    # get list of voices for selected service
    let voices = try { $list | get $service | get voices } catch { |e| return ($e.json | from json | wrap error) }
    # select voice from list
    let voice = try { $voices | input list -f "Select Default TTS Voice:" } catch { |e| return ($e.json | from json | wrap error) }
    # return if no voice selected
    if $voice == null { return ("No voice selected" | wrap error) }
    # get voice ID from selection
    let voice = try { $voice | get vid } catch { |e| return ($e.json | from json | wrap error) }
    # get list of devices
    let devices = try {
        phiola device list | complete | get stdout | lines | take until { |r| $r =~ "Capture" } | drop nth 0
    } catch {
        |e| return ($e.json | from json | wrap error)
    }
    # select device from list
    let device = try { $devices | input list -f "Select Default Playback Device:" } catch { |e| return ($e.json | from json | wrap error) }
    # return if no device selected
    if $device == null { return ("No device selected" | wrap error) }
    # get device number from selection
    let device = try { $device | str snake-case | split row "_" | get 0 } catch { |e| return ($e.json | from json | wrap error) }
    # setup list of numbers
    let numbers = [10,20,30,40,50,60,70,80,90,100]
    # select timeout from list
    let timeout = try { $numbers | input list -f "Select Default Playback Timeout (in seconds):" } catch { |e| return ($e.json | from json | wrap error) }
    # return if no timeout selected
    if $timeout == null { return ("No timeout selected" | wrap error) }
    # select volume from list
    let volume = try { $numbers | input list -f "Select Default Playback Volume:" } catch { |e| return ($e.json | from json | wrap error) }
    # return if no volume selected
    if $volume == null { return ("No volume selected" | wrap error) }
    # setup list of durations
    let waits = [0sec,5sec,10sec,15sec,20sec,25sec,30sec]
    # select wait from list
    let wait = try { $waits | input list -f "Select Default Time to Wait Before Playback:" } catch { |e| return ($e.json | from json | wrap error) }
    # return if no wait selected
    if $wait == null { return ("No wait selected" | wrap error) }
    # update data in stor
    try {
        $service | wrap service
        | merge ($voice | wrap voice)
        | merge ($device | wrap device)
        | merge ($timeout | wrap timeout)
        | merge ($volume | wrap volume)
        | merge ($wait | wrap wait)
        | stor update --table-name nuTTS
    } catch {
        |e| return ($e.json | from json | wrap error)
    }
    # export stor to file
    try {
        mv -f $"($nu.default-config-dir)/nuTTS.sqlite" $"($nu.default-config-dir)/nuTTS.sqlite.bak"
    } catch {
        |e| return ($e.json | from json | wrap error)
    }
    try {
        stor export --file-name $"($nu.default-config-dir)/nuTTS.sqlite"
    } catch {
        |e| mv -f $"($nu.default-config-dir)/nuTTS.sqlite.bak" $"($nu.default-config-dir)/nuTTS.sqlite"
        return ($e.json | from json | wrap error)
    }
    # output config and delete table from memory
    let output = try { stor open | $in.nuTTS.0 } catch { |e| return ($e.json | from json | wrap error) }
    try { stor delete --table-name nuTTS } catch { |e| return ($e.json | from json | wrap error) }
    return $output
}

# Configures default settings for nuTTS
#
# If no flags are used, interactive configuration will be ran
# Results are output in JSON format unless ran in interactive mode
def "main config" [
    --service (-s):string # set default TTS service (must be used with --voice flag)
    --voice (-v):string # set default TTS voice (must be used with --service flag)
    --device (-d):int # set default playback device for 'play' subcommand
    --timeout (-t):int # set default playback timeout for 'play' subcommand
    --volume (-V):int  # set default playback volume for 'play' subcommand
    --wait (-w):duration  # set default time to wait before playback for 'play' subcommand
]: nothing -> string {
    # check if config file exists
    if ($"($nu.default-config-dir)/nuTTS.sqlite" | path type) == "file" {
        # import config into stor if exists
        try { stor import --file-name $"($nu.default-config-dir)/nuTTS.sqlite" } catch { |e| return ($e.json | from json | wrap error | to json) }
    } else {
        # create stor if doesn't exist
        try {
            stor create --table-name nuTTS --columns {service: str, voice: str, device: int, timeout: int, volume: int, wait: str}
        } catch {
            |e| return ($e.json | from json | wrap error | to json)
        }
        # insert default data into stor
        try {
            "Streamlabs" | wrap service
            | merge ("Brian" | wrap voice)
            | merge (0 | wrap device)
            | merge (60 | wrap timeout)
            | merge (100 | wrap volume)
            | merge ("0sec" | wrap wait)
            | stor insert --table-name nuTTS
        } catch {
            |e| return ($e.json | from json | wrap error | to json)
        }
        # export stor to file
        try { stor export --file-name $"($nu.default-config-dir)/nuTTS.sqlite" } catch { |e| return ($e.json | from json | wrap error | to json) }
    }
    # run interactive config if no flags used
    if $service == null and $voice == null and $device == null and $timeout == null and $volume == null and $wait == null {
        let output = try { config_interactive } catch  { |e| return ($e.json | from json | wrap error) }
        return $output
    }
    # get full TTS voice list
    let list = main list | from json
    # set service if not null
    if $service != null and $voice != null {
        # get list of services
        let services = $list | columns
        # check if input is in list of services
        if $service in $services {
            try { $service | wrap service | stor update --table-name nuTTS } catch { |e| return ($e.json | from json | wrap error | to json) }
        } else {
            return ("Invalid service input" | wrap error | to json)
        }
    }
    # set voice if not null
    if $service != null and $voice != null {
        # get default service from stor
        let service = try { stor open | to json | from json | get nuTTS.0.service } catch { |e| return ($e.json | from json | wrap error | to json) }
        # get list of voices for service
        let voices = try { $list | get $service | get voices } catch { |e| return ($e.json | from json | wrap error | to json) }
        # check if input is in list of voices for service
        if $voice in ($voices | get vid) {
            # update stor
            try { $voice | wrap voice | stor update --table-name nuTTS } catch { |e| return ($e.json | from json | wrap error | to json) }
        } else {
            return ("Invalid voice input" | wrap error | to json)
        }
    }
    # set device if not null
    if $device != null {
        # update stor
        try { $device | wrap device | stor update --table-name nuTTS } catch { |e| return ($e.json | from json | wrap error | to json) }
    }
    # set timeout if not null
    if $timeout != null {
        # update stor
        try { $timeout | wrap timeout | stor update --table-name nuTTS } catch { |e| return ($e.json | from json | wrap error | to json) }
    }
    # set volume if not null
    if $volume != null {
        # update stor
        try { $volume | wrap volume | stor update --table-name nuTTS } catch { |e| return ($e.json | from json | wrap error | to json) }
    }
    # set wait if not null
    if $wait != null {
        # update stor
        try { $wait | into string | wrap wait | stor update --table-name nuTTS } catch { |e| return ($e.json | from json | wrap error | to json) }
    }
    # export stor to file
    try {
        mv -f $"($nu.default-config-dir)/nuTTS.sqlite" $"($nu.default-config-dir)/nuTTS.sqlite.bak"
    } catch {
        |e| return ($e.json | from json | wrap error | to json)
    }
    try {
        stor export --file-name $"($nu.default-config-dir)/nuTTS.sqlite"
    } catch {
        |e| mv -f $"($nu.default-config-dir)/nuTTS.sqlite.bak" $"($nu.default-config-dir)/nuTTS.sqlite"
        return ($e.json | from json | wrap error | to json)
    }
    # output config in JSON format and delete table from memory
    let output = try { stor open | $in.nuTTS.0 | to json } catch { |e| return ($e.json | from json | wrap error | to json) }
    try { stor delete --table-name nuTTS } catch { |e| return ($e.json | from json | wrap error) }
    return $output
}

# Gets JSON list of TTS voices
def "main list" [
    --service (-s):string # get voices for specific service
]: nothing -> string {
    # if no --service input, list all services from tts_list.json
    if $service == null {
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

# Plays TTS audio using phiola, returns playback status
#
# Results are output in JSON format by default
def "main play" [
    text:string # text to speek
    --service (-s):string # service to use for TTS voice (default: Streamlabs)
    --voice (-v):string # voice ID for TTS (default: Brian)
    --device (-d):int # device number for TTS playback; 0 is system default (default: 0)
    --exit-code (-e) # output phiola exit code instead of JSON (default: JSON)
    --timeout (-t):int # max playback seconds for TTS (default: 60)
    --volume (-V):int # playback volume for TTS (0-100) (default: 100)
    --wait (-w):duration # seconds to wait before starting TTS playback (default: 0sec)
]: nothing -> string {
    # check if config file exists
    let settings = if ($"($nu.default-config-dir)/nuTTS.sqlite" | path type) == "file" {
        # get settings if nuTTS.sqlite exists
        try { open $"($nu.default-config-dir)/nuTTS.sqlite" | get nuTTS.0 } catch { |e| return ($e.json | from json | wrap error | to json) }
    }
    # get settings from default if no inputs
    let voice = if $voice == null { $settings.voice? | default "Brian" } else { $voice }
    let service = if $service == null { $settings.service? | default "Streamlabs" } else { $service }
    let device = if $device == null { $settings.device? | default 0 } else { $device }
    let timeout = if $timeout == null { $settings.timeout? | default 60 } else { $timeout }
    let volume = if $volume == null { $settings.volume? | default 100 } else { $volume }
    let wait = if $wait == null { $settings.wait? | default 0sec | into duration } else { $wait }
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

# Gets TTS audio for given service, returns base64 encoded audio
#
# Results are output in JSON format
def main [
    text:string # text to speek
    --service (-s):string # service to use for TTS voice (default: Streamlabs)
    --voice (-v):string # voice ID for TTS (default: Brian)
]: nothing -> string {
    # check if config file exists
    let settings = if ($"($nu.default-config-dir)/nuTTS.sqlite" | path type) == "file" {
        # get settings if nuTTS.sqlite exists
        try { open $"($nu.default-config-dir)/nuTTS.sqlite" | get nuTTS.0 } catch { |e| return ($e.json | from json | wrap error | to json) }
    }
    # get settings from default if no inputs
    let voice = if $voice == null { $settings.voice? | default "Brian" } else { $voice }
    let service = if $service == null { $settings.service? | default "Streamlabs" } else { $service }
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
