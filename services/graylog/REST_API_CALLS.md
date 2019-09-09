# TODO: to be automatically call later


## Create inputs

POST GRAYLOG_URL/api/system/inputs

json body
{
  "title": "standard GELF UDP input",
  "type": "org.graylog2.inputs.gelf.udp.GELFUDPInput",
  "global": true,
  "configuration": {
    "bind_address":  "0.0.0.0",
    "port":  12201
},
  "node": null
}

## Create streams


POST GRAYLOG_URL/streams
{
  "title": "simcore stream",
  "description": "contains all messages from simcore stack",
  "rules": [
    "object"
  ],
  "content_pack": null,
  "matching_type": "AND",
  "remove_matches_from_default_stream": false,
  "index_set_id": "string" # needs to be the default index set (use a GET)
}