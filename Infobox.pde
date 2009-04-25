class Infobox {
  
  Infobox( String fontName, int fontSize ){
    
    this.fontSize = fontSize;
    infolines = new Infoline[maxlines];
    textRenderer = new VTextRenderer(fontName, fontSize);

    xOffset = yOffset = (int)(0.5 * fontSize);
  }
  
  Infoline addLine( String text ){
  
      return infolines[numlines++] = new Infoline(text);
  };
  
  void print( String text ) {
    
    String[] lines = split(text, "\n");
        
    for (int i=0; i < lines.length; i++) {
      textRenderer.print( lines[i], xOffset, yOffset + (int)(0.5 + i) * fontSize);
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
