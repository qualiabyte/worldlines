// Infobox
// tflorez

class Action {
  void doAction() {}
}

interface IToggleVisible {
  void toggleVisible();
  boolean isVisible();
  void setVisible(boolean b);
}

class ToggleVisibleAction extends Action {
  
  IToggleVisible target;
  
  ToggleVisibleAction(IToggleVisible target) {
    this.target = target;
  }
  
  ToggleVisibleAction() {
    this(null);
  }
  
  void doAction() {
    this.target.toggleVisible();
  }
}

class Infopane implements IToggleVisible {
  
  VTextRenderer vtext;
  Vector2f padding;
  Vector2f size, pos;
  Vector2f lineSize;
  
  Action clickAction = null;
  
  boolean isClickable = false;
  boolean isVisible = true;
  boolean isBackgroundVisible = true;
  
  color backgroundColor = 0xcc000000;
  color foregroundColor = 0xffffffff;
  
  Infopane(Vector2f size, Vector2f pos, VTextRenderer vtext) {
    this.padding = new Vector2f(10, 10);
    this.size = size;
    this.pos = pos;
    this.vtext = vtext;
    this.lineSize = new Vector2f(this.size.x, 1.5 * vtext._fontSize);
  }
  
  Infopane(Vector2f size, Vector2f pos, Font theFont) {
    this( size, pos, new VTextRenderer(theFont, theFont.getSize()) );
  }
  
  Infopane(Vector2f size, Vector2f pos) {
    this(size, pos, new Font("Monospace", Font.TRUETYPE_FONT, 14));
    //this(size, pos, loadFont(loadBytes(bundledFont), 14));
  }
  
  Infopane(Font theFont) {
    this(new Vector2f(), new Vector2f(), theFont);
  }
  
  Infopane() {
    //this(new Font("Monospace", Font.TRUETYPE_FONT, 14));
    this(loadFont(loadBytes(bundledFont), 14));
  }
  
  /* Expect derived classes to override */
  void draw() {
    if (! this.isVisible) { return; }
    
    drawBackground(this.backgroundColor);
  }
  
  void doClickAction() {
    if (this.clickAction != null) {
      clickAction.doAction();
    }
  }
  
  boolean isMouseOver() {
    /*
    Dbg.say("isMouseOver() " + this + "\n  pos: " + pos.x + ", " + pos.y
      + "size: " + size.x + ", " + size.y );
    */
    return ( mouseX > pos.x && mouseX < pos.x + size.x 
          && mouseY > pos.y && mouseY < pos.y + size.y );
  }
  
  void setClickAction(Action theAction) {
    this.isClickable = true;
    this.clickAction = theAction;
  }
  
  boolean isVisible() {
    return this.isVisible;
  }
  void setVisible(boolean b) {
    this.isVisible = b;
  }
  void toggleVisible() {
    this.setVisible( ! this.isVisible() );
  }
  
  void drawBackground(color theBackgroundColor) {
    if (! this.isBackgroundVisible) { return; }
    
    gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE_MINUS_SRC_ALPHA);
    
    stroke(foregroundColor);
    fill(theBackgroundColor);
    rect(pos.x, pos.y, size.x, size.y);
  }
  
  void useLightOnDark() {
    backgroundColor = 0xee000000;
    foregroundColor = 0xeeffffff;
  }
  
  void useDarkOnLight() {
    backgroundColor = 0xeeffffff;
    foregroundColor = 0xee000000;
  }
}

class Infopanel extends Infopane {
  
  // FLOW CONSTANTS FOR ADDING PANELS (NO ENUM IN P5)
  static final int DOWNWARD = 0;
  static final int RIGHTWARD = 1;
  int flow = DOWNWARD;
  
  List infopanes = new ArrayList();
  
  Infopanel(Infopane thePane) {
    super(thePane.size, thePane.pos, thePane.vtext);
  }
  
  Infopanel() {
    super(
      new Vector2f(width/2, height*0.9),
      new Vector2f( (width - width/2)/2, (3*FONT_SIZE)),//height - (lineSize.y + 2*padding.y)) ),//height*0.9)/2 ),
      //new VTextRenderer(new Font("Monospace", Font.TRUETYPE_FONT, 14), 14)
      new VTextRenderer(loadFont(loadBytes(bundledFont), 14), 14)
      );
  }
  
  Infoline addLine(String theText) {
    
    Infoline theLine = new Infoline(this, theText);
    if (flow == RIGHTWARD) {
      theLine.size.x = theLine.getRenderWidth() + this.padding.x;
    }
    addPane(theLine);
    return theLine;
  }
  
  void addPane(Infopane thePane) {
    
    positionPaneByFlow(thePane);
    this.infopanes.add(thePane);
  }
  
  Infopane getLastPane() {
    
    return (infopanes.isEmpty()) ? null : (Infopane) infopanes.get(infopanes.size() - 1);
  }
  
  void positionPaneByFlow(Infopane thePane) {
    
    positionPaneByFlow(thePane, this.flow);
  }
  
  void positionPaneByFlow(Infopane thePane, int theFlow) {
    
    Infopane lastPane = this.getLastPane();
    
    if (lastPane == null) {
      thePane.pos.set(this.pos);
      thePane.pos.add(this.padding);
    }
    else {
      if (flow == DOWNWARD) {
        thePane.pos.set(this.pos.x + this.padding.x, lastPane.pos.y + lastPane.size.y);
      }
      else if (flow == RIGHTWARD) {
        thePane.pos.set(lastPane.pos.x + lastPane.size.x, lastPane.pos.y);
      }
    }
  }
  
  void setFlow(int theFlow) {
    this.flow = theFlow;
  }
  
  void draw() { //intervalSay(90, "  drawPanel(): " + this);
    if (! this.isVisible) { return; }
    
    this.drawBackground(backgroundColor);
    this.drawPanes();
  }
  
  void drawPanes() {
    
    for (Iterator iter = infopanes.iterator(); iter.hasNext();) {
      Infopane thePane = (Infopane) iter.next();
      
      int xPos = (int)thePane.pos.x;
      int yPos = (int)(height - thePane.pos.y - 0.8*thePane.size.y);
      
      if (thePane instanceof Infoline) {
        Infoline theLine = (Infoline) thePane;
        
        if (theLine.isClickable && theLine.isMouseOver()) {
          
          // INDICATE ACTION IF MOUSEOVER CLICKABLE
          theLine.drawBackground(ACTION_COLOR);
          
          vtext.setColor(ACTION_COLOR_CONTRAST);
          vtext.print(theLine.toString(), xPos, yPos);
          
          // RESET COLOR
          vtext.setColor(getColor4fv(foregroundColor));
        }
        else {
          // OTHERWISE JUST DRAW
          vtext.print(theLine.toString(), xPos, yPos);
        }
      }
    }
  }
  
  Infopane getClickedPane() {
    if (!this.isVisible) { return null; }
    
    Dbg.say("getClicked(): " + this);
    
    for (Iterator iter = infopanes.iterator(); iter.hasNext();) {
      Infopane thePane = (Infopane) iter.next();
      /*
      Dbg.say("  thePane: " + thePane
          + "\n  isVisible: " + thePane.isVisible + "\n  isClickable: " + thePane.isClickable
          + "\n  isMouseOver: " + thePane.isMouseOver() );
      */
      if (thePane.isVisible && thePane.isClickable && thePane.isMouseOver()) {
        return thePane;
      }
    }
    return null;
  }
}

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
    
    this.vtext = new VTextRenderer(theFont.deriveFont(fontSize), (int)fontSize);
    this.vtext.setColor(1, 0.5, 0.6, 1);
  }
  
  Infobar(FloatControl theFloatControl) {
    this(theFloatControl, new Font("Sans-Serif", Font.TRUETYPE_FONT, FONT_SIZE));
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

class Infobox extends Infopane {
  
  Infoline[] infolines;
  
  int numlines = 0;
  int maxlines = 10;
  
  Infobox( Font font ) {
    super(font);
  }
  
  Infoline addLine( String text ) {
    return infolines[numlines++] = new Infoline(text);
  }
  
  void print( String text ) {
    if (!this.isVisible()) { return; }
    
    int xOffset = (int)this.pos.x;
    int yOffset = (int)this.pos.y;
    
    String[] lines = split(text, "\n");
        
    for (int i=0; i < lines.length; i++) {
      vtext.print( lines[i], xOffset, (int)( yOffset + (lines.length - i - 0.5) * lineSize.y ));
    }
  }
  
  void draw() {
    for (int i=0; i < numlines; i++) {
        vtext.print( infolines[i].toString(), (int)pos.x, (int)(pos.y + (0.5 + i) * lineSize.y) );
    }
  }
}

class Infoline extends Infopane {
  
  String text;
  
  Infoline (Infopane theParent, String theText) {
    super(new Vector2f(theParent.size.x - 2 * theParent.padding.x, theParent.lineSize.y),
      new Vector2f(0, 0),
      theParent.vtext
      );
    this.text = theText;
    this.isVisible = true;
  }
  
  Infoline() {
    this("");
  }
  
  Infoline( String theText ) {
    this( new Infopane(), theText );
  }
  
  void setText( String text ) {
    this.text = text;
  }
  
  float getRenderWidth() {
    return (float) vtext._textRender.getBounds(this.toString()).getWidth();
  }
  
  String toString() {
    return text;
  }
}

