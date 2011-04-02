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

web: applet applet-required
	@if [ -d web/applet ]; then \
		echo "Copying additional jars for applet"; \
		cp web/applet-required/* web/applet/; \
	fi

applet:
	@if [ ! -d applet ]; then \
		echo "Please export the applet with Processing before building the web presentation"; \
		echo "    ('applet' dir is missing, so 'web/applet' link is broken)"; \
	fi

applet-required:


clean:
	(cd $(DOC_DIR); rm $(HANDBOOK_PDF))

