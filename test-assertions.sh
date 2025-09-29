#!/bin/sh

SCHEMA=TAPRegExt-v1.1.xsd

die() {
	echo $*
	exit 1
}


assert_schema_version_for_rec() {
	# make sure the schema version has no tags if this is a REC
	if xmlstarlet sel -T -t -m "xs:schema" -v "@version"  $SCHEMA \
		| grep "^[0-9]\.[0-9]$" > /dev/null ; then
		: # all is fine
	else
		die "$SCHEMA version has tags (inappropriate for a REC release)"
	fi
}

if grep "ivoaDoctype}{REC}" ivoatexmeta.tex > /dev/null; then
	assert_schema_version_for_rec
fi
