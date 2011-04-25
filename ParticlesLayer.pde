// ParticlesLayer
// tflorez

class ParticlesLayer {
  
  Collection selectedParticles;
  
  PImage particleImage;
  Kamera kamera;
  
  Texture particleTexture;
  Texture particleClockTickTexture;
  
  Texture selectedParticleTexture;
  
  float PARTICLE_SIZE;
  
  int[] textures = new int[3];
    
  ParticlesLayer (List particles, String particleImagePath, Kamera kamera, Collection theSelectedParticles) {
    
    this.selectedParticles = theSelectedParticles;
    
    this.kamera = kamera;
    this.particleImage = loadImage(particleImagePath);
    
    pgl = (PGraphicsOpenGL)g;
    gl = pgl.beginGL();
    
      this.particleTexture = loadTextureFromStream(openStream(particleImagePath));
      this.selectedParticleTexture = loadTextureFromStream(openStream(prefs.getString("selectedParticleImagePath")));
      this.particleClockTickTexture = loadTextureFromStream(openStream(prefs.getString("particleClockTickImagePath")));
    
    pgl.endGL();
  }
  
  Texture loadTextureFromStream(InputStream textureStream){
    
    Texture texture = null;
    
    try {
      texture = TextureIO.newTexture(textureStream, true, TextureIO.PNG);
      //texture.setTexParameteri(GL.GL_TEXTURE_MAG_FILTER, GL.GL_LINEAR_MIPMAP_NEAREST);
      //texture.setTexParameteri(GL.GL_TEXTURE_MIN_FILTER, GL.GL_LINEAR_MIPMAP_NEAREST);
    }
    catch(Exception e) {
      println("Error loading texture: " + e);
    }
    
    return texture;
  }
  
  void draw() {
    
    this.PARTICLE_SIZE = prefs.getFloat("PARTICLE_SIZE");
    restFrame.setPosition(targetParticle.getPositionVec());
    
    // GL SECTION BEGIN
    pgl = (PGraphicsOpenGL)g;
    gl = pgl.beginGL();
    
    // DRAW PATHS + REST & ORIGIN FRAME AXES
    this.drawPathsAndAxesGL(gl, particles);
    
    // INTERSECTION CALCULATION
    Frame[] displayFrames = new Frame[] {
      restFrame,
      //targetParticle
    };
    
    HashMap frameIntersectionsMap = this.buildFrameIntersectionsMap(displayFrames, particles);
    
    // UPDATE & DRAW INTERSECTIONS
    updateIntersections(simultIntersections);
    this.drawIntersectionsGL(gl, simultIntersections);
    
    // DRAW HEADS
    this.drawHeadsGL(gl, frameIntersectionsMap);
    
    // PARTICLES (TEXTURED BILLBOARDS)
    this.drawParticleClockPulsesGL(gl, particles, displayFrames, frameIntersectionsMap);
    
    // PARTICLE CLOCK TICKS
    if (prefs.getBoolean("show_Particle_Clock_Ticks")) {
      this.drawParticleClockTicksGL(gl, particles, particleClockTickTexture);
    }
    
    // SELECTION RETICLES (TEXTURED BILLBOARDS)
    this.drawSelectionReticlesGL(gl, selectedParticleTexture, selectedParticles);
    
    // RIGID BODIES
    if (prefs.getBoolean("show_Rigid_Bodies") == true) {
      
      for (Iterator iter=rigidBodies.iterator(); iter.hasNext(); ) {
        RigidBody rb = (RigidBody) iter.next();
        rb.drawGL(gl);
      }
    }
    
    // SELECTION LABELS
    this.drawSelectedParticleLabelsGL(gl);
    this.drawSelectionLabelsGL(gl, intersectionSelector);
    
    // FAN SELECTION LABELS (MENU FROM RIGHT CLICK ON SELECTABLE)
    if (labelSelector.selection.contains(myFanSelection)) {
      this.drawFanSelectionLabelsGL(gl, myFanSelection);
    }
    
    // TARGETS (LINK INTERSECTIONS WITH HORIZONTAL PLANE)
    gl.glColor4f(0.4, 0.4, 0.4, 0.5);
    gl.glBegin(GL.GL_LINE_LOOP);
    for (int i=0; i < targets.size(); i++) {
      Particle p = (Particle) targets.get(i);
      Vector3f linkPos = p.getDisplayPositionVec();
      
      gl.glVertex3f(linkPos.x, linkPos.y, linkPos.z);
    }
    gl.glEnd();
    
    pgl.endGL();
  }
  
  void updateIntersections(List theIntersections) {
    for (int i=0; i<theIntersections.size(); i++) {
      PathPlaneIntersection intersection = (PathPlaneIntersection) theIntersections.get(i);
      intersection.update();
    }
  }
  
  HashMap buildFrameIntersectionsMap(Frame[] theDisplayFrames, List theParticles) {
    
    HashMap theFrameIntersectionsMap = new HashMap();
    
    for (int i=0; i < theDisplayFrames.length; i++) {
      Frame currentFrame = theDisplayFrames[i];
      Vector3f[] theIntersections = new Vector3f[theParticles.size()];
      Vector3f theIntersection;
      
      for (int j=0; j < theParticles.size(); j++) {
        Particle p = (Particle) particles.get(j);
        theIntersection = p.getIntersection(currentFrame);
        
        if (theIntersection != null) {
          Relativity.displayTransform(lorentzMatrix, theIntersection, theIntersection);
        }
        theIntersections[j] = theIntersection;
      }
      theFrameIntersectionsMap.put(currentFrame, theIntersections);
    }
    return theFrameIntersectionsMap;
  }
  
  void drawPathsAndAxesGL(GL gl, List theParticles) {
    
    //restFrame.setPosition(targetParticle.getPosition());
    //originFrame.getAxesSettings().setAxesGridVisible(prefs.getBoolean("show_Origin_Axes_Grid"));
    
    myAxes.drawGL(gl, restFrame);
    myAxes.drawGL(gl, originFrame);
    
    for (int i=0; i < theParticles.size(); i++) {
      Particle p = (Particle)theParticles.get(i);
      
      // WORLDLINE PATH
      p.drawPathGL(gl);
      
      // AXES
      if ( !emissions.contains(p) ) {
        myAxes.drawGL(gl, (Frame)p);
      }
    }
  }
  
  void drawHeadsGL(GL gl, HashMap theFrameIntersectionsMap) {
    
    Collection intersectionArrays = theFrameIntersectionsMap.values();
    for (Iterator iter = intersectionArrays.iterator(); iter.hasNext(); ) {
      Vector3f[] intersections = (Vector3f[]) iter.next();
      
      for (int i=0; i<intersections.length; i++) {
        Particle p = (Particle) particles.get(i);
        Vector3f displayTmp = new Vector3f();
        
        if (intersections[i] != null) {
          p.drawHeadGL(gl, intersections[i]);
        }
      }
    }
  }
  
  void drawSelectionReticlesGL(GL gl, Texture theSelectionReticleTexture, Collection selection) {
    
    beginTextureGL(selectedParticleTexture);
    
      for (Iterator iter = selection.iterator(); iter.hasNext(); ) {
        Particle p = (Particle) iter.next();
        if (p == null) { continue; }
        
        Vector3f displayPos = p.getDisplayPositionVec();
        
        float scale = 0.25;
        
        gl.glColor4f(1, 1, 1, 0.35);
        
        drawDistanceScaledBillboardGL(displayPos, scale);
      }
    endTextureGL(theSelectionReticleTexture);
  }
  
  void drawParticleClockTicksGL(GL gl, List theParticles, Texture theTexture) {
    
    beginTextureGL(theTexture);
    
    int[] tickColors = new int[] {
      //A R G B
      0xFFFF0044, // 0 red
      0XFFFFFF00, // 1 yellow
      0XFFFF7700, // 2 orange
      0XFF00FF44, // 3 green
      0XFF0077FF, // 4 blue
      0XFF9900FF, // 5 violet
    };
    
    for (int i=0; i < theParticles.size(); i++) {
      Particle p = (Particle)theParticles.get(i);
      
      Vector3f tickPos = new Vector3f();
      Vector3f tickDisplayPos = new Vector3f();
      
      float tickSpacing = nearestPowerOf10Below(p.getAge()/2);
      float tickSpacingExponent = logBase10(tickSpacing);
      
      int colorIndex = max(0, (int)tickSpacingExponent);
      int c = tickColors[colorIndex];
      
      float tickScale = 0.2 + 0.1 * colorIndex;
      
      glColorGL(gl, c);
      
      for (int j=0; j<p.histCount; j++) {
        Frame f = p.frameHist[j];
        Frame fNext = p.frameHist[j+1];
        
        Vector3f threeVelocity = f.getVelocity().getThreeVelocity();
        
        float timeToFirstTick = tickSpacing - fNext.getAncestorsAge() % tickSpacing;
        float timeFirstTickToNextFrame = fNext.getAge() - timeToFirstTick;
        
        float numTickSegments = timeFirstTickToNextFrame / tickSpacing;
        int numTicks = (numTickSegments < 0) ? 0 : 1 + (int) numTickSegments;
        
        // FIRST TICK POS
        tickPos.scaleAdd(timeToFirstTick, threeVelocity, f.getPositionVec());
        
        for (int n=0; n < numTicks; n++) {
          
          Relativity.displayTransform(lorentzMatrix, tickPos, tickDisplayPos);
          
          drawTickGL(gl, tickScale, tickDisplayPos);
          
          tickPos.scaleAdd(tickSpacing, threeVelocity, tickPos);
        }
      }
    }
    
    endTextureGL(theTexture);
  }
  
  void drawDistanceScaledBillboardGL(Vector3f theDisplayPos, float theScale) {
    
    drawBillboardGL(theDisplayPos, theScale * getDistance(theDisplayPos, kamera.pos));
  }
  
  void drawBillboardGL(Vector3f displayPos, float scale) {
  
    beginCylindricalBillboardGL(displayPos);
      
      gl.glScalef(scale, scale, scale);
      simpleQuadGL(gl);
      
    endBillboardGL();
  }
  
  void drawTickGL(GL gl, float tickScale, Vector3f tickDisplayPos) {

    float farClampRatio = 0.05 * tickScale;
    
    beginCylindricalBillboardGL(tickDisplayPos);
    beginDistanceScaleGL(tickDisplayPos, kamera.pos, 1, 1, farClampRatio);
      
      simpleQuadGL(gl);
      
    endDistanceScaleGL();
    endBillboardGL();
  }
  
  void drawIntersectionsGL(
    GL gl,
    List theIntersections
    ) {
    
    particleTexture.enable();
    particleTexture.bind();
    
    for (int i=0; i<theIntersections.size(); i++) {
      PathPlaneIntersection intersection = (PathPlaneIntersection) theIntersections.get(i);
      
      Vector3f displayPos = intersection.getDisplayPositionVec();
      
      drawIntersectionGL(displayPos, intersection.pathParent);
    }
    particleTexture.disable();
  }
  
  void drawIntersectionGL(Vector3f theDisplayPos, Particle theParentParticle) {

    if (theDisplayPos == null) {
      return;
    }
    
    Vector3f intersectPos = Relativity.inverseDisplayTransform(targetParticle.getVelocity(), theDisplayPos);
    
    // Distance (in world frame) from intersection to current simulation step
    // of the parent particle whose worldline path corresponds to this intersection
    float distToParent = getDistance(intersectPos, theParentParticle.getPositionVec());
    
    // Length (in world frame) of path parent's 2+1 velocity
    float parentThreeVelLength = theParentParticle.getVelocity().getThreeVelocity().length();

    // Time offset for path parent particle between the current simulation step and this path-plane intersection
    float properTimeOffset = distToParent / parentThreeVelLength;
    
    // Is the intersection in the path parent's future or past?
    int offsetSign = (intersectPos.z > theParentParticle.getPositionVec().z) ? +1 : -1;
    
    // Propertime the path parent partice would have when passing through intersection,
    // assuming the velocity it has on its current route
    float intersectionProperTime = theParentParticle.properTime + properTimeOffset * offsetSign;
    
    // Distance (in display coordinates) from kamera to the intersection being drawn
    float distKameraToDisplayPos = getDistance(theDisplayPos, kamera.pos);
    
    // Factor for animating particle clock pulses
    float pulseFactor = 1.0 - 0.5*sin(intersectionProperTime);
    
    float scale = distKameraToDisplayPos * 0.05 * PARTICLE_SIZE * pulseFactor;
    
    color c = lerpColor(#FFFFFF, theParentParticle.fillColor, 0.5*pulseFactor);
    
    glColorGL(gl, c);
    drawBillboardGL(theDisplayPos, scale);
  }
  
  void drawParticleClockPulsesGL(
    GL gl,
    List theParticles,
    Frame[] theDisplayFrames,
    HashMap frameIntersections) {

    particleTexture.enable(); //gl.glEnable(GL.GL_TEXTURE_2D); //gl.glEnable(particleTexture.getTarget());
    particleTexture.bind(); //gl.glBindTexture(GL.GL_TEXTURE_2D, textures[0]); //gl.glTexEnvf(GL.GL_TEXTURE_ENV, GL.GL_TEXTURE_ENV_MODE, GL.GL_MODULATE);
    
    Vector3f toParticle = new Vector3f();
    
    for (int k=0; k < theDisplayFrames.length; k++) {
      Frame theFrame = theDisplayFrames[k];
      Vector3f[] intersections = (Vector3f[]) frameIntersections.get(theFrame);
      
      for (int i=0; i<intersections.length; i++) {
        Particle p = (Particle) particles.get(i);
                
        Vector3f displayPos = intersections[i];
        drawIntersectionGL(displayPos, p);
      }
    }
    particleTexture.disable();
  }
  
  void drawSelectionLabelsGL(GL gl, Selector theSelector) {
    
    color labelColor = #22DDFF;
    myLabelor.setTextColor(labelColor);
    
    for (Iterator iter = theSelector.selection.iterator(); iter.hasNext(); ) {
      ISelectableLabel sl = (ISelectableLabel) iter.next();
      if (sl == null || sl.getDisplayPositionVec() == null) { continue; }
      
      Vector3f displayPos = sl.getDisplayPositionVec();
      
      gl.glColor4f(1, 1, 1, 0.5);
      
      String label = sl.getName(); //"An Intersection"; //buildLabel(sl);
      float labelScale = theSelector.getHoverScale(sl);
      
      myLabelor.drawLabelGL(gl, label, displayPos, labelScale);
    } 
  }
  
  void drawSelectedParticleLabelsGL(GL gl) {
    
    color particleLabelColor = #22DDFF;//#BBCCCCCC;
    myLabelor.setTextColor(particleLabelColor);
    
    for (Iterator iter = selectedParticles.iterator(); iter.hasNext(); ) {
      
      Particle p = (Particle) iter.next();
      if (p == null) { continue; }
      
      Vector3f displayPos = p.getDisplayPositionVec();
      
      gl.glColor4f(1, 1, 1, 0.5);
      
      String label = buildParticleLabel(p);
      float labelScale = particleSelector.getHoverScale(p);
      
      myLabelor.drawLabelGL(gl, label, displayPos, labelScale);
    }
  }
  
  void drawFanSelectionLabelsGL(GL gl, FanSelection theFanSelection) {
    
    int fanSelectionColor = ACTION_COLOR;
    myLabelor.setTextColor(fanSelectionColor);
    myLabelor.backgroundVisible = true;
    
    ArrayList labels = theFanSelection.getSelectableLabels();
    for (int i=0; i<labels.size(); i++) {
      SelectableLabel selecLabel = (SelectableLabel) labels.get(i);
      
      myLabelor.drawLabelGL(gl, selecLabel, 0.5);
      
      Vector3f displayPos = selecLabel.getDisplayPositionVec();
      
      float scale = 0.005;
      
      // DISTANCE SCALED BILLBOARD
      drawDistanceScaledBillboardGL(displayPos, scale);
    }
    myLabelor.drawLabelGL(gl, (SelectableLabel) myFanSelection, 0.5);
    
    myLabelor.backgroundVisible = false;
  }
  
  String buildLabel(Object theObject) {
    if (theObject instanceof Particle) {
      return buildParticleLabel((Particle) theObject);
    }
    else if (theObject instanceof ISelectableLabel) {
      return ((ISelectableLabel)theObject).getLabel();
    }
    return null;
  }
  
  String buildParticleLabel(Particle p) {
    
    Vector3f targetToParticle = new Vector3f();
    Vector3f targetToParticlePrime = new Vector3f(); 
    
    String label = "";
    
    if (targets.contains(p)) {
      label += "ControlParticle(" + targets.indexOf(p) + ")\n";
    }
    else if (emissions.contains(p)) {
      label += "Emission(" + emissions.indexOf(p) + ")\n";
    }
    else if (particles.contains(p)) {
      label += "Particles(" + particles.indexOf(p) + ")\n";
    }
    
    label += p.label;
    
    /*
    targetToParticle.sub(p.getPositionVec(), targetParticle.getPositionVec());
    //Relativity.displayTransform(lorentzMatrix, targetToParticle, targetToParticlePrime);
    
    lorentzMatrix.transform(targetToParticle, targetToParticlePrime);
    */
    
    return label;
  }
}

void simpleQuadGL(GL gl, float x, float y, float z) {
  gl.glPushMatrix();
  gl.glTranslatef(x, y, z);
  simpleQuadGL(gl);
  gl.glPopMatrix();
}

void simpleQuadGL(GL gl, float w, float h) {
  gl.glBegin(GL.GL_QUADS);
  gl.glTexCoord2f(w,h); gl.glVertex2f(w,h);
  gl.glTexCoord2f(w,0); gl.glVertex2f(w,-h);
  gl.glTexCoord2f(0,0); gl.glVertex2f(-w,-h);
  gl.glTexCoord2f(0,h); gl.glVertex2f(-w,h);
  gl.glEnd();
}

void simpleQuadGL(GL gl) {
  simpleQuadGL(gl, 1, 1);
  /*
  gl.glBegin(GL.GL_QUADS);
  gl.glTexCoord2f(1,1); gl.glVertex2f(1,1);
  gl.glTexCoord2f(1,0); gl.glVertex2f(1,-1);
  gl.glTexCoord2f(0,0); gl.glVertex2f(-1,-1);
  gl.glTexCoord2f(0,1); gl.glVertex2f(-1,1);
  gl.glEnd();
  */
}

void glTriangle(GL gl) {
  gl.glBegin(GL.GL_TRIANGLES);
  gl.glVertex2f(0, 1);
  gl.glVertex2f(-0.5, -1);
  gl.glVertex2f(+0.5, -1);
  gl.glEnd();
}

void beginBillboardGL(Kamera k, float x, float y, float z){
  gl.glPushMatrix();
  
  float dx = k.pos.x - x;
  float dy = k.pos.y - y;
  float dz = k.pos.z - z;
  float dxy = sqrt(dx*dx + dy*dy);
  float dxyz = sqrt(dz*dz + dxy*dxy);
  
  float theta_ct = degrees(atan2(dy, dx));
  float phi_ct = atan2(dz, dxy);
  
  gl.glTranslatef(x, y, z);
  
  //gl.glRotatef(degrees(frameCount)/10, 0f, 0f, 1f);
  
  gl.glRotatef(theta_ct, 0f, 0f, 1f);
  gl.glRotatef(degrees(-HALF_PI-phi_ct), 0f, 1f, 0f);
  gl.glRotatef(degrees(-HALF_PI), 0f, 0f, 1f);  
}

//BILLBOARDING (in OpenGL)
void endBillboardGL(){
  gl.glPopMatrix();
}

void beginCylindricalBillboardGL(Vector3f v) {
  beginCylindricalBillboardGL(v.x, v.y, v.z);
}

void beginCylindricalBillboardGL(float x, float y, float z){
  gl.glPushMatrix();
  
  gl.glTranslatef(x, y, z);
  
  float[] modelview = new float[16];
  
  gl.glGetFloatv(GL.GL_MODELVIEW_MATRIX, modelview, 0);
  
  for (int row=0; row<3; row++) {
    for (int col=0; col<3; col++) {
      modelview[row*4+col] = (row==col) ? 1 : 0;
    }
  }
  gl.glLoadMatrixf(modelview, 0);
}

//BILLBOARDING (in processing)
void drawBillboard(PImage img, float scale, Kamera kamera, float x, float y, float z){
  pushMatrix();
  
  float dx = kamera.pos.x - x;
  float dy = kamera.pos.y - y;
  float dz = kamera.pos.z - z;
  float dxy = sqrt(dx*dx + dy*dy);
  float dxyz = sqrt(dz*dz + dxy*dxy);
  
  float theta_ct = atan2(dy, dx);
  float phi_ct = atan2(dz, dxy);

  translate(x, y, z);
  rotateZ(theta_ct);
  rotateY(-HALF_PI-phi_ct);
  rotateZ(-HALF_PI);

  scale(scale);
  image(img, 0, 0);

  popMatrix();
}

