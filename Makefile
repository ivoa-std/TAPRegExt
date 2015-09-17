# ivoatex Makefile.  The ivoatex/README for the targets available.

SCHEMA_FILE=TAPRegExt-v1.0.xsd 

# short name of your document (edit $DOCNAME.tex; would be like RegTAP)
DOCNAME = TAPRegExt

# count up; you probably do not want to bother with versions <1.0
DOCVERSION = 1.1

# Publication date, ISO format; update manually for "releases"
DOCDATE = 2015-10-15

# What is it you're writing: NOTE, WD, PR, or REC
DOCTYPE = WD

# Source files for the TeX document (but the main file must always
# be called $(DOCNAME).tex
SOURCES = $(DOCNAME).tex $(SCHEMA_FILE) sample.xml

# List of pixel image files to be included in submitted package 
FIGURES = TAPRegExt-arch.png

# List of PDF figures (for vector graphics)
VECTORFIGURES = 


# Additional files to distribute (e.g., CSS, schema files, examples...)
AUX_FILES = $(SCHEMA_FILE)


include ivoatex/Makefile

sample.xml: dumprecord.py
	# this rule only works of you have GAVO DaCHS installed.
	python $< > $@.tmp
	# some cosmetics on the namespace and schema location, plus remove the
	# old, invalid upload method URIs
	gavo admin xsdValidate sample.xml
	sed -e 's/xmlns\|standardID\|xsi:type/~  &/g;s/xsi:schemaLocation="[^"]*"//' $@.tmp \
		| grep -v "ivo://ivoa.org/tap/uploadmethods" \
		| tr '~' '\n  ' > $@
#	rm $@.tmp
	
install:
	# local to Markus' setup
	fixschema $(SCHEMA_FILE) > ~/gavo/trunk/schemata/$(SCHEMA_FILE)
