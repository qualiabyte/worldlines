
# LYX_2
#
# With Lyx-2.0, XHTML output is possible
# Set this if you have lyx 2.0+ in a non-default location
# (If your default lyx is above 2.0, just leave this unset)
#
# LYX_2 = /home/qualiabyte/apps/lyx-2.0.0rc3/src/lyx

ifdef LYX_2
  LYX = $(LYX_2)
else
  LYX = $(shell which lyx)
endif

DOC_DIR = doc

HB = Worldlines\ Handbook
HANDBOOK_LYX   = $(HB).lyx
HANDBOOK_PDF   = $(HB).pdf
HANDBOOK_XHTML = $(HB).xhtml
HANDBOOK_XHTML_FIXED = $(HB)\ \(fixed\).xhtml

HANDBOOK_SRC = $(DOC_DIR)/$(HANDBOOK_LYX)
HANDBOOK = $(DOC_DIR)/$(HANDBOOK_PDF)

HANDBOOK_PRODUCTS = doc/$(HANDBOOK_PDF) \
	doc/html/$(HANDBOOK_XHTML) \
	doc/html/$(HANDBOOK_XHTML_FIXED)

WEB_ZIP = worldlines.web.zip

APP_ZIPS = web/worldlines.linux.zip \
           web/worldlines.macosx.zip \
           web/worldlines.windows.zip

PRODUCTS = $(HANDBOOK_PRODUCTS) $(WEB_ZIP) $(APP_ZIPS)

all: doc web

doc: handbook_pdf handbook_xhtml

handbook_pdf: $(HANDBOOK)

$(HANDBOOK): $(HANDBOOK_SRC)
	cd $(DOC_DIR); $(LYX) --export pdf $(HANDBOOK_LYX)

handbook_xhtml: $(HANDBOOK_SRC)
	LYX="$(LYX)"; \
	LYX_VERSION=`$$LYX --version 2>&1| grep -P 'LyX \d+.\d+.\d+' |sed 's/LyX \([0-9]\+\).*/\1/'`; \
	if [ $$LYX_VERSION -lt 2 ]; then \
		echo "!!  Warning, LyX version is < 2.0 (found major version: $${LYX_VERSION})"; \
	fi; \
	if [ -x $$LYX ]; then \
		cd $(DOC_DIR); \
		$$LYX --export xhtml $(HANDBOOK_LYX); \
		mv $(HANDBOOK_XHTML) html/; \
		rm *.png; \
		cd html; \
		./fix-lyx-xhtml.sh $(HANDBOOK_XHTML) $(HANDBOOK_XHTML_FIXED); \
	else \
		echo "!!  Missing: $$LYX"; \
	fi;

web: applet applet-required applications
	@if [ -d web/applet ]; then \
		echo "Copying additional jars for applet"; \
		cp web/applet-required/* web/applet/; \
	fi; \
	echo "Creating package: $(WEB_ZIP)"; \
	zip --quiet -r $(WEB_ZIP) web \
	    --exclude '*~' web/applet-required/\* web/doc/\* web/handbook-html/\*sized/\*;

applet:
	@if [ ! -d applet ]; then \
		echo "!!  Missing 'applet'"; \
		echo "!!    (Please export the applet with Processing before building the web presentation)"; \
	fi

applet-required:

applications:
	@for os in "linux" "macosx" "windows"; do \
		appdir="application.$$os"; \
		if [ -d $$appdir ]; then \
			pkg="web/worldlines.$$os.zip"; \
			if [ $$pkg -nt $$appdir ]; then break; \
			else \
				echo "Creating package: $$pkg"; \
				zip --quiet -r $$pkg $$appdir; \
			fi; \
		else \
			echo "!!  Missing: '$$appdir'"; \
			echo "!!    (Please export as application with Processing so it can be packaged)"; \
		fi; \
	done

clean: clean_pngs
	-rm $(PRODUCTS);

clean_pngs:
	-rm doc/*.png;

