// ParticlesLayer
// tflorez

class ParticlesLayer {
  ArrayList particles;
  Collection selection;
  
  PImage particleImage;
  Kamera kamera;
  
  Texture particleTexture;
  Texture selectedParticleTexture;
  
  int[] textures = new int[3];
    
  ParticlesLayer (ArrayList particles, String particleImagePath, Kamera kamera, Collection selection) {
    this.particles = particles;
    this.selection = selection;
    
    this.kamera = kamera;
    this.particleImage = loadImage(particleImagePath);
    //this.particleTexture = loadTexture(particleImagePath);
    pgl = (PGraphicsOpenGL)g;
    gl = pgl.beginGL();
    this.particleTexture = loadTextureFromStream(openStream(particleImagePath));
    this.selectedParticleTexture = loadTextureFromStream(openStream(prefs.getString("selectedParticleImagePath")));
    //loadTextureGL(openStream(particleImagePath));
    pgl.endGL();
  }
  
  void loadTextureGL(InputStream textureStream){
    
    TextureData textureData = null;
    //dumpStreamBytes(textureStream, 32);
    try {
      textureData = TextureIO.newTextureData(textureStream, true, TextureIO.PNG);
      //texture = TextureIO.newTexture(textureStream, false, TextureIO.PNG);
    }
    catch(Exception e) {
      println("Error loading textureData: " + e);
    }
    
    int imgWidth = textureData.getWidth();
    int imgHeight = textureData.getHeight();
    int bytesPerPixel = 4;
    
    Buffer textureBuffer = textureData.getBuffer();
    
    gl.glGenTextures(1, textures, 0);
    gl.glBindTexture(GL.GL_TEXTURE_2D, textures[0]);
    gl.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_WRAP_S, GL.GL_REPEAT);
    gl.glTexImage2D(
      GL.GL_TEXTURE_2D,
      0,
      GL.GL_RGBA,
      imgWidth,
      imgHeight,
      0,
      GL.GL_UNSIGNED_BYTE,//GL.GL_INT,//GL.GL_BYTE,//
      GL.GL_RGBA,
      textureBuffer
    );
    
    if (textureBuffer != null) {
      println("textureBuffer.toString(): " + textureBuffer.toString());
    }
    else {
      println("textureBuffer was null");
    }
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
  
  Texture loadTexture(String pImagePath) {
    Texture texture = null;
    
    try {
      texture = TextureIO.newTexture(new File(dataPath(pImagePath)), true);
    }
    catch(Exception e) {
      println("Error loading texture: " + e);
    }
      
    return texture;
  }
  
  void draw() {
    
    //inputDispatch.updateParticleDragging();
    
    restFrame.setPosition(targetParticle.getPosition());
    Frame[] displayFrames = new Frame[] {restFrame, targetParticle};
    
    // GL SECTION BEGIN
    pgl = (PGraphicsOpenGL)g;
    gl = pgl.beginGL();
    
    originFrame.getAxesSettings().setAxesGridVisible(prefs.getBoolean("show_Origin_Axes_Grid"));
    
    myAxes.drawGL(gl, restFrame);
    myAxes.drawGL(gl, originFrame);
    //targetParticle.drawHeadGL(gl);
    
    for (int i=0; i < particles.size(); i++) {
      Particle p = (Particle)particles.get(i);
        
      // WORLDLINE PATH
      p.drawPathGL(gl);
      
      // AXES
      if ( !emissions.contains(p) ) {
        myAxes.drawGL(gl, (Frame)p);
      }
    }
    
    // INTERSECTION CALCULATION
    HashMap frameIntersections = new HashMap();
    for (int i=0; i<displayFrames.length; i++) {
      frameIntersections.put(displayFrames[i], new Vector3f[particles.size()]);
    }
    
    for (int k=0; k < displayFrames.length; k++) {
      Frame theFrame = displayFrames[k];
      
      Vector3f[] intersections = (Vector3f[]) frameIntersections.get(theFrame);
      Vector3f theIntersection = new Vector3f();
      
      for (int i=0; i < particles.size(); i++) {
        Particle p = (Particle)particles.get(i);
        
        // FIND SIMULT. PLANE INTERSECTIONS
        theIntersection = p.getIntersection(theFrame);
        
        if (theIntersection != null) {
          Relativity.displayTransform(lorentzMatrix, theIntersection, theIntersection);
          
          // DRAW INTERSECTION
          p.drawHeadGL(gl, theIntersection);
        }
        intersections[i] = theIntersection;
      }
    }
    
    // PARTICLE CLOCK PULSES
    particleTexture.enable();
    particleTexture.bind();
    
    for (int i=0; i < particles.size(); i++) {
      Particle p = (Particle)particles.get(i);
      Vector3f tickPos = new Vector3f();
      Vector3f tickDisplayPos = new Vector3f();
      
//      if (emissions.indexOf(p) == 0) {
//        intervalSay(45, "Emission0, p.histCount: " + p.histCount);
//      }
      
      float tickSpacing = 10;
      
      float tickSpacingExponent = (int) ( log(p.getAge() + p.getAncestorsAge()) / log(10) );
      tickSpacing = pow(10, tickSpacingExponent);
      
//      if (p == targetParticle) {
//        intervalSay(45, "p.getAge(): " + p.getAge() + ", p.getAncestorsAge(): " + p.getAncestorsAge());
//        intervalSay(45, "tickSpacingExponent: " + tickSpacingExponent + ", tickSpacing: " + tickSpacing);
//        intervalSay(45, "p.histCount: " + p.histCount + ",\t p.frameHist.length: " + p.frameHist.length); 
//        intervalSay(45, "p.histCount: " + p.histCount + ",\t p.frameHist.length: " + p.frameHist.length);
//        intervalSay(45, "p.frameHist[" + p.histCount + "]:" +  p.frameHist[p.histCount]);
//        intervalSay(45, "p.frameHist[" + (p.histCount + 1) + "]: " + p.frameHist[(p.histCount + 1)]);
//      }
      
      for (int j=0; j<p.histCount; j++) {
        Frame f = p.frameHist[j];
        Frame fNext = p.frameHist[j+1];
        
//        if (p == targetParticle) {
//          intervalSay(45, "p.frameHist[" + i + "]: " + p.frameHist[i]);
//          intervalSay(45, "p.frameHist[" + (i+1) + "]: " + p.frameHist[i+1]);
//        }
        
        Vector3f threeVelocity = fNext.getVelocity().getThreeVelocity();
        
        tickPos.scaleAdd(tickSpacing - f.getAncestorsAge() % tickSpacing, threeVelocity, f.getPositionVec());
        Plane nextSimultPlane = fNext.getSimultaneityPlane();
        
        //while ( ! nextSimultPlane.liesBelow(tickPos) ) {
        while ( tickPos.z < fNext.getPositionVec().z ) {
          Relativity.displayTransform(lorentzMatrix, tickPos, tickDisplayPos);
          
          beginCylindricalBillboardGL(tickDisplayPos.x, tickDisplayPos.y, tickDisplayPos.z);
          beginDistanceScaleGL(tickDisplayPos, kamera.pos, 1, 1, 0.01);
            
            simpleQuadGL(gl);
            
          endDistanceScaleGL();
          endBillboardGL();
          
          tickPos.scaleAdd(tickSpacing, threeVelocity, tickPos);
        }
      }
    }
    particleTexture.disable();
    
    float PARTICLE_SIZE = prefs.getFloat("PARTICLE_SIZE");
    
    // PARTICLES (TEXTURED BILLBOARDS)
    particleTexture.enable(); //gl.glEnable(GL.GL_TEXTURE_2D); //gl.glEnable(particleTexture.getTarget());
    particleTexture.bind(); //gl.glBindTexture(GL.GL_TEXTURE_2D, textures[0]); //gl.glTexEnvf(GL.GL_TEXTURE_ENV, GL.GL_TEXTURE_ENV_MODE, GL.GL_MODULATE);
    
    Vector3f toParticle = new Vector3f();
    
    for (int k=0; k < displayFrames.length; k++) {
      Frame theFrame = displayFrames[k];
      Vector3f[] intersections = (Vector3f[]) frameIntersections.get(theFrame);
      
      for (int i=0; i<intersections.length; i++) {
        Particle p = (Particle) particles.get(i);
        
        if (intersections[i] == null) {
          continue;
        }
        
        float x = intersections[i].x;
        float y = intersections[i].y;
        float z = intersections[i].z;
        
        toParticle.set(intersections[i]);
        toParticle.sub(kamera.pos);
        
        float distToParticle = toParticle.length();
        float pulseFactor = 1.0 - 0.5*sin(p.properTime);
        
        float scale = distToParticle * 0.05* PARTICLE_SIZE * pulseFactor;
        
        color c = lerpColor(#FFFFFF, p.fillColor, 0.5*pulseFactor);
        
        //beginBillboardGL(kamera, x, y, z);
        beginCylindricalBillboardGL(x, y, z);
          
          gl.glColor4ub((byte)((c>>16) & 0xFF), (byte)((c>>8) & 0xFF), (byte)(c & 0xFF), (byte)((c>>24) & 0xFF));
          gl.glScalef(scale, scale, scale);
          simpleQuadGL(gl);
          
        endBillboardGL();
      }
    }
    particleTexture.disable(); //particleTexture.dispose(); //gl.glDisable(GL.GL_TEXTURE_2D);
    
    // SELECTION (TEXTURED BILLBOARDS)
    selectedParticleTexture.bind();
    selectedParticleTexture.enable();
    
    for (Iterator iter = selection.iterator(); iter.hasNext(); ) {
      Particle p = (Particle) iter.next();

      Vector3f displayPos = p.getDisplayPositionVec();
      
      toParticle.sub(displayPos, kamera.pos);
      
      float distToParticle = toParticle.length();
      float scale = 0.25*distToParticle;
      
      gl.glColor4f(1, 1, 1, 0.35);
      beginCylindricalBillboardGL(displayPos.x, displayPos.y, displayPos.z);
        gl.glScalef(scale, scale, scale);
        simpleQuadGL(gl);
      endBillboardGL();
    }
    selectedParticleTexture.disable();
    
    // SELECTION LABELS
    for (Iterator iter = selection.iterator(); iter.hasNext(); ) {
      Particle p = (Particle) iter.next();
      
      Vector3f displayPos = p.getDisplayPositionVec();
      
      gl.glColor4f(1, 1, 1, 0.5);
      
      String label = buildParticleLabel(p);
      float labelScale = particleSelector.getHoverScale(p);
      
      myLabelor.drawLabelGL(gl, label, displayPos, labelScale);
    }
    
    // FAN SELECTION (MENU FROM RIGHT CLICK ON SELECTABLE)
    if (labelSelector.selection.contains(myFanSelection)) {
      
      ArrayList labels = myFanSelection.getSelectableLabels();
      for (int i=0; i<labels.size(); i++) {
        myLabelor.drawLabelGL(gl, (SelectableLabel) labels.get(i), 0.5);
      }
      myLabelor.drawLabelGL(gl, (SelectableLabel) myFanSelection, 0.5);
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
    
    //Vector3f[] restIntersections = (Vector3f[])frameIntersections.get(restFrame);
    // RIGID BODIES
    if (prefs.getBoolean("show_Rigid_Bodies") == true) {
      
      for (Iterator iter=rigidBodies.iterator(); iter.hasNext(); ) {
        RigidBody rb = (RigidBody) iter.next();
        rb.drawGL(gl);
        
        //int intersectIndex = particles.indexOf(rb.parentParticle);
        //rb.drawBodyIntersectGL(restIntersections[intersectIndex]);
      }
    }
    
    pgl.endGL();
  }
  
  String buildParticleLabel(Particle p) {
    
    Vector3f targetToParticle = new Vector3f();
    Vector3f targetToParticlePrime = new Vector3f(); 
    
    String label = "";
    
    if (targets.contains(p)) {
      label += "ControlParticle(" + targets.indexOf(p) + ")\n";
    }
    else if (emissions.contains(p)) {
      label +=
        "Emission(" + emissions.indexOf(p) + ")\n";
    }
    else if (particles.contains(p)) {
      label += "Particles(" + particles.indexOf(p) + ")\n";
    }
    
    targetToParticle.sub(p.getPositionVec(), targetParticle.getPositionVec());
    //Relativity.displayTransform(lorentzMatrix, targetToParticle, targetToParticlePrime);
    lorentzMatrix.transform(targetToParticle, targetToParticlePrime);
    
    Vector3f displayPos = p.getDisplayPositionVec();
    
    label += (
      "p : " + nfVec(p.getPositionVec(), 3) + "\n" +
      "p': " + nfVec(displayPos, 3) + "\n" +
      "fromTarget : " + nfVec(targetToParticle, 3) + "\n" +
      "fromTarget': " + nfVec(targetToParticlePrime, 3) + "\n" +
      "velocity: (" + nf(p.velocity.magnitude, 0, 4) + ")\n" +
      "mass: ("  + nf(p.mass, 0, 4) + ")\n" +
      "age: (" + nf(p.properTime, 0, 1) + ")\n" +
      
      "headFrame.getAncestorsAge(): " + nf(p.headFrame.getAncestorsAge(), 0, 2) + "\n" +
      "headFrame.getAge(): " + nf(p.headFrame.getAge(), 0, 2)  + "\n"
      );
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

void endBillboardGL(){
  gl.glPopMatrix();
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

