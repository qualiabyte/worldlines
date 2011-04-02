DOC_DIR = doc

HANDBOOK_LYX = Worldlines\ Handbook.lyx
HANDBOOK_PDF = Worldlines\ Handbook.pdf

HANDBOOK_SRC = $(DOC_DIR)/$(HANDBOOK_LYX)
HANDBOOK_OUT = $(DOC_DIR)/$(HANDBOOK_PDF)

all: doc web

doc: handbook_pdf

handbook_pdf: $(HANDBOOK_OUT)

$(HANDBOOK_OUT): $(HANDBOOK_SRC)
	(cd $(DOC_DIR); lyx --export pdf $(HANDBOOK_LYX))

web: applet applet-required applications
	@if [ -d web/applet ]; then \
		echo "Copying additional jars for applet"; \
		cp web/applet-required/* web/applet/; \
	fi

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

clean:
	(cd $(DOC_DIR); rm $(HANDBOOK_PDF))

