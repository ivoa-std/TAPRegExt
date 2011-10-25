STDNAME=tapregext
DOCVERSION=1.0
PUBSTATUS=WD
# $(WD)-$(STDNAME)-$(VERSION)-$(DATE).html

SCHEMA_FILE=TAPRegExt-v1.0.xsd 

# You probably want to configure your system so the following works
SAXON=saxonb-xslt
FOP=FOP_HYPHENATION_PATH=./fop-hyph.jar fop
HTMLSTYLE=ivoadoc/ivoarestructure.xslt
FOSTYLE=ivoadoc/ivoa-fo.xsl

# You should not need to edit anything below this line

%-fmt.html: %.html $(HTMLSTYLE)
	$(SAXON) -o $@ $< $(HTMLSTYLE) docversion=$(DOCVERSION) pubstatus=$(PUBSTATUS)

%.fo: %-fmt.html
	$(SAXON) -o $@ $< $(FOSTYLE) docversion=$(DOCVERSION) pubstatus=$(PUBSTATUS)

%.pdf: %.fo
	$(FOP) -pdf $@ -fo $<


default: $(STDNAME)-fmt.html

clean:
	rm -f $(PUBSTATUS)-$(STDNAME)-*.html
	rm -f $(PUBSTATUS)-$(STDNAME)-*.pdf
	rm -f $(STDNAME).pdf

# Local stuff
tapregext-fmt.html: sample.xml $(SCHEMA_FILE)

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
	# local to Markus' setup
	fixschema $(SCHEMA_FILE) |\
		ssh alnilam "cat > /var/www/docs/schemata/$(SCHEMA_FILE)"

install-doc: spec.html
	scp spec.html TAPRegExt-arch.png alnilam:/var/www/docs/tre/
