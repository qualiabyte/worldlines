#!/bin/bash

# CSS file to include with fixes for Handbook XHTML
CSSFILE="worldlines-handbook-fixes.css"

# HTML to be inserted for CSS Fix
CSS_INCLUDE="
<!-- Begin Fixes -->

<link rel='stylesheet' href='${CSSFILE}' type='text/css' />

<!-- End Fixes-->
"

usage () {
    echo "Usage: $0 <file-to-filter.html> <output-file-name>"
}

if [[ $# -eq 2 ]]; then

    INFILE="$1"
    OUTFILE="$2"

    TMPFILE="tmp.fix-lyx-html"

    if [[ -f "$INFILE" ]]; then

        cp "$INFILE" "$TMPFILE"

        # Simplify image names produced by LYX
        perl -p -i -e 's/media_Elements.*(ima)?ges_(.*.png)/$2/' "${TMPFILE}"

        # Fix title
        perl -p -i -e 's#(<title>.*</title>)#<title>Worldlines Handbook</title>#' "$TMPFILE"

        # Add Css fixes after title
        perl -p -i -e "s#(<title>.*</title>)#\$1\n${CSS_INCLUDE}#" "$TMPFILE"

        # Move tmpfile to outfile
        mv "$TMPFILE" "$OUTFILE"

    else
        echo "!! Missing file: ${INFILE}"
    fi
else
    usage
    exit 1;
fi

