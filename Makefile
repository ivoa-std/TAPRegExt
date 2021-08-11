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


include ivoatex/Makefile

sample.xml: samplegroom.sed Makefile
	# this rule only works if there's a (proper) TAP service on
	# http://localhost:8080/tap
	curl -s http://dc.zah.uni-heidelberg.de/__system__/tap/run/tap/capabilities \
		| xmlstarlet ed -d "//feature[starts-with(form, 'ivo_apply_pm')]" \
			-d "//feature[starts-with(form, 'gavo_to_jd')]" \
			-d "//feature[starts-with(form, 'gavo_to_mjd')]" \
			-d "//feature[starts-with(form, 'ivo_hashlist_has')]" \
			-d "//feature[starts-with(form, 'ivo_nocasematch')]" \
			-d "//feature[starts-with(form, 'ivo_hasword')]" \
		| xmlstarlet fo > $@.tmp
#	gavo admin xsdValidate $@.tmp
	sed -f samplegroom.sed $@.tmp > $@
#	rm $@.tmp
	
install:
	# local to Markus' setup
	fixschema $(SCHEMA_FILE) > ~/gavo/trunk/schemata/$(SCHEMA_FILE)
