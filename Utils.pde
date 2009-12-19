
class Selector extends ArrayList {
  ArrayList selectables;
  ArrayList selection;
  ArrayList hover;
  HashMap hoverAngles;
  
  float minHoverAngle = radians(10);
  float minSelectionAngle = radians(5);
  float minAngleToPreferClosest = radians(1.5);
  
  float millisLastUpdateHover;
  
  Object bestPick;
  float angleToBestPick;
  
  Selector (ArrayList theSelectables, ArrayList theStartingSelection) {
    this.selection = this;
    this.selectables = theSelectables;
    this.addAll(theStartingSelection);
    this.hover = new ArrayList();
    this.hoverAngles = new HashMap();
  }
  
  Selector (ArrayList theSelectables) {
    this(theSelectables, new ArrayList());
  }
  
  void invertSelectionStatus(Object theSelectable) {
    
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
  
  float getHoverScale(Object theSelectable) {
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
      updateHoverAndPick((java.util.List)this.selection, theKamera.pos, getPickDirection(theKamera, mouseX, mouseY));
    }
  }
  
  void updateHoverAndPick (java.util.List theSelectables, Vector3f cameraPos, Vector3f pickingRayDirection) {
    
    millisLastUpdateHover = millis();
    hover.clear();
    hoverAngles.clear();
    
    bestPick = null;
    angleToBestPick = PI;
    
    float distToBestPick = Float.MAX_VALUE;
        
    Vector3f cameraToParticle = new Vector3f();
    
    for (int i=0; i<theSelectables.size(); i++) {
      
      Particle p = (Particle) theSelectables.get(i);
      
      cameraToParticle.sub(p.getDisplayPositionVec(), cameraPos);
      
      float distToParticle = cameraToParticle.length();
      
      float angleRayToParticle = cameraToParticle.angle(pickingRayDirection);
      
      if ( (angleRayToParticle < angleToBestPick) || 
           ( (angleRayToParticle < minAngleToPreferClosest)
              && (distToParticle < distToBestPick) ) )
      {
        distToBestPick = distToParticle;
        angleToBestPick = angleRayToParticle;
        bestPick = p;
      }
      
      if ( angleRayToParticle < minHoverAngle) {
        hover.add(p);
        hoverAngles.put(p, Float.valueOf(angleRayToParticle));
      }
    }
  }
  
  //Particle pickPoint(Vector3f cameraPos, Vector3f pickingRayDirection) {
  Particle pickPoint(Kamera theKamera, int theMouseX, int theMouseY) {
    
    updateHoverAndPick((java.util.List)this.selectables, theKamera.pos, getPickDirection(theKamera, theMouseX, theMouseY));
    
    if (angleToBestPick < minSelectionAngle) {
      return (Particle) bestPick;
    }
    else {
      return null;
    }
  }
}
/*
interface Label {
  getLabelText();
  drawLabel();
}
*/
class Labelor {
  VTextRenderer v;
  
  Labelor() {
    v = myVTextRenderer;
  }
  
  void drawLabelGL(GL gl, String msg, Vector3f position, float scale) {
    beginCylindricalBillboardGL(position.x, position.y, position.z);

      Rectangle2D labelRect = myVTextRenderer._textRender.getBounds(msg);
      
      float lw = (float)labelRect.getWidth();
      float lh = (float)labelRect.getHeight();
      
      float yOffset = -2 * lh;
      
      float lx = (float)labelRect.getCenterX();
      float ly = -(float)labelRect.getCenterY() + yOffset;
      
      Vector3f toKamera = new Vector3f(kamera.pos);
      toKamera.sub(position);
      float distToKamera = toKamera.length();
      
      float s = min(distToKamera*0.001, 0.1);
      s = max(s, distToKamera * 0.0008 * scale);
      
      gl.glScalef(s, s, s);
      gl.glTranslatef(-lx, 0, 0);
      /*
      // LABEL BACKGROUND
      gl.glPushMatrix();
        gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE_MINUS_SRC_ALPHA);
        gl.glColor4f(0.1f, 0.1f, 0.1f, 0.5f);
        gl.glTranslatef(lx, ly, 0);
        //simpleQuadGL(gl);
        simpleQuadGL(gl, (0.5*1.2)*lw, lh);
      gl.glPopMatrix();
      */
      // LABEL TEXT
      myVTextRenderer.print(msg, 0, yOffset, 0);
      gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_DST_ALPHA);
    endBillboardGL();
  }
}

// STRING FORMATTING
String nfVec(Vector3f v, int digits) {
  String s = "(" + 
  nf(v.x, digits, 1) + ", " + 
  nf(v.y, digits, 1) + ", " + 
  nf(v.z, digits, 1) + ")";
  
  return s;
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
