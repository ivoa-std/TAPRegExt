schemaFile=TAPRegExt-v1.0.xsd 

.DELETE_ON_ERROR:

spec.html: $(schemaFile) spec.xsl
	xalan -qc -in $< -xsl spec.xsl -out $@

spec.xsl: $(schemaFile) sample.xml spec.xsl.in
		sed -e '/^<.-- INCLUDESAMPLE -->/r sample.xml' $@.in\
		| sed -e "/^<.-- INCLUDESAMPLE -->/d;\
			/^<.-- INCLUDESCHEMA -->/r "$(schemaFile) \
		| sed -e '/^<.-- INCLUDESCHEMA -->/d' > $@

sample.xml: dumprecord.py
	# this rule probably only works of you have GAVO DaCHS installed,
	# built the validator in (source_dir)schemata, and adjusted xsdclasspath
	# in DaCHS' config.
	python $< > $@.tmp
	java -cp `gavo config xsdclasspath` xsdval -n -v -s -f $@.tmp
	# some cosmetics on the namespace and schema location
	sed -e 's/xmlns\|standardID\|xsi:type/~  &/g;s/xsi:schemaLocation="[^"]*"//' $@.tmp \
		| tr '~' '\n  ' > $@
	rm $@.tmp
	
install:
	scp $(schemaFile) alnilam:/var/www/docs/schemata


