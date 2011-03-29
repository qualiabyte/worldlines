DOC_DIR = doc

HANDBOOK_LYX = Worldlines\ Handbook.lyx
HANDBOOK_PDF = Worldlines\ Handbook.pdf

HANDBOOK_SRC = $(DOC_DIR)/$(HANDBOOK_LYX)
HANDBOOK_OUT = $(DOC_DIR)/$(HANDBOOK_PDF)

all: doc

doc: handbook_pdf

handbook_pdf: $(HANDBOOK_OUT)

$(HANDBOOK_OUT): $(HANDBOOK_SRC)
	(cd $(DOC_DIR); lyx --export pdf $(HANDBOOK_LYX))

clean:
	(cd $(DOC_DIR); rm $(HANDBOOK_PDF))

