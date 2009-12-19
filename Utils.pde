// tflorez

interface Selectable {
  //Vector2f getScreenPosition();
  Vector3f getDisplayPositionVec();
}

interface Label {
  void setLabel(String label);
  String getLabel();
}

class FanSelection extends SelectableLabel {
  
  Selectable parentSelectable;
  ArrayList selectableLabels;
  float radius;
  
  AxisAngle4f lookAxisAngle = new AxisAngle4f(kamera.look, 0);
  Matrix4f rotLook = new Matrix4f();
//  Vector3f labelPos = new Vector3f();
//  Vector3f radialVec = new Vector3f();
  
  FanSelection(Selectable parentSelectable, SelectableLabel[] selectableLabels) {
    this.parentSelectable = parentSelectable;
    this.selectableLabels = new ArrayList(Arrays.asList(selectableLabels));
    this.selectableLabels.add(this);
    
    if (parentSelectable instanceof Label) {
      this.setLabel(((Label)parentSelectable).getLabel());
      this.setDisplayPosition(parentSelectable.getDisplayPositionVec());
    }
    
    update();
  }
  
  void update() {
    Vector3f parentPos = parentSelectable.getDisplayPositionVec();
    Vector3f labelPos = new Vector3f();
    Vector3f radialVec = new Vector3f(kamera.up);
    Vector3f distToLabel = new Vector3f();
    
    //distToLabel.scaleAdd(distToKameraPlane, kamera.look, kamera.pos);
    distToLabel.sub(parentPos, kamera.pos);
    
    radius = height / 10 * this.selectableLabels.size();
    radialVec.scale(distToLabel.length() / 15 * selectableLabels.size());
    
    float theta = TWO_PI / (float) selectableLabels.size();
    lookAxisAngle.set(kamera.look, theta);
    rotLook.set(lookAxisAngle);
    
    for (int i=0; i<selectableLabels.size(); i++) {
      
      rotLook.transform(radialVec);
      labelPos.add(radialVec, parentPos);
      
      ((SelectableLabel)selectableLabels.get(i)).setDisplayPosition(labelPos);
    }
  }
  
  ArrayList getSelectableLabels() {
    return selectableLabels;
  }
}

class SelectableLabel implements Selectable, Label {
  Selectable parentSelectable;
  
  Vector2f screenPosition;
  Vector3f displayPosition;
  
  String label;
  
  SelectableLabel(String theLabel, float theScreenX, float theScreenY) {
    screenPosition = new Vector2f();
    displayPosition = new Vector3f();
    
    setScreenPosition(theScreenX, theScreenY);
    setLabel(theLabel);
  }
  
  SelectableLabel() {
    this("", 0, 0);
  }
  
  SelectableLabel(String theLabel, Vector3f displayPos) {
    this(theLabel, screenX(displayPos), screenY(displayPos));
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
  
  void setLabel(String label) {
    this.label = label;
  }
  
  String getLabel() {
    return label;
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
    this.selectables.add(s);
  }
  
  void addToSelectables (Collection theSelectables) {
    this.selectables.addAll(theSelectables);
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
    Float hoverAngle = (Float) particleSelector.hoverAngles.get(theSelectable);
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
    
    //for (int i=0; i<theSelectables.size(); i++) {
    for (Iterator iter=theSelectables.iterator(); iter.hasNext();) {
      
      //Selectable p = (Selectable) theSelectables.get(i);
      Selectable p = (Selectable) iter.next();
      
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
    
    
    if (angleToBestPick < minSelectionAngle) {
      return (Selectable) bestPick;
    }
    else {
      return null;
    }
  }
}

class Labelor {
  VTextRenderer v;
  float lh;
  
  Labelor() {
    v = myVTextRenderer;
    
    // Use the highest lineHeight expected, rather than the sporadic bounds textRender gives for each string
    lh = (float) v._textRender.getBounds("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ|()123456789!@#$%^&*").getHeight();
  }
    
  void drawLabelGL(GL gl, SelectableLabel sl, float scale) {
    drawLabelGL(gl, sl.getLabel(), sl.getDisplayPositionVec(), scale);
  }
  
  void drawLabelGL(GL gl, String msg, Vector3f position, float scale) {
    beginCylindricalBillboardGL(position.x, position.y, position.z);
      
      //SCALE
      Vector3f toKamera = new Vector3f(kamera.pos);
      toKamera.sub(position);
      float distToKamera = toKamera.length();
      
      float s = min(distToKamera*0.001, 0.1);
      s = max(s, distToKamera * 0.00085 * scale);
      //s = max(s, distToKamera * 0.0008 * scale);
      
      gl.glScalef(s, s, s);
      
      // LABEL TEXT
      String[] msgLines = msg.split("\n");
      
      for (int i=0; i<msgLines.length; i++) {
        String msgLine = msgLines[i];
        
        Rectangle2D labelRect = myVTextRenderer._textRender.getBounds(msgLines[i]);
        
        float lw = (float)labelRect.getWidth();
        //float lh = (float)labelRect.getHeight();
        
        float yOffset = -lh * ((float)i + 2);
        
        float lx = (float)labelRect.getCenterX();
        float ly = -(float)labelRect.getCenterY() + yOffset;
        
//        if(msgLines.length > 3) {
//          intervalSay(45, "yOffset: " + nf(yOffset, 3, 0) + ", lh: " + nf(lh, 3, 0) + ", msgLines[i]: " + msgLines[i]);
//        }
        /*
        // LABEL BACKGROUND
        gl.glPushMatrix();
        
          gl.glTranslatef(-lx, 0, 0);
          gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE_MINUS_SRC_ALPHA);
          gl.glColor4f(0.1f, 0.1f, 0.1f, 0.5f);
          gl.glTranslatef(lx, ly, 0);
          //simpleQuadGL(gl);
          simpleQuadGL(gl, (0.5*1.2)*lw, lh);
        gl.glPopMatrix();
        */
        // RENDER LABEL
        myVTextRenderer.print(msgLines[i], -lx, yOffset, 0);
      }
      
//      myVTextRenderer.print(msg, 0, yOffset, 0);
//      myInfobox.print(msg);
      gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_DST_ALPHA);
    endBillboardGL();
  }
}

//Vector3f Utils
void scaleVectors(Vector3f[] v, float scale) {
  for (int i=0; i<v.length; i++) {
    v[i].scale(scale);
  }
}

Vector3f[] genPolygonVertices(int n) {
  
  Vector3f[] vecs = new Vector3f[n];
  for (int i=0; i<n; i++) {
    
    float theta = TWO_PI * ((float)i) / (float)n;
    float r = 5 * n;
    Dbg.say("theta/TWO_PI, r: " + theta/TWO_PI + " " + r);
    //Vector3f pos = new Vector3f(1 + random(-1, 1) * cos(theta), 1 + random(-1, 1) * sin(theta), 0);
    Vector3f pos = new Vector3f(cos(theta)-1, sin(theta), 0);
    Dbg.say("target[" + i + "].pos: " + pos);
    pos.scaleAdd(r, pos, targetParticle.getPositionVec());
    vecs[i] = pos;
  }
  return vecs;
}

// STRING FORMATTING
String nfVec(Vector3f v, int digits) {
  String s = "(" + 
  nfs(v.x, digits, 1) + ", " + 
  nfs(v.y, digits, 1) + ", " + 
  nfs(v.z, digits, 1) + ")";
  
  return s;
}

float screenX (Vector3f v) {
  return screenX(v.x, v.y, v.z);
}

float screenY (Vector3f v) {
  return screenY(v.x, v.y, v.z);
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
