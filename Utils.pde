// tflorez

interface Selectable {
  //Vector2f getScreenPosition();
  Vector3f getPositionVec();
  Vector3f getDisplayPositionVec();
}

interface Label {
  void setName(String name);
  String getName();
  
  void setLabel(String label);
  String getLabel();
}

class DistanceMeasurement {
  
  ISelectableLabel start, end;
  
  Vector3f difference = new Vector3f();
  Vector3f differenceInTargetCoords = new Vector3f();
  Vector3f midpoint = new Vector3f();
  Vector3f midpointDisplayPos = new Vector3f();
  Vector3f labelDisplayPos = new Vector3f();
  
  int textColor = 0xFFFFFFFF;
  
  DistanceMeasurement(ISelectableLabel start, ISelectableLabel end) {
    this.start = start;
    this.end = end;
    
    update();
  }
  
  void update() {
    
    difference.sub(end.getPositionVec(), start.getPositionVec());
    
    lorentzMatrix.transform(difference, differenceInTargetCoords);
    
    midpoint.scaleAdd(0.5, difference, start.getPositionVec());
    
    Relativity.displayTransform(lorentzMatrix, midpoint, midpointDisplayPos);
  }
  
  void drawGL(GL gl) {
    
    update();
    
    String theLabel = this.buildLabel();
    float theScale = 0.5;
    
    float labelX = screenX(midpointDisplayPos);
    float labelY = screenY(midpointDisplayPos) + height / 5f;
    labelDisplayPos = kamera.screenToModel(labelX, labelY);
    
    Vector3f startDispVec = start.getDisplayPositionVec();
    Vector3f endDispVec = end.getDisplayPositionVec();
    
    gl.glBegin(GL.GL_TRIANGLES);
      gl.glColor4f(1, 1, 1, 0);
      glVertexGL(gl, startDispVec);
      glVertexGL(gl, endDispVec);
      
      gl.glColor4f(1, 1, 1, 0.5);
      glVertexGL(gl, labelDisplayPos);
    gl.glEnd();
    
    myLabelor.setTextColor(this.textColor);
    myLabelor.drawLabelGL(gl, theLabel, labelDisplayPos, theScale);
  }
  
  String buildLabel() {
    
    String theLabel = new String(
      "Distance Measurement: \n"
      + start.getName() + " to " + end.getName()
      + "\nworld coord distance:  " + nfVec(this.difference, 1)
      + "\ntarget coord distance: " + nfVec(this.differenceInTargetCoords, 1)
      );
    
    return theLabel;
  }
}

class FanSelection extends SelectableLabel {
  
  Selectable parentSelectable;
  ArrayList selectableLabels;
  //float radius;
  
  AxisAngle4f lookAxisAngle = new AxisAngle4f(kamera.look, 0);
  Matrix4f rotLook = new Matrix4f();
  
  FanSelection(Selectable parentSelectable, List selectableLabels) {
    this.parentSelectable = parentSelectable;
    this.selectableLabels = new ArrayList(selectableLabels);
    
    if (parentSelectable instanceof Label) {
      this.setLabel( ((Label) parentSelectable).getName() );
      this.setDisplayPosition(parentSelectable.getDisplayPositionVec());
    }
    
    update();
  }
  
  void update() {
    Vector3f parentDisplayPos = parentSelectable.getDisplayPositionVec();
    Vector3f labelPos = new Vector3f();
    Vector3f radialVec = new Vector3f(kamera.up);
    
    float distToLabel = getDistance(parentDisplayPos, kamera.pos);
    
    this.setDisplayPosition(parentDisplayPos);
    
    radialVec.scale(distToLabel / 12 * selectableLabels.size());
    
    float theta =  TWO_PI / (float)(selectableLabels.size());
    
    lookAxisAngle.set(kamera.look, theta);
    rotLook.set(lookAxisAngle);
    
    for (int i=0; i<selectableLabels.size(); i++) {
      
      rotLook.transform(radialVec);
      labelPos.add(radialVec, parentDisplayPos);
      
      ((SelectableLabel)selectableLabels.get(i)).setDisplayPosition(labelPos);
    }
  }
  
  ArrayList getSelectableLabels() {
    return selectableLabels;
  }
}

interface ISelectableLabel extends Selectable, Label {
}

class PathPlaneIntersection extends SelectableLabel {
  
  Particle pathParent;
  Particle planeParent;
  
  Vector3f pos = new Vector3f();
  Vector3f displayPos = new Vector3f();
  
  PathPlaneIntersection(Particle thePathParent, Particle thePlaneParent) {
    pathParent = thePathParent;
    planeParent = thePlaneParent;
  }
  
  String getName() {
    return "Intersection\n" + "Path: " + pathParent.getName() + " / Plane:" + planeParent.getName();
  }
  
  Object getPlaneParent() {
    return planeParent;
  }
  
  Object getPathParent() {
    return pathParent;
  }
  
  void setPlaneParent(Particle thePlaneParent) {
    this.planeParent = thePlaneParent;
  }
  
  void setPathParent(Particle thePathParent) {
    this.pathParent = thePathParent;
  }
  
  Vector3f getPositionVec() {
    return pos;
  }
  
  Vector3f getDisplayPositionVec() {
    return displayPos;
  }
  
  void update() {
    pos = pathParent.getIntersection(planeParent);
    
    if (pos == null) {
      displayPos = null;
    }
    else {
      if (displayPos == null) {
        displayPos = new Vector3f();
      }
      Relativity.displayTransform(lorentzMatrix, pos, displayPos);
    }
  }
}

class SelectableLabel implements ISelectableLabel {
  
  Selectable parentSelectable;
  
  Vector2f screenPosition;
  Vector3f displayPosition;
  
  String name;
  String label;
  
  SelectableLabel(String theLabel, float theScreenX, float theScreenY) {
    screenPosition = new Vector2f();
    displayPosition = new Vector3f();
    
    setScreenPosition(theScreenX, theScreenY);
    setLabel(theLabel);
  }
  
  SelectableLabel(String theLabel, Selectable theParentSelectable) {
    this(theLabel, theParentSelectable.getDisplayPositionVec());
    this.parentSelectable = theParentSelectable;
  }
  
  SelectableLabel() {
    this("", 0, 0);
  }
  
  SelectableLabel(String theLabel, Vector3f displayPos) {
    this(theLabel, screenX(displayPos), screenY(displayPos));
  }
  
  Vector3f getPositionVec() {
    
    Vector3f position = Relativity.inverseDisplayTransform(targetParticle.velocity, this.displayPosition);
    return position;
  }
  
  Vector3f getDisplayPositionVec() {
    return this.displayPosition;
  }
  
  Vector2f getScreenPosition() {
    return this.screenPosition;
  }
  
  void setScreenPosition(float sx, float sy) {
    screenPosition.set(sx, sy);
    updateDisplayPosition();
  }
  
  void setDisplayPosition(Vector3f newPosition) {
    this.displayPosition.set(newPosition);
  }
  
  void updateDisplayPosition() {
    displayPosition = kamera.screenToModel(screenPosition.x, screenPosition.y);
  }
  
  String getLabel() {
    return label;
  }
  
  void setLabel(String label) {
    this.label = label;
  }
  
  String getName() {
    return name;
  }
  
  void setName(String name) {
    this.name = name;
  }
  
  Selectable getParentSelectable() {
    return this.parentSelectable;
  }
  
  String toString() {
    return super.toString() + ", displayPosition: " + nfVec(this.displayPosition, 1);
  }
}

class Selector extends HashSet {
  HashSet selectables;
  HashSet selection;
  HashSet hover;
  HashMap hoverAngles;
  
  float minHoverAngle = radians(10);
  float minSelectionAngle = radians(3);
  float minAngleToPreferClosest = radians(1.5);
  
  float millisLastUpdateHover;
  
  Selectable bestPick;
  float angleToBestPick;
  
  Selector (Collection theSelectables, Collection theStartingSelection) {
    this.selection = this;
    this.selectables = new HashSet(theSelectables);
    this.addAll(theStartingSelection);
    this.hover = new HashSet();
    this.hoverAngles = new HashMap();
  }
  
  Selector (Collection theSelectables) {
    this(theSelectables, new ArrayList());
  }
  
  Selector () {
    this(new ArrayList(), new ArrayList());
  }
  
  void addToSelectables (Selectable s) {
    if (s == null) { return; }
    this.selectables.add(s);
  }
  
  void addToSelectables (Collection theSelectables) {
    this.selectables.addAll(theSelectables);
    //this.selectables.removeAll(null);
  }
  
  void drop (Selectable toDrop) {
    this.selection.remove(toDrop);
    this.selectables.remove(toDrop);
  }
  
  void drop (Collection toDrop) {
    this.selection.removeAll(toDrop);
    this.selectables.removeAll(toDrop);
  }
  
  void invertSelectionStatus (Selectable theSelectable) {
    
    if (theSelectable == null) {
      return;
    }
    
    if (selection.contains(theSelectable)) {
      selection.remove(theSelectable);
    }
    else {
      selection.add(theSelectable);
    }
  }
  
  float getHoverScale(Selectable theSelectable) {
    Float hoverAngle = (Float) this.hoverAngles.get(theSelectable);
    float angle = (hoverAngle == null) ? minHoverAngle : hoverAngle;
    float hoverScale = (1 - abs(angle)/(2*minHoverAngle));
    return hoverScale;
  }
  
  Vector3f getPickDirection(Kamera kam, int theMouseX, int theMouseY) {
    Vector3f direction = new Vector3f();
    direction.sub(kam.screenToModel(theMouseX, theMouseY), kam.pos);
    return direction;  
  }
  
  void update(Kamera theKamera) {
    
    if (millis() - millisLastUpdateHover > 10) {
      updateHoverAndPick(this.selection, theKamera.pos, getPickDirection(theKamera, mouseX, mouseY));
    }
  }
  
  void updateHoverAndPick (Collection theSelectables, Vector3f cameraPos, Vector3f pickingRayDirection) {
    
    millisLastUpdateHover = millis();
    hover.clear();
    hoverAngles.clear();
    
    bestPick = null;
    angleToBestPick = PI;
    
    float distToBestPick = Float.MAX_VALUE;
        
    Vector3f cameraToSelectable = new Vector3f();
    
    for (Iterator iter=theSelectables.iterator(); iter.hasNext();) {
      Selectable p = (Selectable) iter.next();
      
      if (p == null || p.getDisplayPositionVec() == null) { continue; }
      
      cameraToSelectable.sub(p.getDisplayPositionVec(), cameraPos);
      
      float distToSelectable = cameraToSelectable.length();
      
      float angleRayToSelectable = cameraToSelectable.angle(pickingRayDirection);
      
      if ( (angleRayToSelectable < angleToBestPick) || 
           ( (angleRayToSelectable < minAngleToPreferClosest)
              && (distToSelectable < distToBestPick) ) )
      {
        distToBestPick = distToSelectable;
        angleToBestPick = angleRayToSelectable;
        bestPick = p;
      }
      
      if ( angleRayToSelectable < minHoverAngle) {
        hover.add(p);
        hoverAngles.put(p, Float.valueOf(angleRayToSelectable));
      }
    }
  }
  
  //Selectable pickPoint(Vector3f cameraPos, Vector3f pickingRayDirection) {
  Selectable pickPoint(Kamera theKamera, int theMouseX, int theMouseY) {
    
    updateHoverAndPick(this.selectables, theKamera.pos, getPickDirection(theKamera, theMouseX, theMouseY));
    println(this + "pickPoint(): bestPick: " + bestPick + " , angle: " + angleToBestPick);
    println("minSelectionAngle: " + minSelectionAngle);
    
    if (angleToBestPick < minSelectionAngle) {
      return (Selectable) bestPick;
    }
    else {
      return null;
    }
  }
}

class Labelor {
  VTextRenderer vtext;
  float lineHeight;
  
  boolean backgroundVisible = false;
  float[] backgroundColor = new float[] {0.1f, 0.1f, 0.1f, 0.9f};
  
  Labelor() {
    vtext = myVTextRenderer;
    
    // Use the highest lineHeight expected, rather than the sporadic bounds textRender gives for each string
    lineHeight = (float) vtext._textRender.getBounds("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ|()123456789!@#$%^&*").getHeight();
  }
  
  void setTextColor(int theColorARGB) {
    this.vtext.setColor(getColor4fv(theColorARGB));
  }
  
  void setBackgroundColor(int theColorARGB) {
    this.backgroundColor = getColor4fv(theColorARGB);
  }
  
  void drawLabelGL(GL gl, SelectableLabel sl, float scale) {
    drawLabelGL(gl, sl.getLabel(), sl.getDisplayPositionVec(), scale, 0f);
  }
  
  void drawLabelGL(GL gl, String msg, Vector3f position, float scale) {
    drawLabelGL(gl, msg, position, scale, -2.0f);
  }
  /*
   *  @param verticalOffset    vertical offset from the label's position on screen
   *                           (as a multiple of text lineheight)
   */
  void drawLabelGL(GL gl, String msg, Vector3f position, float scale, float verticalOffset) {
    beginCylindricalBillboardGL(position.x, position.y, position.z);
      
      //SCALE
      float unclampedScale = 0.1;
      float nearClampRatio = 0.001;
      float farClampRatio = 0.00085*scale * 1280f / width;
      
      beginDistanceScaleGL(position, kamera.pos, unclampedScale, nearClampRatio, farClampRatio);
      
      // LABEL TEXT
      String[] msgLines = msg.split("\n");
      
      for (int i=0; i<msgLines.length; i++) {
        String msgLine = msgLines[i];
        
        Rectangle2D labelRect = vtext._textRender.getBounds(msgLines[i]);
        
        float lw = (float)labelRect.getWidth();
        
        float lineOffsetY = -lineHeight * i;
        float groupOffsetY = lineHeight * verticalOffset;
        
        float lx = -(float)labelRect.getCenterX();
        float ly = -(float)labelRect.getCenterY() + lineOffsetY + groupOffsetY;
        
        drawLabelBackgroundGL(gl, lx, ly, lw, lineHeight);
        
        // RENDER LABEL
        vtext.print(msgLines[i], lx, ly, 0);
      }
      
      endDistanceScaleGL();
    endBillboardGL();
  }
  
  void drawLabelBackgroundGL(GL gl, float lx, float ly, float lw, float lh) {
    if (!backgroundVisible) { return; }
    
    gl.glColor4fv(backgroundColor, 0);
    gl.glPushMatrix();
      gl.glTranslatef(-lx, 0, 0);
      gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE_MINUS_SRC_ALPHA);
      //gl.glColor4f(0.1f, 0.1f, 0.1f, 0.5f);
      gl.glTranslatef(lx, ly, 0);
      //simpleQuadGL(gl);
      simpleQuadGL(gl, (0.5*1.2)*lw, lh);
      
      gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_DST_ALPHA);
    gl.glPopMatrix();
  }
}

// GL CONVENIENCE UTILS - COLOR
void glVertexGL(GL gl, Vector3f v) {
  gl.glVertex3f(v.x, v.y, v.z);
}

void glColorGL(GL gl, color c) {
  gl.glColor4ub((byte)((c>>16) & 0xFF), (byte)((c>>8) & 0xFF), (byte)(c & 0xFF), (byte)((c>>24) & 0xFF));
}

float[] getColor4fv(color c) {
  colorMode(RGB, 1.0f);
  
  return new float[] {
    red(c),
    green(c),
    blue(c),
    alpha(c)
  };
}

// GL CONVENIENCE UTILS - TEXTURE
void beginTextureGL(Texture tex) {
  tex.bind();
  tex.enable();
}

void endTextureGL(Texture tex) {
  tex.disable();
}

// GL CONVENIENCE UTILS - SCALING
void beginDistanceScaleGL(Vector3f objectPos, Vector3f kameraPos, float scale) {

  float s = scale * getDistance(objectPos, kameraPos);
  gl.glPushMatrix();
  gl.glScalef(s, s, s);
}

void beginDistanceScaleGL(Vector3f objectPos, Vector3f kameraPos, float scale, float nearClampRatio, float farClampRatio) {
  
  float distToKamera = getDistance(objectPos, kameraPos);
  float s = min(distToKamera * nearClampRatio, scale);
  s = max(s, distToKamera * farClampRatio);
  
  gl.glPushMatrix();
  gl.glScalef(s, s, s);
}

void endDistanceScaleGL() {
  gl.glPopMatrix();
}

//Vector3f Utils
float getDistance(Vector3f va, Vector3f vb) {
  float x = va.x - vb.x;
  float y = va.y - vb.y;
  float z = va.z - vb.z;
  return sqrt(x*x + y*y + z*z);
}

Vector3f getOffset(Vector3f from, Vector3f to) {
  return new Vector3f(to.x - from.x, to.y - from.y, to.z - from.z);
}

void scaleVectors(Vector3f[] v, float scale) {
  for (int i=0; i<v.length; i++) {
    v[i].scale(scale);
  }
}

Vector3f[] genPolygonVerticesAt(Vector3f theOffsetPos, int n) {
  
  Vector3f[] vecs = new Vector3f[n];
  for (int i=0; i<n; i++) {
    
    float theta = TWO_PI * ((float)i) / (float)n;
    float r = 5 * n;
    
    Vector3f pos = new Vector3f(cos(theta)-1, sin(theta), 0);
    pos.scaleAdd(r, pos, theOffsetPos);
    vecs[i] = pos;
    
    //Dbg.say("theta/TWO_PI, r: " + theta/TWO_PI + " " + r);
    //Dbg.say("target[" + i + "].pos: " + pos);
  }
  return vecs;
}

void offsetParticle(Vector3f theOffset, Particle p) {
  
  Vector3f newPos = new Vector3f();
  newPos.add(theOffset, p.getPositionVec());
  
  p.setPosition(newPos);
  
  Frame[] frameHist = p.frameHist;
  int numFrames = p.histCount;
  
  for (int i=0; i<numFrames; i++) {
    DefaultFrame histFrame = (DefaultFrame)frameHist[i];
    
    Vector3f newHistPos = new Vector3f();
    newHistPos.add(theOffset, histFrame.getPositionVec());
    histFrame.setPosition(newHistPos);
  }
}

void offsetParticles(Vector3f theOffset, Collection theParticles) {
  
  for (Iterator iter=theParticles.iterator(); iter.hasNext(); ) {
    Particle p = (Particle) iter.next();
    
    offsetParticle(theOffset, p);
  }
}

// MATH

/**
 * Find the remainder left from m divided by n, after an offset,
 * thus restricting the result to range (offset, offset + n).
 * 
 * Example:
 *
 * Some trig functions require the angle to be within a certain range,
 * such as (-PI, PI).
 *
 * An angle of unknown value and sign can be sanitized as follows:
 *   safeAngle = modulus(angle, TWO_PI, -PI);
 * 
 * @return    the remainder, a value from (offset) to (offset + n):
 *                (m > offset)  : offset + (m - offset) % n
 *                (m <= offset) : offset + (m - offset) % n + n
 */
double modulus(double m, double n, double offset) {

  if (m > offset) {
    return offset + (m - offset) % n;
  }
  else {
    return offset + n + (m - offset) % n;
  }
}

float logBase10(float value) {
  return (log(value) / log(10));
}

float nearestPowerOf10Below(float value) {
  return pow(10, (int)logBase10(value));
}

// STRING FORMATTING
String nfVecArray(Vector3f[] vecArray, int digits) {
  StringBuilder sb = new StringBuilder();
  
  for (int i=0; i<vecArray.length; i++) {
    sb.append(nfVec(vecArray[i], digits));
    sb.append(", \n");
  }
  return sb.toString();
}

String nfVec(Vector3f v, int digits) {
  String s = "(" + 
  nfs(v.x, digits, 1) + ", " + 
  nfs(v.y, digits, 1) + ", " + 
  nfs(v.z, digits, 1) + ")";
  
  return s;
}
String nfVec(Vector2f v, int digits) {
  String s = "(" +
    nfs(v.x, digits, 1) + ", " + 
    nfs(v.y, digits, 1) + ")";
  
  return s; 
}

float screenX (Vector3f v) {
  return screenX(v.x, v.y, v.z);
}

float screenY (Vector3f v) {
  return screenY(v.x, v.y, v.z);
}

// LOAD UTILS - FONTS
Font loadFont( byte[] fontBytes, int fontSize ){

  Font font = null;
  
  try {
    ByteArrayInputStream fontStream = new ByteArrayInputStream(fontBytes);
    font = Font.createFont(Font.TRUETYPE_FONT, fontStream);
    font = font.deriveFont((float)fontSize);
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

class FpsTimer {
  
  import org.apache.commons.math.stat.descriptive.DescriptiveStatistics;
  DescriptiveStatistics secondsPerFrameStats;
  
  float seconds, secondsLastDraw, secondsLastFpsAvg, deltaSeconds;
  float fpsRecent, prevFrameCount;
  
  FpsTimer() {
    // INIT FPS TIMING
    secondsPerFrameStats = new DescriptiveStatistics();
    secondsPerFrameStats.setWindowSize(90);
    for (int i=0; i<90; i++) { secondsPerFrameStats.addValue(1.0 / 30.0); }
    secondsLastDraw = seconds = 0.001 * millis();
  }
  
  void update() {
    secondsLastDraw = seconds;
    seconds = 0.001 * millis();
    
    secondsPerFrameStats.addValue(seconds - secondsLastDraw);
    
    deltaSeconds = seconds - secondsLastFpsAvg;
    
    if (deltaSeconds > 1) {
      fpsRecent = (frameCount - prevFrameCount) / deltaSeconds;
      secondsLastFpsAvg = seconds;
      prevFrameCount = frameCount;
    }
  }
  
  float getSecondsPerFrame() {
    return (float)secondsPerFrameStats.getMean();
  }
  float getFramesPerSecond() {
    return 1.0f / getSecondsPerFrame();
  }
}

void intervalSay(int frameInterval, String msg) {
  if (frameCount % frameInterval == 0) {
    println(msg);
  }
}

static class Dbg {
  
  static void say(String msg) {
    println(msg);
  }
  
  static void warn(String msg) {
    println("WARNING: " + msg);
  }
  
  static void dumphex(String name, int i) {
    println("hex(" + name + "): " + hex(i));
  }
  
  static void dumpStreamBytes(InputStream inputStream, int numBytes) {
    try {
      byte[] b = new byte[numBytes];
      inputStream.read(b, 0, numBytes);
      
      println("inputStream.toString(): " + inputStream.toString());
      println("inputStream Bytes[0.."+numBytes+"]:");
      
      dumpBytes(b, numBytes);
      
    }
    catch (Exception e){
      println("Error reading inputStream: ");
    }
  }
  
  static void dumpBytes(byte[] b, int numBytes){
    
    for (int i=0; i<numBytes/8; i++){
      for (int j=0; j<8; j++){
        print(" " + b[i*8+j]);
      }
      println("\t");
    }
  }
}

