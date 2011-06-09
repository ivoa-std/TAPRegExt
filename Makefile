schemaFile=TAPRegExt-v1.0.xsd 

.DELETE_ON_ERROR:

default:
	@echo "Document building is now done through ant"

sample.xml: dumprecord.py
	# this rule probably only works of you have GAVO DaCHS installed,
	# built the validator in (source_dir)schemata, and adjusted xsdclasspath
	# in DaCHS' config.
	python $< > $@.tmp
	java -cp `gavo config xsdclasspath` xsdval -n -v -s -f $@.tmp
	# some cosmetics on the namespace and schema location
	sed -e 's/xmlns\|standardID\|xsi:type/~  &/g;s/xsi:schemaLocation="[^"]*"//' $@.tmp \
		| tr '~' '\n  ' > $@
#	rm $@.tmp
	
install:
	scp $(schemaFile) alnilam:/var/www/docs/schemata

install-doc: spec.html
	scp spec.html TAPRegExt-arch.png alnilam:/var/www/docs/tre/
