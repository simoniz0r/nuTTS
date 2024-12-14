#!/usr/bin/env nu
# Name: sb_to_fb
# Author: Syretia
# License: MIT
# Dependencies: nushell
# Description: sends event data from Streamer.bot to Firebot

# parse env vars set by Streamer.bot and send to Firebot
def main [] {
    # try to get trigger from STREAMER_TRIGGER env var
    let trigger = try {
        $env.STREAMER_TRIGGER
    } catch {
        return "Failed to get trigger"
    }
    # find env vars starting with STREAMER_
    let envrecord = try {
        $env | items { |name, value| if $name =~ "STREAMER_" { $value | wrap $name } } | into record
    } catch {
        return "Failed to find environment variables"
    }
    # wrap env var results in JSON
    let json = try {
        $envrecord | wrap data | merge (0 | wrap ttl) | to json
    } catch {
        return "Failed to create JSON"
    }
    # send http post to Firebot's API to set data from Streamer.bot as variable
    let firebot = try {
        http post -fH [content-type application/json] http://localhost:7472/api/v1/custom-variables/($trigger) $json
    } catch {
        |e| return $e.msg
    }
    return ($firebot | get status)
}
