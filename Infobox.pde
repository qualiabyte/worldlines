class Infobox {
  
  Infobox( String fontName, int fontSize ){
    
    init( fontSize );
    textRenderer = new VTextRenderer(fontName, fontSize);
  }

  Infobox( File fontFile, int fontSize ){

    init( fontSize );
    textRenderer = new VTextRenderer( loadFont(fontFile), fontSize );
  }
    
  private void init( int fontSize ){
    
    this.fontSize = fontSize;    
    xOffset = yOffset = (int)(0.5 * fontSize);
    infolines = new Infoline[maxlines];
  }
  
  private Font loadFont( File fontFile ){

    Font font = null;
    
    try {
      FileInputStream fontStream = new FileInputStream(fontFile);
      font = Font.createFont(Font.TRUETYPE_FONT, fontStream);
      font = font.deriveFont((float)fontSize );
    }
    catch (FontFormatException e) {
      println(e.getMessage());
    }
    catch (IOException e) {
      println(e.getMessage());
    }
    finally {
      if (font==null) {
        font = new Font("Sans-Serif", Font.PLAIN, fontSize);
      }
    }
    return font;
  }
  
  Infoline addLine( String text ) {
  
      return infolines[numlines++] = new Infoline(text);
  };
  
  void print( String text ) {
    
    String[] lines = split(text, "\n");
        
    for (int i=0; i < lines.length; i++) {
      textRenderer.print( lines[i], xOffset, yOffset + (int)(lines.length - i - 0.5) * fontSize);
    }
  }
  
  void draw() {
    
    for (int i=0; i < numlines; i++) {
        textRenderer.print( infolines[i].toString(), xOffset, yOffset + (int)(0.5 + i) * fontSize);
    }
  }

  VTextRenderer textRenderer;

  int fontSize;
  
  int xOffset, yOffset;
  
  Infoline[] infolines;
  int numlines = 0;
  int maxlines = 10;
}

