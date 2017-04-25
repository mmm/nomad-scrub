#!/bin/bash -x

# register ourself as a watcher
[ "${WATCHER}" != "$0" ] && exec env WATCHER="$0" consul watch -type=key -key=some/sort/of/coordination/key "$0" || :                                                                                                                                                        

logger "running nomad-scrub job"

scrub_event() {
  local s3_event_path=$1
  aws --region=us-west-2 s3 cp $s3_event_path - | \
    jq -r '.| .cc_num = "TOKEN"' | \
    aws --region=us-west-2 s3 cp - "${s3_event_path/nomad-data-to-scrub/nomad-scrubbed-data}"
}

event_url=`consul kv get some/sort/of/coordination/key`
[ ! -z "$event_url" ] && scrub_event $event_url

logger "done running nomad-scrub job"

