# ivoatex Makefile.  The ivoatex/README for the targets available.

SCHEMA_FILE=TAPRegExt-v1.1.xsd

# short name of your document (edit $DOCNAME.tex; would be like RegTAP)
DOCNAME = TAPRegExt

# count up; you probably do not want to bother with versions <1.0
DOCVERSION = 1.1

# Publication date, ISO format; update manually for "releases"
DOCDATE = 2015-11-17

# What is it you're writing: NOTE, WD, PR, or REC
DOCTYPE = WD

# Source files for the TeX document (but the main file must always
# be called $(DOCNAME).tex

SOURCES = $(DOCNAME).tex $(SCHEMA_FILE) sample.xml gitmeta.tex role_diagram.pdf

# List of image files to be included in submitted package (anything that
# can be rendered directly by common web browsers)
FIGURES = role_diagram.svg

# List of PDF figures (for vector graphics)
VECTORFIGURES =


# Additional files to distribute (e.g., CSS, schema files, examples...)
AUX_FILES = $(SCHEMA_FILE) sample.xml

-include ivoatex/Makefile

sample.xml: make-sample.sh
	./make-sample.sh

install:
	# local to Markus' setup
	~/gavo/standards/fixschema $(SCHEMA_FILE) > ~/gavo/trunk/gavo/resources/schemata/TAPRegExt.xsd

STILTS ?= stilts
SCHEMA_FILE=TAPRegExt-v1.1.xsd

# These tests need stilts >3.4 and xmlstarlet
test:
	@sh test-assertions.sh
	@$(STILTS) xsdvalidate $(SCHEMA_FILE)
	@$(STILTS) xsdvalidate \
		schemaloc="http://www.ivoa.net/xml/TAPRegExt/v1.0=$(SCHEMA_FILE)" \
		schemaloc="http://www.ivoa.net/xml/VOSICapabilities/v1.0=https://www.ivoa.net/xml/VOSICapabilities/v1.0" \
		schemaloc="http://www.ivoa.net/xml/VODataService/v1.1=https://www.ivoa.net/xml/VODataService/v1.1" \
		doc=sample.xml
