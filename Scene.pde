// Scene
// tflorez

ParticleScene buildScene(String name) {
  ParticleScene scene = null;
  
  if (name == "AxesScene") {
    scene = new AxesScene();
  }
  if (name == "BellsSpaceShipScene") {
    int numGroups = 2;
    int shipsPerGroup = 3;
    float groupSpacing = 50;
    scene = new BellsSpaceShipScene(numGroups, shipsPerGroup, groupSpacing);
  }
  if (name == "LengthContractionScene") {
    scene = new LengthContractionScene();
  }
  else if (name == "TwinParadoxScene") {
    float relativeSpeed = 0.9;
    float turnaroundTime = 50;
    scene = new TwinParadoxScene(relativeSpeed, turnaroundTime);
  }
  else if (name == "MultiTwinScene") {
    scene = new MultiTwinScene(50, 0.1, 0.9, 0.1);
  }
  else if (name == "RandomParticleScene") {
    scene = new RandomParticleScene(prefs.getInteger("PARTICLES"));
  }
  else if (name == "UniformParticleScene") {
    scene = new UniformParticleScene(prefs.getInteger("PARTICLES"));
  }
  else if (name == "PhotonScene") {
    scene = new PhotonScene();
  }
  else if (name == "PolygonParticleScene") {
    scene = new PolygonParticleScene(5, 3);
  }
  
  Dbg.say("buildScene(): " + scene);
  return scene;
}

class Scene {
  List subScenes;
  List distanceMeasurements;
  List panels;
  
  Map scenePrefs = new HashMap();
  ControlPanel sceneControlPanel;
  
  //Infopanel infolayerPanel = new Infopanel();
  Infopanel descriptionPanel = buildDescriptionPanel();
  
  Infopane buildCenterPane(){
    return new Infopane(
      new Vector2f(width/2, height*0.9), // size
      new Vector2f( (width - width/2)/2, (height - height*0.9)/2 ) // pos
    );
  }
  
  class OpenLinkAction extends Action {
    
    String _path;
    String _window;
    
    OpenLinkAction(String path, String window) {
      _path = path;
      _window = window;
    }
    
    OpenLinkAction(String path) {
      this(path, "_new");
    }
    
    void doAction() {
      link(_path, _window);
      Dbg.say("Link: " + _path + ", " + _window);
    }
  }
  
  Infopanel buildDescriptionPanel() {
    Infopanel descPanel = new Infopanel(buildCenterPane());
    
    String className = this.getClass().getName();
    String descFile = className.replaceAll(".*\\$", "") + ".txt";
    String descPath = "scene-descriptions/";
    
    String[] descText = loadStrings(descPath + descFile);
    
    if (descText != null) {
      
      Dbg.say("Found description text in descFile: " + descFile);
      
      for (int i=0; i<descText.length; i++) {
        descPanel.addLine(descText[i]);
      }
    }
    else {
      Dbg.say("No description text for descFile: " + descFile);
    }
    
    descPanel.addLine("More Information");
    descPanel.addLine("» See the \"Scenarios\" section in the manual.")
             .setClickAction(new OpenLinkAction("http://worldlines.com/"));
    
    return descPanel;
  }
  
  Scene() {
    this.subScenes = new ArrayList();
    this.distanceMeasurements = new ArrayList();
    
    this.panels = new ArrayList();
    //this.panels.add(infolayerPanel);
    //this.infolayerPanel.isVisible = false;
    
    // SCENE DESCRIPTION PANEL
    this.panels.add(descriptionPanel);
    this.descriptionPanel.isVisible = false;
    
    this.sceneControlPanel = new ControlPanel("scene");
  }
  
  void addSubScene(Scene s) {
    this.subScenes.add(s);
  }
  
  void update() {
  
  }
  
  void addMeasurement(DistanceMeasurement measurement) {
    this.distanceMeasurements.add(measurement);
  }
  
  List getParticles() {
    return null;
  }
  
  Infopane getClickedPane() { //Dbg.say("scene.getClickedPane(): " + this);
    
    Infopane clicked = null;
    
    for (Iterator iter = this.panels.iterator(); iter.hasNext(); ) {
      Infopanel panel = (Infopanel) iter.next();
      clicked = panel.getClickedPane();
      
      if ( clicked != null ) {
        return clicked;
      }
    }
    
    // Try all subscene's panels
    for (Iterator iter = subScenes.iterator(); iter.hasNext(); ) {
      Scene subscene = (Scene) iter.next();
      clicked = subscene.getClickedPane();
      
      if ( clicked != null ) {
        return clicked;
      }
    }
    
    // No panel clicked in all composite scenes
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
  /*
  void showDescription() {
    this.descriptionPanel.isVisible = true;
  }
  
  void drawDescription() {
    descriptionPanel.draw();
  }
  */
  void drawPanels() {
    //beginCamera();
    camera();
    for (Iterator iter = this.panels.iterator(); iter.hasNext(); ) {
      Infopanel panel = (Infopanel) iter.next();
      panel.draw();
    }
    //endCamera();
  }
  
  void drawMeasurements() {
    
    //intervalSay(45, "drawMeasurements()");
    //intervalSay(45, "this.distanceMeasurements: " + this.distanceMeasurements);
    
    if (this.distanceMeasurements.isEmpty()) { return; }
    
    kamera.commit();
    
    pgl =  (PGraphicsOpenGL) g;
    gl = pgl.beginGL();
    
    for (Iterator iter=distanceMeasurements.iterator(); iter.hasNext(); ) {
      DistanceMeasurement measurement = (DistanceMeasurement)iter.next();
      
      measurement.drawGL(gl);
    }
    pgl.endGL();
  }
  
  void draw() { //intervalSay(90, "scene.draw(): " + this);
    drawPanels();
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
  
  Collection getAllParticles() {
    Collection c = new ArrayList();
    
    c.addAll(this.particles);
    
    for (Iterator iter = this.subScenes.iterator(); iter.hasNext(); ) {
      Scene subScene = (Scene) iter.next();
      if (subScene instanceof ParticleScene) {
        c.addAll( ((ParticleScene)subScene).particles );
      }
    }
    return c;
  }
}

class MultiTwinScene extends ParticleScene {
  
  MultiTwinScene(float turnaroundTime, float minSpeed, float maxSpeed, float speedSeparation) {
    
    int count = 1;
    
    for (float speed=minSpeed; speed <= maxSpeed; speed += speedSeparation) {
      TwinParticlePair twins = new TwinParticlePair(speed, turnaroundTime);
      
      // Hide twinA for all but the first pair; it's always at origin
      if (speed != minSpeed) {
        twins.twinA.setAllVisibility(false);
        twins.twinB.setName("Twin B." + count);
      }
      addScene(twins);//twinScene);
      //this.subScenes.add(twinScene);
      count++;
    }
    // SCENE PREFS
    this.scenePrefs.put("PROPERTIME_SCALING", Boolean.TRUE);
    this.scenePrefs.put("toggle_Spatial_Transform", Boolean.TRUE);
    this.scenePrefs.put("toggle_Temporal_Transform", Boolean.TRUE);
  }
}

class TwinParadoxScene extends ParticleScene {
  
  TwinParticlePair twinParticlePair;
  Infobar ageDiffInfobar;
  
  TwinParadoxScene(float relativeSpeed, float turnaroundTime) {
    
    this.twinParticlePair = new TwinParticlePair(relativeSpeed, turnaroundTime);
    
    this.subScenes.add(twinParticlePair);
    
    //addTarget(twinParticlePair.twinA);
    addParticle(twinParticlePair.twinA);
    addParticle(twinParticlePair.twinB);
    
    println(twinParticlePair.twinA);
    println(twinParticlePair.twinB);
    
    // AGE DIFFERENCE INFOBAR
    FloatControl ageDiffFloatControl = new FloatControl("ageDiff = delta_t = t_A - t_B", twinParticlePair.getAgeDiff());
    ageDiffFloatControl.setUnitsLabel("s");
    this.ageDiffInfobar = new Infobar(ageDiffFloatControl);
    
    // DISTANCE MEASUREMENT
    // this.addMeasurement(new DistanceMeasurement(twinParticlePair.twinA, twinParticlePair.twinB));
    
    // SCENE PREFS
    this.scenePrefs.put("toggle_Spatial_Transform", Boolean.TRUE);
    this.scenePrefs.put("toggle_Temporal_Transform", Boolean.TRUE);
  }
  
  void draw() {
    super.draw();
    camera();
    this.ageDiffInfobar.draw();
  }
  
  void update() {
    ageDiffInfobar.floatControl.setValue(twinParticlePair.getAgeDiff());
    
    this.twinParticlePair.update();
    
    if (twinParticlePair.isTripComplete()) {
      ((StateControl) prefs.getControl("playStatus")).setState("paused");
    }
  }
}

class TwinParticlePair extends ParticleScene {
  Particle twinA, twinB;
  float relativeSpeed;
  float turnaroundTime;
  float initialAgeTwinB;
  float elapsedTime;
  
  float separation, separationLastUpdate;
  
  boolean returnHasBegun;
  boolean departWhenComplete;
  
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
  
  /** Constructs a new pair of "twin" Particles
    * @param relativeSpeed
    *    The relative speed between the frames of twins A and B,
    *    as a fraction of C
    * @param turnaroundTime
    *    Elapsed time before twinB decelerates and begins to return,
    *    in seconds as measured by twinB
    */
  TwinParticlePair (float relativeSpeed, float turnaroundTime) {
    
    this.relativeSpeed = relativeSpeed;
    this.turnaroundTime = turnaroundTime;
    
    twinA = new Particle();
    twinB = new Particle();
    
    twinA.setName("Twin A");
    twinB.setName("Twin B");
    
    twinA.labelBuilder = new TwinParticleLabelBuilder();
    twinB.labelBuilder = new TwinParticleLabelBuilder();
    
    this.beginDeparture();
    
    this.particles.add(twinA);
    this.particles.add(twinB);
  }
  
  void update() {
    
    elapsedTime = twinB.properTime - initialAgeTwinB;
    
    separationLastUpdate = separation;
    separation = this.getSeparation();
    
    if (!returnHasBegun && elapsedTime > turnaroundTime) {
      this.beginReturn();
    }
    else if (this.isTripComplete()) {
      
      if (departWhenComplete) {
        this.beginDeparture();
      }
      else {
        this.holdPositions();
      }
    }
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
  void holdPositions() {
    twinB.setVelocity(0, 0);
  }
}

class UniformParticleScene extends ParticleScene {
  
  UniformParticleScene(int count) {
    this.particles.addAll( buildUniformParticles(count) );
  }
  
  UniformParticleScene(float dx, float dy, int nx, int ny) {
    this.particles.addAll( buildUniformParticles(dx, dy, nx, ny) );  
  }
  
  List buildUniformParticles(
    float dx,
    float dy,
    int nx,
    int ny
  ) {
    List theParticles = new ArrayList();
    
    for (float i=0; i < nx; i++) {
      for (float j=0; j < ny; j++) {
        Vector3f pos = new Vector3f(i*dx, j*dy, 0);
        Particle p = new Particle(pos, new Velocity());
        theParticles.add(p);
      }
    }
    return theParticles;
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
    
    theParticles = buildUniformParticles(spacing, -spacing, (int)(xLim / spacing), (int)(yLim / spacing));
    //offsetParticles(new Vector3f(xLim/2, yLim/2, 0), theParticles);
    /*
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
    */
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
    
  float cauchyWeightedRandom(float gamma) {
    
    while (true) {
      float x = random(0, gamma*20);
      float probability = cauchyPDF(x, gamma);
      if (probability > random(0, 1)) {
        return x;
      }
    }
  }
  
  float cauchyPDF(float x, float gamma) {
    return 1.0f / (PI*(1 + pow(x / gamma, 2.0)));
  }
}

class AxesScene extends ParticleScene {
  
  AxesScene() {
    
    Particle drivenParticle = new DrivenParticle(new SineVelocityParticleDriver(200, 0.99));
    this.particles.add(drivenParticle);
    
    makeTargetParticle(drivenParticle);
    
    // Secondary Scene
    Scene secondaryScene = new PolygonParticleScene(5, 3);
    this.addSubScene(secondaryScene);
    
    this.scenePrefs.put("PROPERTIME_SCALING", Boolean.FALSE);
    this.scenePrefs.put("toggle_Spatial_Transform", Boolean.FALSE);
    this.scenePrefs.put("toggle_Temporal_Transform", Boolean.FALSE);
  }
}

class LengthContractionScene extends ParticleScene {
  LengthContractionScene() {
    
    //this.sceneControlPanel.putFloat("drivenParticleWavelength", 200, 0, 1000);
    //this.scenePrefs = new ControlMap(new ControlPanel[] { sceneControlPanel });
    
    this.scenePrefs.put("PROPERTIME_SCALING", Boolean.FALSE);
    this.scenePrefs.put("toggle_Spatial_Transform", Boolean.TRUE);
    this.scenePrefs.put("toggle_Temporal_Transform", Boolean.TRUE);
    
    ParticleScene uniformScene = new UniformParticleScene(10, 10, 15, 5);
    this.addSubScene(uniformScene);
    
    Particle drivenParticle = new DrivenParticle(new SineVelocityParticleDriver(200, 0.99));
    this.particles.add(drivenParticle);
    
    makeTargetParticle(drivenParticle);
  }
}

class BellsSpaceShipScene extends ParticleScene {
  
  BellsSpaceShipScene(int numGroups, int shipsPerGroup, float groupSpacing) {
    
    for (int i=0; i < numGroups; i++) {
      ParticleScene groupScene = new PolygonParticleScene(shipsPerGroup, 1);
      
      Vector3f groupOffsetVec = new Vector3f(-i*groupSpacing, 0, 0);
      offsetParticles(groupOffsetVec, groupScene.particles);
      
      List shipBodies = buildRigidBodiesAt(buildTrapezoidVertices(), groupScene.particles);
      addRigidBodies(shipBodies);
      
      addTargets(groupScene.particles);
      this.addSubScene(groupScene);
    }
    makeTargetParticle((Particle) this.getAllParticles().iterator().next());
    
    // BACKGROUND SCENE
    Scene secondaryScene = new RandomParticleScene(prefs.getInteger("PARTICLES"));
    this.addSubScene(secondaryScene);
    
    //this.scenePrefs.put("use_Emissions", Boolean.TRUE);
    this.scenePrefs.put("PROPERTIME_SCALING", Boolean.TRUE);
  }
}

class PolygonParticleScene extends ParticleScene {
  
  PolygonParticleScene(int numVertices, float scale) {
    
    Vector3f pos = new Vector3f();
    Velocity vel = new Velocity();
    
    Vector3f[] polygonPositions = genPolygonVerticesAt(pos, numVertices);
    scaleVectors(polygonPositions, scale);
    
    this.particles = buildParticlesAt(polygonPositions, vel);
  }
}

class Photon extends Particle {

  Photon() {
  }
  
  Photon(Vector3f pos) {
    this(pos, new Velocity(1f, 0));
  }
  
  Photon(Vector3f pos, Velocity vel) {
    super(pos, vel);
    this.velocity.setMagnitude(1);//1-1E-7f);
  }
}

class PhotonScene extends ParticleScene {
  
  PhotonScene() {
    
    Photon p = new Photon(new Vector3f());
    Photon p2 = new Photon(new Vector3f());
    p2.velocity.setDirection(PI);
    
    this.particles.add(p);
    this.particles.add(p2);
    p.setName("Photon");
    p2.setName("Photon2");
    
    Dbg.say("PhotonScene: velocity: " + p.velocity.toString());
    
    Particle drivenParticle = new DrivenParticle(new SineVelocityParticleDriver(100, 0.999));
    this.particles.add(drivenParticle);
    
    addSubScene(new MultiTwinScene(50, 0.5, 0.999, 0.05));
    this.scenePrefs.put("toggle_Spatial_Transform", Boolean.TRUE);
    this.scenePrefs.put("toggle_Temporal_Transform", Boolean.TRUE);
  }
}

class InfolayerScene extends Scene {
  
  Infobox infobox;
  Infopanel infolayerPanel = new Infopanel();
  
  InfolayerScene(Font theFont) {
    
    this.infobox = new Infobox(theFont);//new Infobox(font, fontSize);
    
    this.infolayerPanel.addPane(infobox);
    infobox.pos.set(0, 0);//height - 5 * infobox.lineSize.y);
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

class MenuLayerScene extends Scene {
  
  MenuBarScene menuBarScene;
  
  MenuLayerScene() {
    addSubScene(new MenuBarScene());
    //addSubScene(new SceneMenuScene());
  }
}

class MenuBarScene extends Scene {
  
  Infopanel menuBar;
  SceneMenuScene sceneMenuScene;
  
  class MenuBarToggleVisibleAction extends ToggleVisibleAction {
    
    MenuBarToggleVisibleAction(IToggleVisible target) {
      this.target = target;
    }
    
    void doAction() {
      boolean beforeToggle = target.isVisible();
      
      hideSubsceneMenus();
      target.setVisible(!beforeToggle);
    }
  }
  
  MenuBarScene() {
    sceneMenuScene = new SceneMenuScene(menuClassNames);
    addSubScene(sceneMenuScene);
    
    menuBar = new Infopanel();
    menuBar.setVisible(true);
    
    menuBar.padding.set(10, 1);
    menuBar.pos.y = 0; //menuBar.padding.y;
    menuBar.size.y = menuBar.lineSize.y + 2*menuBar.padding.y;
    
    menuBar.setFlow(Infopanel.RIGHTWARD);
    
    menuBar.addLine("» SCENE MENU ").setClickAction(new MenuBarToggleVisibleAction(sceneMenuScene.menu));
    menuBar.addLine("» DESCRIPTION ").setClickAction(new MenuBarToggleVisibleAction(primaryScene.descriptionPanel));
    
    this.panels.add(menuBar);
  }
  
  void hideSubsceneMenus() {
    
    primaryScene.descriptionPanel.setVisible(false);
    
    for (Iterator iter = subScenes.iterator(); iter.hasNext(); ) {
      Scene subscene = (Scene) iter.next();
      
      for (Iterator iterP = subscene.panels.iterator(); iterP.hasNext(); ) {
        Infopanel panel = (Infopanel) iterP.next();
        
        if (panel != menuBar) {
          panel.setVisible(false);
        }
      }
    }
  }
}

class SceneMenuScene extends Scene {
  
  Infopanel menu;
  
  //class CloseMenuAction extends Action {
  //  void doAction() { menu.setVisible(false);  } }
  
  SceneMenuScene(String[] theMenuClassNames) {
    
    setMenuPanel(this.buildMenu(theMenuClassNames));
  }
  
  void setMenuPanel(Infopanel m) {
    this.panels.add(m);
    this.menu = m;
  }
  
  Infopanel buildMenu(String[] theMenuClassNames) {
    
    Infopanel menu = new Infopanel();
    menu.setVisible(true);
    
    menu.setFlow(Infopanel.RIGHTWARD);
    
    menu.addLine("SCENE MENU  ");
    menu.addLine("» CLOSE").setClickAction(new ToggleVisibleAction(menu));
    
    menu.setFlow(Infopanel.DOWNWARD);
    menu.addLine("");
    
    for (int i=0; i<theMenuClassNames.length; i++) {
      final String className = theMenuClassNames[i];
      
      Infoline theLine = menu.addLine(className);
      theLine.setClickAction( new Action() {
        public void doAction() {
          PRIMARY_SCENE = className;
          restart();
        }
      } );
    }
    return menu;
  }
}
