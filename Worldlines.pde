// Worldlines
// tflorez

import processing.opengl.*;
import javax.media.opengl.GL;
import controlP5.*;

import javax.vecmath.*;
import java.util.List;
import java.awt.geom.Rectangle2D;

import com.sun.opengl.util.texture.*;
import com.sun.opengl.util.BufferUtil;
import java.nio.ByteBuffer;
import java.nio.Buffer;

int SIZE_X = 900, SIZE_Y = 540;
//int SIZE_X = 1280, SIZE_Y = 900;
//int SIZE_X = 1100, SIZE_Y = 700;

PGraphicsOpenGL pgl;
GL gl;

Kamera kamera;

Matrix3f lorentzMatrix;
Matrix3f inverseLorentzMatrix;

Scene topScene;

List scenes;
List particles;
List simultIntersections;
List measurables; // particles and intersections, for now

Scene primaryScene;
InfolayerScene infolayerScene;

Particle targetParticle;
AxesSettings originAxesSettings, targetAxesSettings;

ArrayList targets;
ArrayList emissions;

// RIGID BODIES
RigidBody targetRigidBody;
ArrayList rigidBodies;

Vector3f[] trapezoidVertices = new Vector3f[] {
    new Vector3f(+10, +2.5, 0),
    new Vector3f(+10, -2.5, 0),
    new Vector3f(-10, -10, 0),
    new Vector3f(-10, +10, 0),
};

Vector3f[] bodyVertices = trapezoidVertices;

Selector particleSelector;
Selector labelSelector;
Selector intersectionSelector;

FanSelection myFanSelection;

DefaultFrame originFrame;
DefaultFrame restFrame;

ParticlesLayer particlesLayer;
InputDispatch inputDispatch;

Axes myAxes;

float C = 1.0;

FpsTimer myFpsTimer;

String PRIMARY_SCENE = "MultiTwinScene";

String[] menuClassNames = new String[] {
  "AxesScene",
  "TwinParticleScene",
  "MultiTwinScene",
  "LengthContractionScene",
  "BellsSpaceShipScene",
  "UniformParticleScene",
  "RandomParticleScene",
  "PolygonParticleScene",
  "PhotonScene"
};

// GUI Control Vars
public int PARTICLES = 16;//49;

public int TARGET_COLOR = #F01B5E;
public int PARTICLE_COLOR = #1B83F0;

public int ACTION_COLOR = 0xFF86FF74;//0xFF86FF74; //0xFF6BE359; //0xFFFF1778;
public int ACTION_COLOR_CONTRAST = 0xFF000000;

// Input Device Vars
public boolean MOUSELOOK = false;
public boolean INPUT_RIGHT;
public boolean INPUT_LEFT;
public boolean INPUT_UP;
public boolean INPUT_DOWN;

// Data Files
String PARTICLE_IMAGE = "particle.png";//_reticle.png";
String bundledFont = "VeraMono.ttf";

int FONT_SIZE = 14;

ControlP5 controlP5;

void setup() {
  size(SIZE_X, SIZE_Y, OPENGL);
  
  frameRate(45);
  //hint(DISABLE_DEPTH_SORT);
  
  restart(); //initScene();
}

VTextRenderer myVTextRenderer, infobarVTextRenderer;
Labelor myLabelor;

static ControlMap prefs;

void controlEvent(controlP5.ControlEvent event) {
  prefs.handleControlEvent(event);
}

// CONTROLP5 CALLBACK
public void playStatus() {
  StateControl c = (StateControl) prefs.getControl("playStatus");
  c.setState( (c.getState() == "paused") ? "playing" : "paused" );
  
  Dbg.say("playStatus(): state -> " + c.getState());
  Dbg.say("playStatus(): label -> " + c.getLabel());
}
// CONTROLP5 CALLBACK
public void randomize() {
  
  String[] floatLabels = new String[] {
    "START_POS_DISPERSION",
    //"START_POS_X_SCALE",
    "START_POS_Y_SCALE",
    "START_VEL_DISPERSION", 
    "START_VEL_ECCENTRICITY"
  };
  
  for (int i=0; i<floatLabels.length; i++) {
    String label = floatLabels[i];
    FloatControl control = prefs.getFloatControl(label);
    
    float randomValue = random(control.max);
    control.setValue(randomValue);
  }
  setup();
}
/*
public void transform_to_target_coords() {
  
  prefs.getControl("toggle_Spatial_Transform").setValue()
}
*/

ControlPanel[] buildControlPanels() {
  
  Control restart = new ButtonControl("restart");
  Control randomize = new ButtonControl("randomize");
  StateControl pause = new StateControl("playStatus", "playing", "PAUSE");
  pause.addState("paused", "PLAY");
  ControlPanel panel;
  
  // SETUP PANEL
  ControlPanel setupPanel = new ControlPanel("setup");
  panel = setupPanel;
  //panel.addControl(restart);
  panel.addControl(randomize);
  panel.putInteger("PARTICLES", PARTICLES, 0, PARTICLES*5);
  panel.putInteger("TARGETS", 3, 1, PARTICLES);
  panel.putFloat("START_POS_DISPERSION", 2.6, 0, 4);
  panel.putFloat("START_POS_X_SCALE", 2.6, 0, 3);
  panel.putFloat("START_POS_Y_SCALE", 2.6, 0, 3);
  panel.putFloat("START_VEL_DISPERSION", 5.4, 0, 20);
  panel.putFloat("START_VEL_ECCENTRICITY", 1.95, 0, 15);
  panel.putFloat("START_VEL_X_SCALE", 1);
  panel.putFloat("START_VEL_Y_SCALE", 1);
  
  // MAIN PANEL
  ControlPanel mainPanel = new ControlPanel("default");
  mainPanel.setLabel("MAIN");
  panel = mainPanel;
  panel.addControl(pause);
  panel.addControl(restart);
  panel.putFloat("timestep", 10, 0, 20);
  panel.putBoolean("PROPERTIME_SCALING", true);
  panel.putBoolean("toggle_Spatial_Transform", false);
  panel.putBoolean("toggle_Temporal_Transform", false);
  panel.putBoolean("1-D_control", false);
  panel.putBoolean("show_Rigid_Bodies", true);
  panel.putBoolean("use_Emissions", false);
  //panel.putBoolean("showAxesGrid", false);
  
  targetAxesSettings = new AxesSettings();
  originAxesSettings = new AxesSettings();
  targetAxesSettings.setAxesLabelsVisible(true);
  
  panel.putBoolean("show_Target_Axes_Grid", true).addUpdater(
    new AxesSettingsVisibilityUpdater(targetAxesSettings));
  panel.putBoolean("show_Origin_Axes_Grid", false).addUpdater(
    new AxesSettingsVisibilityUpdater(originAxesSettings));
  panel.putBoolean("show_Particle_Clock_Ticks", true);
  
  // DEBUG PANEL
  ControlPanel debugPanel = new ControlPanel("debug");
  panel = debugPanel;
  panel.putInteger("maxEmissions", 50, 0, 500);
  //panel.putFloat("fov", 60, 0, 180);
  panel.putFloat("backgroundColorHue", 0.65f);// 0.59);// 64//
  panel.putFloat("backgroundColorSaturation", 0.48f);// 0.70);// 53//
  panel.putFloat("backgroundColorBrightness", 0.23f);//0.17f);// 0.31);// 28//
  panel.putFloat("cauchyGamma", 1, 0, 4);
  panel.putFloat("momentumNudge", 0.003, 0, 1);
  panel.putBoolean("energy_Conservation", false);
  panel.putFloat("INPUT_RESPONSIVENESS", 0.13);
  //panel.putBoolean("brehmeDiagramCorrection", false);
  //panel.putFloat("kam_units_scale", 1, 0, 8);
  
  // GRAPHICS PANEL
  ControlPanel graphicsPanel = new ControlPanel("graphics");
  panel = graphicsPanel;
  panel.putFloat("PARTICLE_SIZE", 2.5, 0, 10); //1.3, 0, 10);
  //panel.putFloat("LIGHTING_PARTICLES", 0.75);
  panel.putFloat("LIGHTING_WORLDLINES", 0.8);
  panel.putFloat("STROKE_WIDTH", 2, 0, 8);
  panel.putFloat("HARMONIC_FRINGES", 3.4, 0, 16);
  panel.putFloat("HARMONIC_CONTRIBUTION", 0.5);
  
  ControlPanel[] controlPanels = new ControlPanel[] {
    setupPanel,
    mainPanel,
    debugPanel,
    graphicsPanel
  };
  
  return controlPanels;
}

ControlMap buildPrefs(ControlPanel[] controlPanels) {
  ControlMap oldPrefs = prefs;
  ControlMap newPrefs = new ControlMap(controlPanels);
  
  if (oldPrefs != null) {
    copyControlValues(oldPrefs, newPrefs);
  }
  return newPrefs;
}

ControlP5 buildControlP5(ControlMap thePrefs) {
  
  ControlP5 theControlP5 = new ControlP5(this);
  theControlP5.setAutoDraw(false);
  //controlP5.setColorForeground(#093967);
  thePrefs.buildControlP5(theControlP5);
  
  return theControlP5;
}

//void initScene() {
void restart() {
  
  // BUILD CONTROL PANELS
  ControlPanel[] controlPanels = buildControlPanels();
  
  // BUILD PREFERENCES
  prefs = buildPrefs(controlPanels);
  
  prefs.put("particleImagePath", "particle_hard.png");//"particle_cushioned_core.png");
  prefs.put("particleClockTickImagePath", "particle_clock_tick.png");
  prefs.put("selectedParticleImagePath", "particle_reticle.png");
  prefs.put("startPosWeight", "cauchy");
  
  /*
  // CONTROLP5
  controlP5 = buildControlP5(prefs);
  */
  
  // FONT
  byte[] fontBytes = loadBytes(bundledFont);
  int fontSize = (int)(0.025 * height);
  Font font = loadFont(fontBytes, fontSize);
  
  // TEXT RENDERER
  myVTextRenderer = new VTextRenderer(font.deriveFont(40f), (int)(1*fontSize));
  
  // INFOBOX + LABELOR
  myLabelor = new Labelor();
  
  kamera = new Kamera();
  //kamera.setFov(prefs.getFloat("fov"));
  
  // SCENE OBJECTS
  targets = new ArrayList();
  particles = new ArrayList();
  emissions = new ArrayList();
  rigidBodies = new ArrayList();
  simultIntersections = new ArrayList();
    
  // SCENES
  scenes = new ArrayList();
  topScene = new Scene();
  
  // SELECTABLES
  myFanSelection = null;
  labelSelector = new Selector();
  particleSelector = new Selector(particles);
  intersectionSelector = new Selector();
  
  // INIT LORENTZ FOR PARTICLE CREATION
  Vector3f targetPos = new Vector3f();
  Velocity targetVelocity = new Velocity(0f, 0f); //1E-7f,0f);
  
  lorentzMatrix = Relativity.getLorentzTransformMatrix(targetVelocity);
  inverseLorentzMatrix = Relativity.getInverseLorentzTransformMatrix(targetVelocity);
  
  // TARGET PARTICLES
  targetParticle = new Particle(targetPos, targetVelocity);
  targetParticle.headFrame.axesSettings = targetAxesSettings;
  //makeTargetParticle(targetParticle);
  
  // Target Scene
  /*
  ParticleScene polyScene = new PolygonParticleScene(prefs.getInteger("TARGETS"));
  List polySceneParticles = polyScene.getParticles();
  
  addTargets(polySceneParticles);
  makeTargetParticle((Particle) polySceneParticles.get(0));
  
  // RIGID BODIES
  bodyVertices = buildTrapezoidVertices();
  scaleVectors(bodyVertices, 10);
  
  List polyRigidBodies = buildRigidBodiesAt(bodyVertices, polySceneParticles);
  addRigidBodies(polyRigidBodies);
  */
  
  // FRAMES
  //targetAxesSettings.setAllVisibility(true);
  
  originFrame = new DefaultFrame();
  originFrame.axesSettings = originAxesSettings;
  originAxesSettings.setAllVisibility(false);
  originAxesSettings.setAxesVisible(true);
  
  restFrame = new DefaultFrame();
  restFrame.setVelocity(0,0);
  particlesLayer = new ParticlesLayer(particles, prefs.getString("particleImagePath"), kamera, particleSelector.selection);
  
  inputDispatch = new InputDispatch(targets);
  
  myAxes = new Axes();
  myFpsTimer = new FpsTimer();
  
  // PRIMARY SCENE
  primaryScene = buildScene(PRIMARY_SCENE);
  addScene(primaryScene);
  Dbg.say("got here");
  
  // TODO: PRIMARY SCENE CONTROL PANEL
  //prefs.putControlPanel(primaryScene.sceneControlPanel);
  
  // CONTROLP5
  controlP5 = buildControlP5(prefs);
  
  // load any prefs defined by the PrimaryScene
  for (Iterator iter=primaryScene.scenePrefs.keySet().iterator(); iter.hasNext(); ) {
    String name = (String) iter.next();
    Object value = primaryScene.scenePrefs.get(name);
    
    // If a control, just want the value represented
    if (value instanceof Control) {
      value = ((Control) value).getValue();
    }
    Dbg.say("primaryScene pref: " + name + ", value: " + value);
    Dbg.say("   updatedControl: " + name);//prefs.getControl(name).toString());
    
    // Sync prefs controlmap
    prefs.getControl(name).setValue(value);
    
    // Hack to sync controlP5
    controlP5.controller(name).setValue(parseForControlP5(value));
  }
  
  /*
  // SECONDARY SCENE
  //String secondarySceneName = "RandomScene";
  String secondarySceneName = "UniformScene";
  ParticleScene secondaryScene = buildScene(secondarySceneName);
  addScene(secondaryScene);
  */
  
  // MENULAYER
  MenuLayerScene menuLayerScene = new MenuLayerScene();
  addScene(menuLayerScene);
  
  // INFOLAYER SCENE
  infolayerScene = new InfolayerScene(font);
  addScene(infolayerScene);
  
  // THREADING
  //particleUpdater = new ParticleUpdater(targetParticle, particles);
  //particleUpdater.start();
  
  prefs.notifyAllUpdaters();
}

Vector3f[] buildTrapezoidVertices() {
  return new Vector3f[] {
    new Vector3f(1, 0.25, 0),
    new Vector3f(1, -0.25, 0),
    new Vector3f(-1, -1, 0),
    new Vector3f(-1, +1, 0),
  };
}

List buildRigidBodiesAt(Vector3f[] bodyVertices, Collection theParticles) {
  List theBodies = new ArrayList();
  
  for (Iterator iter=theParticles.iterator(); iter.hasNext(); ) {
    Particle p = (Particle) iter.next();
    RigidBody rb = new RigidBody(p, bodyVertices);
    theBodies.add(rb);
  }
  return theBodies;
}

List buildParticlesAt(Vector3f[] positions, Velocity theVelocity) {
  List theParticles = new ArrayList();
  
  for (int i=0; i < positions.length; i++) {
    Particle p = new Particle(positions[i], theVelocity);
    theParticles.add(p);
  }
  return theParticles;
}

// MANAGEMENT - SCENE, PARTICLE, EMISSION, RIGIDBODIES
void addScene(Scene s) {
  if (s == null) { return; }
  
  topScene.subScenes.add(s);
  
  if (!scenes.contains(s)) {
    scenes.add(s);
  }
  
  if (s instanceof ParticleScene) {
    addParticles( ((ParticleScene)s).getAllParticles() );
  }
}

void addParticles(Collection theParticles) {
  if (theParticles == null) { return; }
  
  for (Iterator iter=theParticles.iterator(); iter.hasNext(); ) {
    Particle p = (Particle) iter.next();
    addParticle(p);
  }
}

void addParticle(Particle p) {
  if (p == null) { return; }
  
  if (!particles.contains(p)) {
    particles.add(p);
  }
  addSelectable(p);
  
  PathPlaneIntersection intersection = new PathPlaneIntersection(p, targetParticle);
  simultIntersections.add(intersection);
  intersectionSelector.selectables.add(intersection);
}

void addSelectable(Particle p) {
  
  if (!particleSelector.selectables.contains(p)) {
    particleSelector.addToSelectables(p);
  }
}

void addTargets(List theParticles) {
  
  for (Iterator iter=theParticles.iterator(); iter.hasNext(); ) {
    Particle p = (Particle) iter.next();
    addTarget(p);
  }
}

void addTarget(Particle p) {
  if (p == null) { return; }
  
  addParticle(p);
  if ( !targets.contains(p) ) {
    targets.add(p);
  }
  //p.velocity.set(targetParticle.velocity);
  p.setFillColor(TARGET_COLOR);
}

void addEmission(Particle e) {
  if ( prefs.getBoolean("use_Emissions") ) {
    
    addParticle(e);
    emissions.add(e);
    particleSelector.addToSelectables(e);
    e.setFillColor(color(0, 1, 0));
    
    if (emissions.size() > prefs.getInteger("maxEmissions")) {
      Particle oldEmission = (Particle) emissions.remove(0);
      particles.remove(oldEmission);
      particleSelector.drop(oldEmission);
    }
  }
}

void addRigidBody(RigidBody rb) {
  if (rb == null) { return; }
  
  rigidBodies.add(rb);
}

void addRigidBodies(List theBodies) {
  
  for (Iterator iter=theBodies.iterator(); iter.hasNext(); ) {
    RigidBody rb = (RigidBody) iter.next();
    addRigidBody(rb);
  }
}

void draw() {  
  pgl = (PGraphicsOpenGL)g;
  gl = pgl.beginGL();
  
  gl.glScalef(1,1,1);
  
  gl.glEnable(GL.GL_BLEND);
  gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE);
  //gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_DST_ALPHA);
  //gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE_MINUS_SRC_ALPHA);
  gl.glDisable(GL.GL_DEPTH_TEST);
  gl.glDepthMask(false);
  
  gl.glLineWidth(prefs.getFloat("STROKE_WIDTH"));
  
  pgl.endGL();
  
  // SCENE PREP
  //color c =  #000020; // #3473F7;//
  //colorMode(HSB, 255); color c = color((frameCount * 0.5)%255, 100, 75, 255);
  
  colorMode(HSB, 1.0f); 
  color c = color(
    prefs.getFloat("backgroundColorHue"),
    prefs.getFloat("backgroundColorSaturation"),
    prefs.getFloat("backgroundColorBrightness")
  );
  
  background(c);
  colorMode(RGB, 1.0f);
  
  // UPDATE SCENE
  for (Iterator iter=scenes.iterator(); iter.hasNext(); ) {
    Scene scene = (Scene)iter.next();
    scene.update();
  }
  
  // UPDATE TARGET
  float dt;
  if (prefs.getState("playStatus") != "paused") {
    
    float secondsPerFrame = myFpsTimer.getSecondsPerFrame();
    float dilationFactor = prefs.getBoolean("PROPERTIME_SCALING") ? targetParticle.velocity.gamma : 1.0;
    
    dt = secondsPerFrame * dilationFactor * prefs.getFloat("timestep");
  }
  else {
    dt = 0;
  }
  //particleUpdater.dt = dt;
  
  // UPDATE TARGET
  targetParticle.update(dt);
  
  lorentzMatrix = Relativity.getLorentzTransformMatrix(targetParticle.velocity);
  inverseLorentzMatrix = Relativity.getInverseLorentzTransformMatrix(targetParticle.velocity);
  Relativity.TOGGLE_SPATIAL_TRANSFORM = prefs.getBoolean("toggle_Spatial_Transform");
  Relativity.TOGGLE_TEMPORAL_TRANSFORM = prefs.getBoolean("toggle_Temporal_Transform");
  
  targetParticle.updateTransformedHist(lorentzMatrix);
  
  for (int i=0; i<particles.size(); i++) {
    Particle p = (Particle) particles.get(i);

    if (p != targetParticle) {
      p.update(dt);
      p.updateTransformedHist(lorentzMatrix);
    }
  }
  
  // CAMERA PREP
  kamera.updateTarget(targetParticle.getDisplayPosition());
  kamera.update();
  
  // UPDATE SELECTORS
  particleSelector.update(kamera);
  intersectionSelector.update(kamera);
  
  if (myFanSelection != null) {
    myFanSelection.update();
  }
  
  // RENDER
  particlesLayer.draw();
  
  inputDispatch.update();
  
  // UPDATE FPS
  myFpsTimer.update();
  
  // PICKER / MOUSE
  drawMouse();
  
  // GUI LAYER
  camera();
  imageMode(CORNERS);
  noLights();
  perspective(PI/3.0, float(width)/float(height), 0.1, 10E7);
  controlP5.draw();
  
  // SCENE-SPECIFIC DRAW ROUTINES
  drawScenes();
  
  // RESET CAMERA
  kamera.commit();
}

void drawScenes() {
  
  // SCENE DESCRIPTION & INFOLAYERS
  //beginCamera();  //rectMode(CORNER); //camera();
    
    Collection allScenes = new ArrayList();
    topScene.getAllScenes(allScenes);
    //intervalSay(45, "allScenes: " + allScenes);
    
    for (Iterator iter=allScenes.iterator(); iter.hasNext(); ) {
      Scene scene = (Scene)iter.next();
      
      scene.draw();
    }
  //endCamera();
}

void drawMouse() {
  Vector3f mouse = kamera.screenToModel(mouseX, mouseY);
  
  pgl = (PGraphicsOpenGL)g;
  gl = pgl.beginGL();
  
  beginCylindricalBillboardGL(mouse.x, mouse.y, mouse.z);
    float s = 5;
    gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE);
    gl.glPushMatrix();
      gl.glColor4f(1, 1, 1, 0.5);
      gl.glScalef(s, s, s);
      gl.glRotatef(35, 0, 0, 1);
      gl.glRotatef(-20, 1, 0, 0);
      gl.glRotatef(0.4*millis(), 0, 1, 0);
      gl.glTranslatef(0, -1, 0);
      glTriangle(gl);
      gl.glRotatef(35, 0, 1, 0);
      glTriangle(gl);
    gl.glPopMatrix();
  endBillboardGL();
  
  pgl.endGL();
}

class InputDispatch {
  ArrayList targets;
  
  float buttonPressure;
  float buttonAccumulateFactor = 0.02;
  float buttonDecayFactor = 0.95;
  
  InputDispatch(ArrayList targets) {
     this.targets = targets;
  }
  
  void update() {
    
    if (INPUT_UP || INPUT_DOWN || INPUT_LEFT || INPUT_RIGHT) {
      
      float x = 0;
      float y = 0;
      
      if      (INPUT_UP)   { y += -1.0; }
      else if (INPUT_DOWN) { y += +1.0; }
      else if (INPUT_LEFT) { x += -1.0; }
      else if (INPUT_RIGHT){ x += 1.0; }
      
      float direction = atan2(y, x);
      float offset = kamera.azimuth - HALF_PI;
      
      buttonPressure += (1 - buttonPressure) * buttonAccumulateFactor;
      constrain(buttonPressure, 0, 1.0);
      
      //println("Nudge: Direction: " + direction / PI);
      //println("Nudge: Offset:    " + offset / PI);
      
      direction = direction + offset;
      
      if (prefs.getBoolean("1-D_control")) {
        direction = atan2( 0, cos(direction));
      }
      
      for (int i=0; i < targets.size(); i++) {
        
        if (prefs.getBoolean("energy_Conservation")) {
          energyNudge((Particle)targets.get(i), direction);
        }
        else {
          nudge((Particle)targets.get(i), direction, buttonPressure); 
        }
      }
    }
    else {
      buttonPressure *= buttonDecayFactor;
    }
    
    updateParticleDragging();
  }
  
  void energyNudge(Particle particle, float theta) {
    float energyAmt = 0.01*particle.mass*C*C;
    particle.emitEnergy(energyAmt, theta+PI);
    
    intervalSay(45, "energyNudge(): energyAmt: " + energyAmt);
  }
  
  void nudge(Particle particle, float theta, float amt) {
      
      float momentumScale = 0.05;
      //float momentumNudge = 0.0001 ;
      float momentumNudge = prefs.getFloat("momentumNudge");
      
      float v_mag = particle.velocity.magnitude;
      
      float p = particle.mass * particle.velocity.gamma * v_mag;
      
      float vx = targetParticle.velocity.vx;
      float vy = targetParticle.velocity.vy;
      
      float heading_initial = particle.velocity.direction;
      
      float angleDiff = heading_initial - theta;
      
      // Help user slow down at high speeds, quickly but smoothly
      if ((v_mag > 0.99999) && abs(abs(angleDiff)-PI) < TWO_PI/3.0) {
        theta = heading_initial + PI + angleDiff * (1.0 - v_mag);
        momentumScale = 0.10;
//        if (particle.impulseTotal > 0.1 * p) {
//          println("particle.impulseTotal > 0.1 : " + particle.impulseTotal);
//          momentumScale = 0.05;
//        }
      }
  
      float dp = amt * (momentumScale * p + momentumNudge);
  
      float dp_x = dp * cos(theta);
      float dp_y = dp * sin(theta);
      
      particle.propelSelf(dp_x, dp_y);
  }
  
  boolean particleDragInProgress() {
    return ( dragInProgress && mouseButton == LEFT
             && !dragParticles.isEmpty() );
             //&& !particleSelector.isEmpty() && clickedParticle != null );
  }
  
  boolean holdingDragParticles() {
    return dragParticles != null && !dragParticles.isEmpty();
  }
  
  boolean shouldDropDragParticles() {
    return holdingDragParticles() && !dragInProgress;
  }
  
  void releaseDragParticles() {
    dragParticles = null;
  }
  
  void updateParticleDragging() {
    
    if ( particleDragInProgress() || holdingDragParticles() ) {
      if (clickedParticle == null) { return; }
      
      // GET INTERSECT WITH PLANE OF CLICKED DRAG PARTICLE
      Vector3f intersect = getMouseToParticlePlaneIntersect(clickedParticle);
      
      Vector3f offset = getOffset(clickedParticle.getPositionVec(), intersect);
      if (offset == null) { return; }
      
      // PREVIEW DROP POSITIONS FOR DRAG PARTICLES
      for (Iterator iter=dragParticles.iterator(); iter.hasNext(); ) {
        Particle p = (Particle) iter.next();
        if (p == null) { continue; }
        
        Vector3f previewPos = new Vector3f();
        previewPos.add(p.getPositionVec(), offset);
        
        // RENDER DRAGGED PARTICLE
        drawDragParticle(previewPos, p);
      }
      
      // DROP IF DRAG IS OVER
      if ( shouldDropDragParticles() ) {
        
        println("droppingDragParticles: offset" + offset + ", dragParticles: ");
        offsetParticles(offset, dragParticles);
        
        // RELEASE DRAG PARTICLES AFTER MOVE
        releaseDragParticles();
        
        // CLEAR CLICKED PARTICLE
        clickedParticle = null;
      }
    }
  }
  
  Vector3f getMouseToParticlePlaneIntersect(Particle theParticle) {
    if (theParticle == null) { return null; }
    
    Vector3f dragPointerDisplayPos = kamera.screenToModel(mouseX, mouseY);
    Vector3f dragPointerPos = Relativity.inverseDisplayTransform(targetParticle.velocity, dragPointerDisplayPos);
    
    Vector3f kameraPos = Relativity.inverseDisplayTransform(targetParticle.velocity, kamera.pos);
    
    Line dragLine = new Line();
    dragLine.defineBySegment(kameraPos, dragPointerPos);
    
    Plane clickedPlane = theParticle.getSimultaneityPlane();
    
    Vector3f intersect = new Vector3f();
    clickedPlane.getIntersection(dragLine, intersect);
    
    return intersect;
  }
  
  void drawDragParticle(Vector3f dragPos, Particle dragParticle) {
    
    Vector3f dragDisplayPos = new Vector3f();
    Relativity.displayTransform(lorentzMatrix, dragPos, dragDisplayPos);
    
    pgl = (PGraphicsOpenGL)g;
    gl = pgl.beginGL();
      
      clickedParticle.drawHeadGL(gl, dragDisplayPos);
      
      DefaultFrame draggedFrame = clickedParticle.headFrame.clone();
      draggedFrame.setPosition(dragPos);
      
      myAxes.drawGL(gl, draggedFrame);

    pgl.endGL();
  }
}

void drawSphere(Vector3f pos, float radius) {
  pushMatrix();
    translate(pos.x, pos.y, pos.z);
    sphere(radius);
  popMatrix();
}

Particle clickedParticle;

boolean isFanSelectionOpen() {
  return labelSelector.selection.contains(myFanSelection);
}

void openFanSelection(ISelectableLabel pickedSelectable) {//Particle pickedParticle) {
  
  List labels = new ArrayList();
  
  labels.add(new SelectableLabel("makeTargetParticle", pickedSelectable));
  labels.add(new SelectableLabel("attachRigidBody", pickedSelectable));
  
  if (getSelectedMeasurables().size() == 2) {
    labels.add(new SelectableLabel("measureDistance", pickedSelectable));
  }
  
  myFanSelection = new FanSelection( pickedSelectable, labels);
  labelSelector.addToSelectables(myFanSelection.getSelectableLabels());
  labelSelector.selection.add(myFanSelection);
}

void closeFanSelection() {
  labelSelector.drop(myFanSelection.getSelectableLabels());
  labelSelector.drop(myFanSelection);
}

// SelectableLabel Actions
void makeTargetParticle(Particle p) {
  addTarget(p);
  
  // SWAP AXES SETTINGS
  //AxesSettings tmp = p.getAxesSettings();
  //p.headFrame.axesSettings = targetParticle.getAxesSettings();
  //targetParticle.headFrame.axesSettings = tmp;
  
  if (targetParticle != null) {
    targetParticle.headFrame.axesSettings = p.getAxesSettings();
  }
  p.headFrame.axesSettings = targetAxesSettings;
  targetParticle = p;
  
  setPlaneParent(targetParticle, simultIntersections);
}

void setPlaneParent(Particle parentPlane, List theIntersections) {
  for (int i=0; i<theIntersections.size(); i++) {
    PathPlaneIntersection intersection = (PathPlaneIntersection) theIntersections.get(i);
    intersection.setPlaneParent(parentPlane);
  }
}

// SelectableLabel Actions
void attachRigidBodies(Collection theParticleAttachTargets) {
  
  Dbg.say("attachRigidBodies(): attachTargets: " + theParticleAttachTargets);
  List bodies = buildRigidBodiesAt(bodyVertices, theParticleAttachTargets);
  addRigidBodies(bodies);
}

// SelectableLabel Actions
void measureDistance(Collection theSelectedMeasurables) {
  Iterator toMeasure = theSelectedMeasurables.iterator();
  
  ISelectableLabel from = (ISelectableLabel) toMeasure.next();
  ISelectableLabel to = (ISelectableLabel) toMeasure.next();
  
  topScene.addMeasurement(new DistanceMeasurement(from, to));
}

Collection getSelectedMeasurables() {
  
  List theSelectedMeasurables = new ArrayList(particleSelector.selection);
  theSelectedMeasurables.addAll(intersectionSelector.selection);
  
  return theSelectedMeasurables;
}

void mousePickedLabel(SelectableLabel sl) {
  
  String label = sl.getLabel();
  Selectable parentSelectable = sl.getParentSelectable();
  
  Dbg.say("mousePickedLabel(): " + label + ", parentSelectable: " + parentSelectable);
  
  Collection theSelectedMeasurables = getSelectedMeasurables();
  
  if (label == "makeTargetParticle" && parentSelectable instanceof Particle) {
    makeTargetParticle((Particle)parentSelectable);
  }
  else if (label == "attachRigidBody" && parentSelectable instanceof Particle) {
    
    Collection attachTargets = new HashSet();
    
    attachTargets.addAll(particleSelector.selection);
    attachTargets.add(parentSelectable);
    
    attachRigidBodies(attachTargets);
  }
  else if (label == "measureDistance" && theSelectedMeasurables.size() == 2) {
    
    measureDistance(theSelectedMeasurables);
  }
}

void mousePickedParticle(Particle pick) {
  
  clickedParticle = pick;
  
  if (mouseButton == RIGHT) {
    openFanSelection(pick);
  }
  else if (mouseButton == LEFT) {
    particleSelector.invertSelectionStatus(pick);
  }
}

void mousePickedIntersection(PathPlaneIntersection pick) {
  
  if (mouseButton == RIGHT) {
    openFanSelection(pick);
  }
  else if (mouseButton == LEFT) {
    intersectionSelector.invertSelectionStatus(pick);
    //Dbg.say("intersectionSelector.selection:" + intersectionSelector.selection);
  }
}

void mousePressedOnBackground() {
  if (mouseButton == LEFT) {
    particleSelector.clear();
    intersectionSelector.clear();
  }
  else if (mouseButton == RIGHT) {
    MOUSELOOK = !MOUSELOOK;
    
    if (MOUSELOOK) {
      cursor(MOVE);
    }
    else {
      cursor(ARROW);//noCursor();
    }
  }
}

void mousePressedOnScene() {
  
  Selectable pickedIntersection = (PathPlaneIntersection) intersectionSelector.pickPoint(kamera, mouseX, mouseY);
  Selectable pickedParticle = (Particle) particleSelector.pickPoint(kamera, mouseX, mouseY);
  Selectable pickedLabel = labelSelector.pickPoint(kamera, mouseX, mouseY);
  
  Selectable pick = (pickedLabel != null) ? pickedLabel : pickedParticle;
  pick = (pick != null) ? pick : pickedIntersection;
  
  //Dbg.say("intersectionSelector.selectables" + intersectionSelector.selectables);
  Dbg.say("pick: " + pick + ", pickedLabel: " + pickedLabel);
  
  if (isFanSelectionOpen() && pickedLabel == null) {
    closeFanSelection();
  }
  else if (pick == null) { //pickedParticle == null && pickedLabel == null) {
    mousePressedOnBackground();
  }
  else if (pickedLabel != null && pickedLabel instanceof SelectableLabel) {
    mousePickedLabel((SelectableLabel)pickedLabel);
  }
  else if (pickedParticle != null) {
    mousePickedParticle((Particle)pickedParticle);
  }
  else if (pick instanceof PathPlaneIntersection) {
    mousePickedIntersection((PathPlaneIntersection) pickedIntersection);
  }
}

void mousePressedOnPane(Infopane clickedPane) {
  clickedPane.doClickAction();
}

void mousePressed() { //Dbg.say("mousePressed(): mouseX: " + mouseX + ", mouseY: " + mouseY);
  
  Infopane clickedPane = topScene.getClickedPane();
  Dbg.say("clickedPane: " + clickedPane );
  
  if (controlP5.window(this).isMouseOver()) {
    return;
  }
  else if ( clickedPane != null ) {
    mousePressedOnPane(clickedPane);
  }
  else {
    mousePressedOnScene();
  }
}

void mouseReleased() {
  
  dragInProgress = false;
}

Collection dragParticles;
boolean dragInProgress;

boolean isMouseOverControlP5() {
  return controlP5.window(this).isMouseOver();
}

boolean isMouseOverClickablePane() {
  return (topScene.getClickedPane() != null);
}

boolean isMouseOverGuiControl() {
  return isMouseOverControlP5() || isMouseOverClickablePane();
}

void mouseDragged() {
  
  if (!dragInProgress && mouseButton == LEFT && !isMouseOverGuiControl()
      && clickedParticle != null) {
      
      dragInProgress = true;
      
      println("mouseDragged(): ");
      println("  clickedParticle: " + clickedParticle);
      
      particleSelector.selection.add(clickedParticle);
      dragParticles = new HashSet(particleSelector.selection);
  }
}

void keyPressed() {
  
  switch (key) {
    case 'w' : INPUT_UP = true; break;
    case 'W' : INPUT_UP = true; break;
    case 'a' : INPUT_LEFT = true; break;
    case 'A' : INPUT_LEFT = true; break;
    case 's' : INPUT_DOWN = true; break;
    case 'S' : INPUT_DOWN = true; break;
    case 'd' : INPUT_RIGHT = true; break;
    case 'D' : INPUT_RIGHT = true; break;
  }
  switch (keyCode) {
    case UP : INPUT_UP = true; break;
    case DOWN : INPUT_DOWN = true; break;
    case LEFT : INPUT_LEFT = true; break;
    case RIGHT : INPUT_RIGHT = true; break;
  }
  
  if (key == ' ') {
    int i = (int) random(prefs.getInteger("PARTICLES"));
    targetParticle = (Particle) particles.get(i);
    addTarget((Particle)particles.get(i));
  }
  else if (key == '1') {
    particleSelector.clear();
  }
  else if (key == '`') {
    infolayerScene.infobox.toggleVisible();
  }
}

void keyReleased() {
  
  switch (key) {
    case 'w' : INPUT_UP = false; break;
    case 'W' : INPUT_UP = false; break;
    case 'a' : INPUT_LEFT = false; break;
    case 'A' : INPUT_LEFT = false; break;
    case 's' : INPUT_DOWN = false; break;
    case 'S' : INPUT_DOWN = false; break;
    case 'd' : INPUT_RIGHT = false; break;
    case 'D' : INPUT_RIGHT = false; break;
  }
  switch (keyCode) {
    case UP : INPUT_UP = false; break;
    case DOWN : INPUT_DOWN = false; break;
    case LEFT : INPUT_LEFT = false; break;
    case RIGHT : INPUT_RIGHT = false; break;
  }
}

