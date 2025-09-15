#!/bin/bash
# write a sample TAPRegExt record from the capabilities on a DaCHS
# server on localhost to stdout.  We validate the document against the schema
# in this repo, so we need stilts as for make test.
#
# It also needs xmlstarlet.

curl -s http://localhost:8080/tap/capabilities \
	| xmlstarlet ed \
		-d "//capability[not(contains(@standardID, 'capabilities') or contains(@standardID, 'TAP'))]" \
	| xmlstarlet fo -o -s 2 > sample.xml

STILTS=stilts
SCHEMA_FILE=TAPRegExt-v1.1.xsd
$STILTS xsdvalidate \
		schemaloc="http://www.ivoa.net/xml/TAPRegExt/v1.0=$SCHEMA_FILE" \
		schemaloc="http://www.ivoa.net/xml/VOSICapabilities/v1.0=https://www.ivoa.net/xml/VOSICapabilities/v1.0" \
		schemaloc="http://www.ivoa.net/xml/VODataService/v1.1=https://www.ivoa.net/xml/VODataService/v1.1" \
		doc=sample.xml
