# ivoatex Makefile.  The ivoatex/README for the targets available.

SCHEMA_FILE=TAPRegExt-v1.0.xsd 

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
AUX_FILES = $(SCHEMA_FILE)


sample.xml: samplegroom.sed Makefile
	# this rule only works if there's a (proper) TAP service on
	# http://localhost:8080/tap
	curl -s http://dc.zah.uni-heidelberg.de/__system__/tap/run/tap/capabilities \
		| xmlstarlet ed -d "//languageFeatures[@type='ivo://ivoa.net/std/TAPRegExt#features-udf']/feature[not(starts-with(form, 'ivo_hashlist_has'))]" \
		  -d "//languageFeatures[@type='ivo://org.gavo.dc/std/exts#extra-adql-keywords']/feature[not(starts-with(form, 'MOC'))]" \
		  -d "//outputFormat[not(@ivo-id or mime='text/csv')]" \
		  -d "//capability[@standardID='ivo://ivoa.net/std/VOSI#availability']" \
		  -d "//dataModel[@ivo-id='ivo://org.gavo.dc/std/glots#tables-1.0']" \
		| xmlstarlet fo > $@.tmp
	gavo admin xsdValidate $@.tmp
	sed -f samplegroom.sed $@.tmp > $@
	rm $@.tmp
	
-include ivoatex/Makefile

install:
	# local to Markus' setup
	fixschema $(SCHEMA_FILE) > ~/gavo/trunk/schemata/TAPRegExt.xsd

ivoatex/Makefile:
	@echo "*** ivoatex submodule not found.  Initialising submodules."
	@echo
	git submodule update --init
