# Makefile to drive ivoadoc.
#
# To use this, you must have checked out ivoadoc as svn:externals into
# your document directory.  Copy this Makefile into that directory and
# edit it as necessary.
#
# The Makefile assumes you have xalanb-xslt and fop in your path.  On
# Debian-derived systems, you could say
#
# sudo aptitude install xalan fop w3c-dtd-xhtml
#
# You most likely want the hyphenation patterns for fop (the PDF
# formatter), too.  Presumably for licensing reasons, you have to 
# get them manually from http://offo.sourceforge.net.  Drop them
# into your working directory as fop-hyph.jar.
#
# Edit your source as $(STDNAME).html; available targets then are:
#
# * default: format the html, expanding the magic things explained in
#   README
# * $(STDNAME).pdf: same, but make a pdf
# * package: package the docs, css, all pngs and whatever is in
#   PACKAGE_EXTRAS into an aptly-named zip that expands into a
#   nicely-named subdirectory.
#
# Contact for this Makefile: Markus Demleitner (gavo@ari.uni-heidelberg.de)
#
# Fix (and maintain, as you go on) the following set of variables:
#
# The base name of the files (a sensible abbreviation of your standard's 
# title; this is case sensitive)
STDNAME=TAPRegExt
# The current version
DOCVERSION=1.0
# YYYYMMDD of the current release
DOCDATE=20120827
# One of NOTE, WD, PR, REC
PUBSTATUS=REC
# Extra files that need to end up in the final package
# (pngs are included automatically)
PACKAGE_EXTRAS=TAPRegExt-v1.0.xsd tre-vor.xml


# You probably want to configure your system so the following works
# Basically, RESOLVERJAR must eventally point to a jar of apache
# xml commons resolver, and SAXONJAR to a jar containing saxon-b
#
# This stuff should work for Debian, except you'll need to download
# fop-hyph.jar into ivoadoc,
# see http://offo.sourceforge.net/hyphenation/fop-stable/installation.html
#
# For Debian Squeeze, you need to install the backported fop to make
# this work.

CATALOG=ivoadoc/xmlcatalog/catalog.xml
JARROOT=/usr/share/java
RESOLVERJAR=$(JARROOT)/xml-commons-resolver-1.1.jar
SAXONJAR=$(JARROOT)/saxonb.jar
SAXON=java -cp $(RESOLVERJAR):$(SAXONJAR) \
	-Dxml.catalog.files=$(CATALOG) -Dxml.catalog.verbosity=1\
	net.sf.saxon.Transform\
	-novw -r org.apache.xml.resolver.tools.CatalogResolver\
	-x org.apache.xml.resolver.tools.ResolvingXMLReader\
	-y org.apache.xml.resolver.tools.ResolvingXMLReader

# TODO: make fop use our custom catalog
FOP=FOP_HYPHENATION_PATH=./fop-hyph.jar fop -catalog

HTMLSTYLE=ivoadoc/ivoarestructure.xslt
FOSTYLE=ivoadoc/ivoa-fo.xsl

# You should not need to edit anything below this line

versionedName:=$(PUBSTATUS)-$(STDNAME)-$(DOCVERSION)
ifneq "$(PUBSTATUS)" "REC"
		versionedName:=$(versionedName)-$(subst -,,$(DOCDATE))
endif

.PHONY: package

%-fmt.html: %.html $(HTMLSTYLE)
	$(SAXON) -o $@ $< $(HTMLSTYLE) docdate=$(DOCDATE)\
		docversion=$(DOCVERSION) pubstatus=$(PUBSTATUS) ivoname=$(STDNAME)

%.fo: %-fmt.html
	$(SAXON) -o $@ $< $(FOSTYLE) docdate=$(DOCDATE)\
		docversion=$(DOCVERSION) pubstatus=$(PUBSTATUS) ivoname=$(STDNAME)

%.pdf: %.fo
	$(FOP) -pdf $@ -fo $<


default: $(STDNAME)-fmt.html

package: $(STDNAME)-fmt.html $(STDNAME).pdf
	rm -rf -- $(versionedName)
	mkdir $(versionedName)
	cp $(STDNAME)-fmt.html $(versionedName)/$(versionedName).html
	cp $(STDNAME).pdf $(versionedName)/$(versionedName).pdf
	mkdir $(versionedName)/ivoadoc
	cp ivoadoc/*.css $(versionedName)/ivoadoc
	cp *.png $(SCHEMA_FILE) $(PACKAGE_EXTRAS) $(versionedName)
	zip -r $(versionedName).zip $(versionedName)
	rm -rf -- $(versionedName)

clean:
	rm -f $(PUBSTATUS)-$(STDNAME)-*.html
	rm -f $(PUBSTATUS)-$(STDNAME)-*.pdf
	rm -f $(STDNAME).pdf
	rm -r $(PUBSTATUS)-$(STDNAME)*.zip

# Local stuff
SCHEMA_FILE=TAPRegExt-v1.0.xsd 

TAPRegExt-fmt.html: sample.xml $(SCHEMA_FILE)

sample.xml: dumprecord.py
	# this rule probably only works of you have GAVO DaCHS installed,
	# built the validator in (source_dir)schemata, and adjusted xsdclasspath
	# in DaCHS' config.
	python $< > $@.tmp
	java -cp `gavo config xsdclasspath` xsdval -n -v -s -f $@.tmp
	# some cosmetics on the namespace and schema location, plus remove the
	# old, invalid upload method URIs
	sed -e 's/xmlns\|standardID\|xsi:type/~  &/g;s/xsi:schemaLocation="[^"]*"//' $@.tmp \
		| grep -v "ivo://ivoa.org/tap/uploadmethods" \
		| tr '~' '\n  ' > $@
#	rm $@.tmp
	
install:
	# local to Markus' setup
	fixschema $(SCHEMA_FILE) > ~/gavo/trunk/schemata/$(SCHEMA_FILE)

install-doc: spec.html
	scp spec.html TAPRegExt-arch.png alnilam:/var/www/docs/tre/
