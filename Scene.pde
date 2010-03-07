// Scene
// tflorez

class Scene {
  List subScenes;
  List distanceMeasurements;
  
  //boolean isDescriptionVisible = false;
  
  Infopanel infolayerPanel = new Infopanel();
  Infopanel descriptionPanel = new Infopanel(
    new Infopane(
      new Vector2f(width/2, height*0.9), // size
      new Vector2f( (width - width/2)/2, (height - height*0.9)/2 ) // pos
    ));
    
  Scene() {
    this.subScenes = new ArrayList();
    this.distanceMeasurements = new ArrayList();
    
    this.infolayerPanel.isVisible = false;
    this.descriptionPanel.isVisible = false;
  }
  
  void update() {}
  
  void addMeasurement(DistanceMeasurement measurement) {
    this.distanceMeasurements.add(measurement);
  }
  
  List getParticles() {
    return null;
  }
  
  void getParticleLists(Collection target) {
    
    target.add(this.getParticles());
    
    for (Iterator iter = subScenes.iterator(); iter.hasNext(); ) {
      Scene subscene = (Scene) iter.next();
      subscene.getParticleLists(target);
    }
  }
  
  void getAllScenes(Collection target) {
    target.add(this);
    for (Iterator iter = this.subScenes.iterator(); iter.hasNext(); ) {
      Scene subScene = (Scene) iter.next();
      
      subScene.getAllScenes(target);
    }
  }
  
  void setDescription(String theDescriptionText) {
    descriptionPanel.addLine(theDescriptionText);
  }
  
  void showDescription() {
    this.descriptionPanel.isVisible = true;
  }
  
  void drawDescription() {
    intervalSay(45, "scene.drawDescription(): " + this);
    descriptionPanel.draw();
  }
  
  void drawMeasurements() {
    
    //intervalSay(45, "drawMeasurements()");
    //intervalSay(45, "this.distanceMeasurements: " + this.distanceMeasurements);
    
    if (this.distanceMeasurements.isEmpty()) { return; }
    
    kamera.commit();
    pgl =  (PGraphicsOpenGL)g;
    gl = pgl.beginGL();
    
    for (Iterator iter=distanceMeasurements.iterator(); iter.hasNext(); ) {
      DistanceMeasurement measurement = (DistanceMeasurement)iter.next();

      measurement.drawGL(gl);
    }
    pgl.endGL();
  }
  
  void draw() {
    
    intervalSay(45, "scene.draw(): " + this);
    
    this.infolayerPanel.draw();
    drawDescription();
    drawMeasurements();
  }
}

abstract class ParticleScene extends Scene {
  List particles;
  
  ParticleScene () {
    this.particles = new ArrayList();
  }
  
  List getParticles() {
    return this.particles;
  }
}

//class MultiTwinScene extends ParticleScene {}

class TwinParticleScene extends ParticleScene {
  
  TwinParticlePair twinParticlePair;
  Infobar ageDiffInfobar;
  
  TwinParticleScene(float relativeSpeed, float turnaroundTime) {
    
    this.setDescription("Twin Particle Scene");
    
    this.twinParticlePair = new TwinParticlePair(relativeSpeed, turnaroundTime);
    
    this.subScenes.add(twinParticlePair);
    
    //addTarget(twinParticlePair.twinA);
    addParticle(twinParticlePair.twinA);
    addParticle(twinParticlePair.twinB);
    
    println(twinParticlePair.twinA);
    println(twinParticlePair.twinB);
    
    FloatControl ageDiffFloatControl = new FloatControl("ageDiff", twinParticlePair.getAgeDiff());
    ageDiffFloatControl.setUnitsLabel("s");
    this.ageDiffInfobar = new Infobar(ageDiffFloatControl);
  }
  
  void draw() {
    super.draw();
    this.ageDiffInfobar.draw();
  }
  
  void update() {
    ageDiffInfobar.floatControl.setValue(twinParticlePair.getAgeDiff());
    
    this.twinParticlePair.update();
    
    if (twinParticlePair.isTripComplete()) {
      //prefs.getStateControl("playStatus").setState("paused");
      twinParticlePair.beginDeparture();
    }
  }
}

class TwinParticlePair extends Scene {
  Particle twinA, twinB;
  float relativeSpeed;
  float turnaroundTime;
  float initialAgeTwinB;
  float elapsedTime;
  
  float separation, separationLastUpdate;
  
  boolean returnHasBegun;
  
  class TwinParticleLabelBuilder extends ParticleLabelBuilder {
  
    String buildLabel(Particle p) {
      
      String theLabel = (
        "pos : " + nfVec(p.getPositionVec(), 1) + "\n" +
        "pos': " + nfVec(p.getDisplayPositionVec(), 1) + "\n" +
        "velocity: (" + nf(p.velocity.magnitude, 0, 6) + ")\n" +
        "age: (" + nf(p.properTime, 0, 1) + ")\n"
        );
      
      return theLabel;
    }
  }
  
  /** Returns a list containing a new pair of "twin" Particles
    * @param relativeSpeed
    *    The relative speed between the frames of twins A and B,
    *    as a fraction of C
    * @param turnaroundTime
    *    Elapsed time before twinB decelerates and begins to return,
    *    in seconds as measured by twinB
    */
  TwinParticlePair(float relativeSpeed, float turnaroundTime) {
    
    this.relativeSpeed = relativeSpeed;
    this.turnaroundTime = turnaroundTime;
    
    twinA = new Particle();
    twinB = new Particle();
    
    twinA.setName("Twin A");
    twinB.setName("Twin B");
    
    twinA.labelBuilder = new TwinParticleLabelBuilder();
    twinB.labelBuilder = new TwinParticleLabelBuilder();
    
    this.addMeasurement(new DistanceMeasurement(twinA, twinB));
    
    this.beginDeparture();
  }
  
  void update() {
    
    elapsedTime = twinB.properTime - initialAgeTwinB;
    
    if (!returnHasBegun && elapsedTime > turnaroundTime) {
      this.beginReturn();
    }
    
    separationLastUpdate = separation;
    separation = this.getSeparation();
  }
  
  float getAgeDiff() {
    return twinA.getAge() - twinB.getAge();
  }
  
  float getSeparation() {
    return getDistance(twinA.getPositionVec(), twinB.getPositionVec());
  }
  
  boolean isTripComplete() {
    
    return (elapsedTime >= 2 * turnaroundTime && separation > separationLastUpdate );
  }
  
  void beginReturn() {
    twinB.setVelocity(-twinB.velocity.vx, -twinB.velocity.vy);
    returnHasBegun = true;
  }
  void beginDeparture() {
    twinB.setVelocity(relativeSpeed, 0);
    initialAgeTwinB = twinB.properTime;
    returnHasBegun = false;
  }
}

class UniformParticleScene extends ParticleScene {
  
  UniformParticleScene(int count) {
    this.particles.addAll( buildUniformParticles(count) );
  }
  
  List buildUniformParticles(float theCount) {
    List theParticles = new ArrayList();
    
    float xLim, yLim, spacing;
    //float theCount = prefs.getInteger("PARTICLES");
    
    xLim = pow(10, prefs.getFloat("START_POS_X_SCALE"));
    yLim = pow(10, prefs.getFloat("START_POS_Y_SCALE"));
    spacing = sqrt(xLim*yLim / theCount);
    
    Vector3f pos = new Vector3f();
    Velocity vel = new Velocity();
    
    for (float x=0; x < xLim; x += spacing) {
      for (float y=0; y < yLim; y+= spacing) {
        if (theParticles.size() >= theCount) {
          break;
        }
        else {
          pos.set(x - xLim/2, y - yLim/2, 0);
          
          Particle p = new Particle(pos, vel);
          theParticles.add(p);
        }
      }
    }
    return theParticles;
  }
}

class RandomParticleScene extends ParticleScene {
  
  RandomParticleScene(int count) {
    
    this.particles.addAll( buildRandomParticles( count ) );
  }
  
  List buildRandomParticles (
    int count
    //float xScale,
    //float yScale,
    //float dispersionScale,
    //float velocityDispersionScale,
    //float velocityEccentricity
    )
  {
    List theParticles = new ArrayList();
    
    for (int i=1; i<count; i++) {
      
      float xScale = prefs.getFloat("START_POS_X_SCALE");
      float yScale = prefs.getFloat("START_POS_Y_SCALE");
      
      float x, y;
      
      float rScale = pow(10, prefs.getFloat("START_POS_DISPERSION"));
      
      if (prefs.getString("startPosWeight") == "cauchy") {
        
        float cauchyGamma = prefs.getFloat("cauchyGamma");
        float radius = rScale * cauchyWeightedRandom(cauchyGamma);
        float theta = random(0, TWO_PI);
        
        x = radius * cos(theta) * xScale;
        y = radius * sin(theta) * yScale;
      }
      else {
        x = random(-xScale, +xScale);
        y = random(-yScale, +yScale);
      }
      
      Vector3f pos = new Vector3f(x, y, 0);
      
      // Exponentially weight distribution of velocities towards lightspeed
      float vel_mag = 1-pow(random(1, 2), -prefs.getFloat("START_VEL_DISPERSION"));
      float heading = random(TWO_PI);
      
      float velXScale = prefs.getFloat("START_VEL_X_SCALE");
      float velYScale = prefs.getFloat("START_VEL_Y_SCALE");
      
      float vx = velXScale * vel_mag * cos(heading);
      float vy = velYScale * vel_mag * sin(heading) * (pow(1.5, -prefs.getFloat("START_VEL_ECCENTRICITY")));
      
      Vector3f vel = new Vector3f(vx, vy, 0);
      
      Particle p = new Particle(pos, vel);
      p.setFillColor(color(#1B83F0));
      
      theParticles.add(p);
    }
    
    return theParticles;
  }
}

class PolygonParticleScene extends ParticleScene {
  
  PolygonParticleScene(int numVertices) {
    
    Vector3f pos = new Vector3f();
    Velocity vel = new Velocity();
    
    Vector3f[] polygonPositions = genPolygonVerticesAt(pos, numVertices);
    scaleVectors(polygonPositions, 3);
    
    this.particles = buildParticlesAt(polygonPositions, vel);
  }
}

class InfolayerScene extends Scene {
  
  Infobox infobox;
  
  InfolayerScene(Font theFont) {
    this.descriptionPanel = null;
    
    this.infobox = new Infobox(theFont);//new Infobox(font, fontSize);
    this.infolayerPanel.addPane(infobox);
  }
  
  void draw() {
    // INFO LAYER
    this.infobox.print(
    + (int) myFpsTimer.seconds + " seconds\n"
    + (int) myFpsTimer.fpsRecent +  "fps (" + (int)(frameCount / myFpsTimer.seconds) + "avg)\n"
    + "particles: " + particles.size() + "\n"
  //  + "target age:        " + nf(targetParticle.properTime, 3, 2) + " seconds\n"
  //  + "target speed:      " + nf(targetParticle.velocity.magnitude, 1, 8) + " c\n"
  //  + "target gamma:      " + nf(targetParticle.velocity.gamma, 1, 8) + "\n"
  //  + "target position:   " + nfVec(targetParticle.position, 5) + "\n"
  //  + "target displayPos: " + nfVec(targetParticle.getDisplayPositionVec(), 5)  
  //  + "mouseX: " + mouseX + ", mouseY: " + mouseY + "\n"
    + "Controls: Arrows or W,A,S,D to Move; Right mouse button toggles camera rotation"
    );
  }
}
