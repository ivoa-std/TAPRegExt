#!/bin/sh
# write a sample TAPRegExt record from the capabilities on
# http://localhost:8080/tap to stdout; this, really, assumes a DaCHS running
# there, and because of the validation, it also assumes a DaCHS is installed
# locally.
#
# It also needs xmlstarlet.

DEST=sample.xml

function cleanup() {
	rm -f $DEST.tmp.$$
}
trap cleanup EXIT

curl -s http://localhost:8080/tap/capabilities \
	| xmlstarlet ed -d "//feature[starts-with(form, 'ivo_apply_pm')]" \
		-d "//languageFeatures[@type='ivo://ivoa.net/std/TAPRegExt#features-udf']/feature[not(starts-with(form, 'ivo_healpix_center'))]" \
		-d "//languageFeatures[@type='ivo://org.gavo.dc/std/exts#extra-adql-keywords']/feature[not(starts-with(form, 'ivo_healpix_center'))]" \
		-d "//outputFormat[not(mime='application/x-votable+xml' or mime='text/csv')]" \
		-d "//capability[not(contains(@standardID, 'capabilities') or contains(@standardID, 'TAP'))]" \
		-d "//dataModel[.='Registry 1.1']" \
	| xmlstarlet fo -o -s 2 > $DEST.tmp.$$

dachs admin xsdValidate $DEST.tmp.$$ > /dev/null || exit 1
echo '\begin{lstlisting}[basicstyle=\footnotesize,language=XML]'
sed  -e 's/xmlns\|standardID\|xsi:type/\
	&/g
/xml-stylesheet/d
s/xsi:schemaLocation="[^"]*"//
s/\(Query Language is\)[^<]*/\1.../
s/__system__\/tap\/run/tap/
' $DEST.tmp.$$ 
echo '\end{lstlisting}'
