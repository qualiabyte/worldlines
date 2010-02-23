// Infobox
// tflorez

class Infobar {
  
  FloatControl floatControl;
  Vector2f size, pos;
  VTextRenderer vtext;
  
  float textMarginX;
  float textMarginY;
  
  final int ABOVE = 0;
  final int INSIDE = 1;
  final int BELOW = 2;
  
  Infobar(FloatControl theFloatControl, Font theFont)  {
    
    this.floatControl = theFloatControl;
    this.size = new Vector2f(width/3.0f, height/30f);
    this.pos = new Vector2f( (width - size.x)/2f, (height - 3*size.y) );
    this.textMarginX = 0.01*size.x;
    this.textMarginY = 0.3*size.y;
    
    float fontSize = theFont.getSize();
    this.vtext = new VTextRenderer(theFont.deriveFont(11f), (int)(1*fontSize));
    this.vtext.setColor(1, 0.5, 0.6, 1);
  }
  
  Infobar(FloatControl theFloatControl) {
    this(theFloatControl, new Font("Serif", Font.TRUETYPE_FONT, 11));
  }
  
  Infobar() {
    this(new FloatControl("Infobox", 0, -100, +100));
  }
  
  void setSize(int theWidth, int theHeight) {
    this.size.set(theWidth, theHeight);
  }
  
  void setPosition(int posX, int posY) {
    this.pos.set(posX, posY);
  }
  
  void setLabel(String theLabel) {
    this.floatControl.setLabel(theLabel);
  }
  
  void draw() {
    String label = floatControl.label + ": " + buildMarkerLabel(floatControl.getValue());
    drawInfobar(label);
  }
  
  void drawInfobar(String theLabel) {
    
    // BAR
    colorMode(RGB, 255);
    color fillColor = 0xccFFEE33;
    stroke(255); noFill();
    rect(pos.x, pos.y, size.x, size.y);
    fill(fillColor);
    rect(pos.x, pos.y, size.x * barPositionOf((Float)floatControl.value), size.y);
    
    // TEXT
    drawInfobarVtext(theLabel);
    //color textColor = 0xFFFF0088;
  }
  
  void drawInfobarVtext(String theLabel) {
    
    // LABEL
    drawLabelAtPos(0, ABOVE, theLabel);
    
    // UNIT MARKS
    this.updateBounds();
    
    drawMarkerAt(floatControl.min);
    drawMarkerAt(floatControl.max);
    drawMarkerAt(floatControl.getValue(), INSIDE);
    
    float zeroToMin = barPositionOf(0) - (barPositionOf(floatControl.min));
    if (zeroToMin > 0.05) {
      drawMarkerAt(0);
    }
  }
  
  float barPositionOf(float theVal) {
    return (theVal - floatControl.min) / (floatControl.max - floatControl.min);
  }
  
  String buildMarkerLabel(float theValue) {
    return nf(theValue, 1, 2) + floatControl.unitsLabel;
  }
  
  /* @param linesOffset  Float representing number of lines below label
   *                     Optionally, use constants ABOVE, INSIDE, or BELOW here.
   */
  void drawMarkerAt(float theValue, float linesOffset) {
    drawLabelAtPos(barPositionOf(theValue), linesOffset, buildMarkerLabel(theValue));
  }
  
  void drawMarkerInsideAt(float theValue) {
    drawMarkerAt(theValue, INSIDE);
  }
  
  void drawMarkerAt(float theValue) {
    drawMarkerAt(theValue, BELOW);
  }
  
  void drawLabelAtPos(float barPositionX, float linesOffsetY, String theLabel) {
    
    vtext.print(
      theLabel,
      (int)(pos.x + (size.x * barPositionX) + textMarginX),
      (int)((height - pos.y) - (size.y * linesOffsetY) + textMarginY)
    );
  }
  
  void updateBounds() {
    floatControl.updateBounds();
    floatControl.min = min(floatControl.min, 0);
    floatControl.max = 10 * nearestPowerOf10Below((Float)floatControl.value);
  }
}

class Infobox {
  
  Infobox( String fontName, int fontSize ){
    
    init( fontSize );
    textRenderer = new VTextRenderer(fontName, fontSize);
  }
/*
  Infobox( File fontFile, int fontSize ){

    init( fontSize );
    textRenderer = new VTextRenderer( loadFont(fontFile), fontSize );
  }
*/
  Infobox( Font font, int fontSize) {//byte[] fontBytes, int fontSize ){

    init( fontSize );
    textRenderer = new VTextRenderer( font, fontSize );
  }
  
  private void init( int fontSize ){
    
    this.fontSize = fontSize;    
    xOffset = yOffset = (int)(0.5 * fontSize);
    infolines = new Infoline[maxlines];
  }
  
  Infoline addLine( String text ) {
  
      return infolines[numlines++] = new Infoline(text);
  }
  
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

// Infoline
// tflorez

class Infoline {

  Infoline() {
    text = "";
  }
  
  Infoline( String text ) {
    this.text = text;
  }
  
  void setText( String text ) {
    this.text = text;
  }
  
  String toString() {
    return text;
  }
  
  String text;
}

/*
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
*/

