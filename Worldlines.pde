// Worldlines
// tflorez

import processing.opengl.*;
import javax.media.opengl.GL;
import controlP5.*;
import javax.vecmath.*;
import geometry.*;

import com.sun.opengl.util.texture.*;
import com.sun.opengl.util.BufferUtil;
import java.nio.ByteBuffer;
import java.nio.Buffer;

PGraphicsOpenGL pgl;
GL gl;

Kamera kamera;

Matrix3f lorentzMatrix;

ArrayList particles;
Particle targetParticle;
ArrayList targets;
ArrayList emissions;

Selector particleSelector;

DefaultFrame restFrame;

ParticleUpdater particleUpdater;

ParticlesLayer particlesLayer;
InputDispatch inputDispatch;

Axes targetAxes;
ParticleGrid particleGrid;

float C = 1.0;
float timeDelta = 0.2;

// GUI Control Vars
public int MAX_PARTICLES = 500;
public int PARTICLES = MAX_PARTICLES/10; ///3;
public int TARGETS = 1;
public int TARGET_COLOR = #F01B5E;
public int PARTICLE_COLOR = #1B83F0;

public float MAX_START_POS_DISPERSION = 3;
/*
public float START_POS_DISPERSION_X = 0;
public float START_POS_DISPERSION_Y = 0;

public float MAX_START_VEL_DISPERSION = 20;
public float START_VEL_DISPERSION = 5.4; //4.2; //1.8;

public float MAX_START_VEL_ECCENTRICITY = 15;
public float START_VEL_ECCENTRICITY = 1.95;
*/
public void randomize() {
  
  String[] floatLabels = new String[] {
    "START_POS_DISPERSION_X",
    "START_POS_DISPERSION_Y",
    "START_VEL_DISPERSION", 
    "START_VEL_ECCENTRICITY"
  };
  
  for (int i=0; i<floatLabels.length; i++) {
    String label = floatLabels[i];
    FloatControl control = prefs.getFloatControl(label);
    
    float randomValue = random(control.max);
    
    control.setValue(randomValue);
    //prefs.put(label, Float.valueOf(randomValue));
  }
  /*
  START_POS_DISPERSION_X = random(MAX_START_POS_DISPERSION);
  START_POS_DISPERSION_Y = random(MAX_START_POS_DISPERSION);
  START_VEL_DISPERSION = random(MAX_START_VEL_DISPERSION);
  START_VEL_ECCENTRICITY = random(MAX_START_VEL_ECCENTRICITY);
  */
  TARGETS = (int)(random(1, PARTICLES/3));
  setup();
}

public float HARMONIC_FRINGES = 3.4;
public float HARMONIC_FRINGES_MAX = 16;

public float HARMONIC_CONTRIBUTION = 0.5;
public float HARMONIC_CONTRIBUTION_MIN = 0;
public float HARMONIC_CONTRIBUTION_MAX = 1;

public boolean TOGGLE_TIMESTEP_SCALING = true;
public boolean TOGGLE_SPATIAL_TRANSFORM = true;
public boolean TOGGLE_TEMPORAL_TRANSFORM = true;

public void toggleSpatialTransform () {
  TOGGLE_SPATIAL_TRANSFORM = Relativity.TOGGLE_SPATIAL_TRANSFORM ^= true;
}
public void toggleTemporalTransform () {
  TOGGLE_TEMPORAL_TRANSFORM = Relativity.TOGGLE_TEMPORAL_TRANSFORM ^= true;
}

public float PARTICLE_SIZE = 1.3;//0.75;
public float PARTICLE_SIZE_MAX = 10;
public float LIGHTING_PARTICLES = 0.75;
public float LIGHTING_WORLDLINES = 0.8;
public float STROKE_WIDTH = 2.0;
public float STROKE_WIDTH_MAX = 8.0;

public float MAX_INPUT_RESPONSIVENESS = 1.0;
public float INPUT_RESPONSIVENESS = 0.8;

// Input Device Vars
public boolean MOUSELOOK = true;
public boolean INPUT_RIGHT;
public boolean INPUT_LEFT;
public boolean INPUT_UP;
public boolean INPUT_DOWN;

// Data Files
String PARTICLE_IMAGE = "particle.png";//_reticle.png";
String bundledFont = "VeraMono.ttf";

float fpsRecent, prevFrameCount;
float seconds, prevSeconds, deltaSeconds;
float fpsMovingAvg;

ControlP5 controlP5;

String lastControlEventLabel = "";
float lastControlEventValue = 0;

void controlEvent(ControlEvent event) {
  
  Controller controller = event.controller();
  
  String label = controller.label();
  float controllerValue = controller.value();
  
  Object prefValue = (Object) prefs.get(label);
  /*
  if ( (label != lastControlEventLabel) || (controllerValue != lastControlEventValue) ) {
    Dbg.say("ControlEvent : '" + label + "', '" + controllerValue + "' (" + controller + ")");
    lastControlEventLabel = label;
    lastControlEventValue = controllerValue;
  }
  */
  
  if (prefValue != null) {
    
    if (controller instanceof controlP5.Toggle) {
      
      boolean newPrefValue = (controllerValue == 0) ? false : true;
      
      prefs.getBooleanControl(label).setValue(newPrefValue);
      
      Dbg.say("prefs.get('" + label + "') now: " + prefs.get(label));
    }
    else if (controller instanceof controlP5.Slider) {

      prefs.getFloatControl(label).setValue(controllerValue);
    }
  }
  else {
    Dbg.warn("Controller '" + label + "' failed assignment to null preference '" + label + "'");
  }
}

ControlMap buildPreferencesControlMap(ControlPanel[] controlPanels) {
  
  ControlMap controlMap = new ControlMap();
  
  for (int p=0; p<controlPanels.length; p++) { 
    
    ArrayList controls = controlPanels[p].controls;
    
    for (int i=0; i<controls.size(); i++) {
      Control c = (Control) controls.get(i);
      controlMap.putControl(c);
    }
  }
  return controlMap;
}

Hashtable buildPreferences(ControlPanel[] controlPanels) {
  
  Hashtable hash = new Hashtable();
  
  for (int p=0; p<controlPanels.length; p++) { 
    
    ArrayList controls = controlPanels[p].controls;
    
    for (int i=0; i<controls.size(); i++) {
      Control c = (Control) controls.get(i);
      hash.put(c.getLabel(), c.getValue());
    }
  }
  return hash;
}

void setup() {
  size(900, 530, OPENGL);
  ////size(900, 540, OPENGL);
  //size(1280, 900, OPENGL);
  
  frameRate(45);
  //hint(DISABLE_DEPTH_SORT);
  
  initScene();
}

Infobox myInfobox;
ControlPanel[] controlPanels;
ControlMap prefs;
//Hashtable prefs;

void initScene() {
  
  ControlPanel dynamicPanel = new ControlPanel("dynamic");
  dynamicPanel.putBoolean("useEmissions", true);
  dynamicPanel.putBoolean("useGL", true);
  dynamicPanel.putBoolean("showAxesGrid", false);
  //dynamicPanel.putBoolean("useMatrixForPathTransform", true);
  dynamicPanel.putFloat("backgroundColorHue", 0.65f);
  dynamicPanel.putFloat("backgroundColorSaturation", 0.65f);
  dynamicPanel.putFloat("backgroundColorBrightness", 0.17f);
  dynamicPanel.putFloat("kam_units_scale", 1, 0, 8);
  
  ControlPanel setupPanel = new ControlPanel("setup2");
  setupPanel.putFloat("START_POS_DISPERSION_X", 2.6, 0, 3);
  setupPanel.putFloat("START_POS_DISPERSION_Y", 2.6, 0, 3);
  setupPanel.putFloat("START_VEL_DISPERSION", 5.4, 0, 20);
  setupPanel.putFloat("START_VEL_ECCENTRICITY", 1.95, 0, 15);
  
  if (controlPanels == null ) {
    controlPanels = new ControlPanel[] { setupPanel, dynamicPanel };
  }
  
  // PREFERENCES
  prefs = buildPreferencesControlMap(controlPanels);
  
  prefs.put("particleImagePath", "particle.png");
  prefs.put("selectedParticleImagePath", "particle_reticle.png");
  
  Dbg.say("prefs.getFloat(\"START_POS_DISPERSION_X\"): " + prefs.getFloat("START_POS_DISPERSION_X"));
  Dbg.say("prefs.getFloat(\"backgroundColorBrightness\"): " + prefs.getFloat("backgroundColorBrightness"));
  
  myInfobox = new Infobox(loadBytes(bundledFont), (int)(0.025 * height));
  
  String tabLabel;
  int numGlobalControls = 0;
  int numTabControls = 0;
  
  int bWidth = 20;
  int bHeight = 20;
  int bSpacingY = bHeight + 15;
  int sliderWidth = bWidth*5;
  
  int xOffsetGlobal = 10;
  
  controlP5 = new ControlP5(this);
  controlP5.setAutoDraw(false);
  controlP5.setColorForeground(#093967);
  
  // Global Controls (All Tabs)
  //controlP5.addButton("setup", 0, xOffsetGlobal, ++numGlobalControls*bSpacingY, 2*bWidth, bHeight).moveTo("global");
  //controlP5.controller("setup").setLabel("RESTART");
  controlP5.addButton("initScene", 0, xOffsetGlobal, ++numGlobalControls*bSpacingY, 2*bWidth, bHeight).moveTo("global");
  controlP5.controller("initScene").setLabel("RESTART");
  controlP5.addButton("randomize", 0, (int)3*bWidth, numGlobalControls*bSpacingY, (int)(2.6*bWidth), bHeight).moveTo("global");
  controlP5.addSlider("PARTICLES", 0, MAX_PARTICLES, PARTICLES, 10, ++numGlobalControls*bSpacingY, sliderWidth, bHeight).moveTo("global");
  
  int yOffsetGlobal = numGlobalControls*bSpacingY + bHeight;
  
  // Main Tab
  tabLabel = "Main";
  controlP5.tab("default").setLabel(tabLabel);
  numTabControls = numGlobalControls;
  controlP5.addSlider("HARMONIC_FRINGES", 0, HARMONIC_FRINGES_MAX, HARMONIC_FRINGES, 10, ++numTabControls*bSpacingY, sliderWidth, bHeight);
  controlP5.addSlider("HARMONIC_CONTRIBUTION", HARMONIC_CONTRIBUTION_MIN, HARMONIC_CONTRIBUTION_MAX, HARMONIC_CONTRIBUTION, 10, ++numTabControls*bSpacingY, sliderWidth, bHeight);
  controlP5.addSlider("INPUT_RESPONSIVENESS", 0f, MAX_INPUT_RESPONSIVENESS, INPUT_RESPONSIVENESS, 10, ++numTabControls*bSpacingY, sliderWidth, bHeight);
  controlP5.addSlider("PARTICLE_SIZE", 0f, PARTICLE_SIZE_MAX, PARTICLE_SIZE, 10, ++numTabControls*bSpacingY, sliderWidth, bHeight);
  controlP5.addSlider("LIGHTING_PARTICLES", 0f, 1.0f, LIGHTING_PARTICLES, 10, ++numTabControls*bSpacingY, sliderWidth, bHeight);
  controlP5.addSlider("LIGHTING_WORLDLINES", 0f, 1.0f, LIGHTING_WORLDLINES, 10, ++numTabControls*bSpacingY, sliderWidth, bHeight);
  controlP5.addSlider("STROKE_WIDTH", 0f, STROKE_WIDTH_MAX, STROKE_WIDTH, 10, ++numTabControls*bSpacingY, sliderWidth, bHeight);
  controlP5.addToggle("TOGGLE_TIMESTEP_SCALING",TOGGLE_TIMESTEP_SCALING,10,++numTabControls*bSpacingY,bWidth,bHeight);
  controlP5.addToggle("toggleSpatialTransform", TOGGLE_SPATIAL_TRANSFORM, 10, ++numTabControls*bSpacingY,bWidth,bHeight);
  controlP5.addToggle("toggleTemporalTransform", TOGGLE_TEMPORAL_TRANSFORM, 10, ++numTabControls*bSpacingY,bWidth,bHeight);
  
  Relativity.TOGGLE_SPATIAL_TRANSFORM = TOGGLE_SPATIAL_TRANSFORM;
  Relativity.TOGGLE_TEMPORAL_TRANSFORM = TOGGLE_TEMPORAL_TRANSFORM;
  /*
  // Setup Tab
  tabLabel = "SETUP";
  controlP5.addTab(tabLabel);
  numTabControls = numGlobalControls;
  controlP5.addSlider("START_POS_DISPERSION_X", 0, MAX_START_POS_DISPERSION, START_POS_DISPERSION_X, 10, ++numTabControls*bSpacingY, sliderWidth, bHeight).moveTo(tabLabel);
  controlP5.addSlider("START_POS_DISPERSION_Y", 0, MAX_START_POS_DISPERSION, START_POS_DISPERSION_Y, 10, ++numTabControls*bSpacingY, sliderWidth, bHeight).moveTo(tabLabel);
  controlP5.addSlider("START_VEL_DISPERSION", 0, MAX_START_VEL_DISPERSION, START_VEL_DISPERSION, 10, ++numTabControls*bSpacingY, sliderWidth, bHeight).moveTo(tabLabel);
  controlP5.addSlider("START_VEL_ECCENTRICITY", 0, MAX_START_VEL_ECCENTRICITY, START_VEL_ECCENTRICITY, 10, ++numTabControls*bSpacingY, sliderWidth, bHeight).moveTo(tabLabel);
  */
  // Dynamic Tab (TESTING)
  for (int panelIndex=0; panelIndex<controlPanels.length; panelIndex++) {
    ControlPanel panel = controlPanels[panelIndex];
    tabLabel = panel.name;
    
    controlP5.addTab(tabLabel);
    
    boolean defaultValue = false;
    int xPadding = 10;
    int yPadding = 15;
    
    int toggleWidth = 20;
    int toggleHeight = 20;
    
    int xOffset = xOffsetGlobal;
    int yOffset = yPadding + yOffsetGlobal;
    
    for (int i=0; i<panel.controls.size(); i++) {
      Control control = (Control) panel.controls.get(i);
      
      Object prefValue = control.getValue();
      String label =  control.getLabel();
      
      String className = prefValue.getClass().getName();
      
      println("Controller for control('" + label + "' : " + prefValue + ") (" + className +")");
      
      if (prefValue instanceof java.lang.Boolean) {
        
        controlP5.addToggle(label, (Boolean) prefValue, xOffset, yOffset, toggleWidth, toggleHeight).moveTo(tabLabel);
        //Toggle t = (Toggle) controlP5.controller(keyName);
        
        yOffset += toggleHeight + yPadding;
      }
      else if (prefValue instanceof java.lang.Float) {
        float minValue = ((FloatControl)control).min;
        float maxValue = ((FloatControl)control).max;
        
        controlP5.addSlider(label, minValue, maxValue, (Float) prefValue, xOffset, yOffset, sliderWidth, bHeight).moveTo(tabLabel);
        yOffset += bHeight + yPadding;
      }
    }
  }
  
  Velocity targetVelocity = new Velocity(1E-7f,0f);
  lorentzMatrix = Relativity.getLorentzTransformMatrix(targetVelocity);
  
  // SCENE OBJECTS
  //targetParticle = new Particle(targetPos, targetVel);
  //addTarget(targetParticle);
  targetParticle = new Particle();
  targetParticle.setVelocity(targetVelocity.vx, targetVelocity.vy);
  targetParticle.setPosition(0, 0, 0);
  targetParticle.setFillColor(color(#F01B5E));
  
  particles = new ArrayList();
  particles.add(targetParticle);
  
  for(int i=1; i<PARTICLES; i++){
    
    float x = pow(10, prefs.getFloat("START_POS_DISPERSION_X"));
    float y = pow(10, prefs.getFloat("START_POS_DISPERSION_Y"));
    
    Vector3f pos = new Vector3f(random(-x, +x), random(-y, +y), 0);
    
    // Exponentially weight distribution of velocities towards lightspeed
    float vel_mag = 1-pow(random(1, 2), -prefs.getFloat("START_VEL_DISPERSION"));
    float heading = random(TWO_PI);
    
    float vx = vel_mag*cos(heading);
    float vy = vel_mag*sin(heading)*(pow(1.5, -prefs.getFloat("START_VEL_ECCENTRICITY")));
    
    Vector3f vel = new Vector3f(vx, vy, 0);
    
    Particle p = new Particle(pos, vel);
    p.setFillColor(color(#1B83F0));
    particles.add(p);
  }
  
  println("target pos: " + targetParticle.position.x + ", " + targetParticle.position.y);
  println("target direction: " + targetParticle.velocity.direction);
  println("target magnitude: " + targetParticle.velocity.magnitude);
  println("target gamma:     " + targetParticle.velocity.gamma);
  
  targets = new ArrayList();
  for (int i=0; i<TARGETS; i++) {
    addTarget((Particle)particles.get(i));
  }
  
  emissions = new ArrayList();
  
  kamera = new Kamera();
  
  restFrame = new DefaultFrame();
  restFrame.setVelocity(0,0);
  
  particleSelector = new Selector(particles);
  particlesLayer = new ParticlesLayer(particles, PARTICLE_IMAGE, kamera, particleSelector.selection);
  
  inputDispatch = new InputDispatch(targets);
  
  particleGrid = new ParticleGrid(3*50, 5*1000);
  targetAxes = new Axes((Frame)targetParticle);
  
  Velocity restFrameVel = new Velocity(0, 0);
  
  // THREADING
  particleUpdater = new ParticleUpdater(targetParticle, particles);
  //Relativity.loadFrame(targetParticle);
  //particleUpdater.start();
}

void addTarget(Particle p){
  targets.add(p);
  p.velocity.set(targetParticle.velocity);
  p.setFillColor(TARGET_COLOR);
}

void addEmission(Particle e){
  if ( prefs.getBoolean("useEmissions") ) {
    emissions.add(e);
    particles.add(e);
    e.setFillColor(color(0, 1, 0));
  }
}

float[] vel = new float[3];

void draw() {
  pgl = (PGraphicsOpenGL)g;
  gl = pgl.beginGL();
  
  gl.glScalef(1,1,1);
  
  gl.glEnable(GL.GL_BLEND);
  //gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE);
  gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_DST_ALPHA);
  //gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE_MINUS_SRC_ALPHA);
  gl.glDisable(GL.GL_DEPTH_TEST);
  gl.glDepthMask(false);
  
  gl.glLineWidth(STROKE_WIDTH);
  pgl.endGL();
  
  // SCENE PREP
  //color c = #000020; //#3473F7;
  colorMode(HSB, 1.0f); //c = color((frameCount * 0.5)%255, 100, 75, 255);
  color c = color(
    prefs.getFloat("backgroundColorHue"),
    prefs.getFloat("backgroundColorSaturation"),
    prefs.getFloat("backgroundColorBrightness")
  );
  background(c); //background((Float)prefs.get("backgroundColor"));
  colorMode(RGB, 1.0f);
  //directionalLight(LIGHTING_PARTICLES, LIGHTING_PARTICLES, LIGHTING_PARTICLES, 0.5, 0.5, -0.5);
  //directionalLight(LIGHTING_PARTICLES, LIGHTING_PARTICLES, LIGHTING_PARTICLES, 0.5, -0.5, -0.5);
  strokeWeight(STROKE_WIDTH);
  
  // UPDATE SCENE
  inputDispatch.update();
  
  float dilationFactor = TOGGLE_TIMESTEP_SCALING ? targetParticle.velocity.gamma : 1.0;
  float dt = timeDelta * dilationFactor;
  
  particleUpdater.dt = dt;
  
  targetParticle.update(dt);
  
  //Relativity.loadFrame(targetParticle);
  lorentzMatrix = Relativity.getLorentzTransformMatrix(targetParticle.velocity);
  
  targetParticle.updateTransformedHist(lorentzMatrix);
  
  boolean SIMPLE_UPDATES = true;
  
  if (SIMPLE_UPDATES){
    
    for (int i=0; i<particles.size(); i++) {
      Particle p = (Particle)particles.get(i);
      if (p == targetParticle) {
        continue;
      }
      else {
        p.update(dt);
        p.updateTransformedHist(lorentzMatrix);
      }
    }
  }/*
  else {
    // UPDATE TARGET  
    targetParticle.update(dt);  
    targetParticle.updateTransformedHist(lorentzMatrix);
    
    // UPDATE NON-TARGETS
    for (int i=0; i<PARTICLES; i++) {
      Particle p = (Particle)particles.get(i);
      
      if (p == targetParticle)
      {
        continue;
      }
      else if( p.xyt_prime[2] > targetParticle.prime[2] )
      {
        p.updateTransformedHist(lorentzMatrix);
        continue;
      } 
      else {
        p.update(dt);
        p.updateTransformedHist(lorentzMatrix);
      }
    }
  }
  */
  // CAMERA PREP
  kamera.updateTarget(targetParticle.getDisplayPosition());
  kamera.update(timeDelta);
  
  // RENDER
  particlesLayer.draw(); //particleGrid.draw(targetParticle.xyt);
  
  // PICKING PROCESS
  
  Vector3f model = kamera.screenToModel(mouseX, mouseY);
  
  pgl = (PGraphicsOpenGL)g;
  gl = pgl.beginGL();
  
  beginCylindricalBillboardGL(model.x, model.y, model.z);
  float s = 0.1; //0.03;
  gl.glScalef(s, s, s);
  gl.glRotatef(25, 0, 0, 1);
  gl.glRotatef(20, 1, 0, 0);
  gl.glRotatef(0.4*millis(), 0, 1, 0);
  gl.glTranslatef(0, -1, 0);
  glTriangle(gl);
  //gl.glTranslatef(0, 0, -0.1);
  gl.glRotatef(35, 0, 1, 0);
  glTriangle(gl);
  endBillboardGL();
  
  pgl.endGL();
  
  // UPDATE FPS
  seconds = 0.001 * millis();
  deltaSeconds = seconds - prevSeconds;
  
  if (deltaSeconds > 1) {
    fpsRecent = (frameCount - prevFrameCount) / deltaSeconds;
    prevSeconds = seconds;
    prevFrameCount = frameCount;
  }
  
  float[] p1 = targetParticle.getDisplayPosition();
  
  // INFO LAYER
  myInfobox.print(
  + (int) seconds + " seconds\n"
  + (int) fpsRecent +  "fps (" + (int)(frameCount / seconds) + "avg)\n"
  + "particles: " + particles.size() + "\n"
  //+ "targetParticle.pos.z: " + nf(targetParticle.position.z, 3, 2) + " seconds\n"
  //+ "kamera.target.x:      " + nf(kamera.target.x, 3, 2) + " seconds\n"
  + "target age:        " + nf(targetParticle.properTime, 3, 2) + " seconds\n"
  + "target speed:      " + nf(targetParticle.velocity.magnitude, 1, 8) + " c\n"
  + "target gamma:      " + nf(targetParticle.velocity.gamma, 1, 8) + " c\n"
  + "target position:   " + targetParticle.position.toString() + "\n"
  + "target displayPos: " + p1[0] + " " + p1[1] + " " + p1[2]
  //+ "Controls: W,A,S,D to move; Right mouse button toggles camera rotation"
  );
  
  // GUI LAYER
  imageMode(CORNERS);
  camera();
  noLights(); //lights();
  perspective(PI/3.0, float(width)/float(height), 0.1, 10E7);
  
  controlP5.draw();
}

class ParticlesLayer {
  ArrayList particles;
  ArrayList selection;
  
  PImage particleImage;
  Kamera kamera;
  
  boolean useGL = true;
  
  Texture particleTexture;
  Texture selectedParticleTexture;
  
  int[] textures = new int[3];
    
  ParticlesLayer (ArrayList particles, String particleImagePath, Kamera kamera, ArrayList selection) {
    this.particles = particles;
    this.selection = selection;
    
    this.kamera = kamera;
    this.particleImage = loadImage(particleImagePath);
    //this.particleTexture = loadTexture(particleImagePath);
    pgl = (PGraphicsOpenGL)g;
    gl = pgl.beginGL();
    this.particleTexture = loadTextureFromStream(openStream(particleImagePath));
    //println("prefs.getString('selectedParticleImagePath'): " + prefs.getString("selectedParticleImagePath"));
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
      //TextureData td = TextureIO.newTextureData(textureStream, true, TextureIO.PNG);
      //texture = TextureIO.newTexture(td);
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
    
    restFrame.setPosition(targetParticle.getPosition());
    Frame[] displayFrames = new Frame[] {restFrame, targetParticle};
        
    // GL SECTION BEGIN
    pgl = (PGraphicsOpenGL)g;
    gl = pgl.beginGL();
    
    //targetParticle.drawHeadGL(gl);
    
    Vector3f intersection = new Vector3f();
    Vector3f[] intersections = new Vector3f[particles.size()*displayFrames.length];
    int intersectionCount = 0;
    
    for (int i=0; i < particles.size(); i++) {
      Particle p = (Particle)particles.get(i);
            
      p.drawPathGL(gl);
      
      if ( !emissions.contains(p) ) {
        targetAxes.drawGL(gl, (Frame)p);
      }
      
      for (int j=0; j < displayFrames.length; j++) {
        
        intersection = p.getIntersection(displayFrames[j]);
        
        intersections[intersectionCount++] = intersection;
        
        p.drawHeadGL(gl, intersection);
      }
    }
    pgl.endGL();
    
    if (prefs.getBoolean("useGL")) {
      
      pgl.beginGL();
      
      particleTexture.enable(); //gl.glEnable(GL.GL_TEXTURE_2D); //gl.glEnable(particleTexture.getTarget());
      particleTexture.bind(); //gl.glBindTexture(GL.GL_TEXTURE_2D, textures[0]); //gl.glTexEnvf(GL.GL_TEXTURE_ENV, GL.GL_TEXTURE_ENV_MODE, GL.GL_MODULATE);
      
      Vector3f toParticle = new Vector3f();
      
      for (int i=0; i<intersectionCount; i++) {
        Particle p = (Particle)particles.get(i/2);
        
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
      particleTexture.disable(); //particleTexture.dispose(); //gl.glDisable(GL.GL_TEXTURE_2D);
      
      // SELECTION DISPLAY
      selectedParticleTexture.bind();
      selectedParticleTexture.enable();
      
      Vector3f displayPos = new Vector3f();
      //Vector3f toParticle = new Vector3f();
      
      gl.glColor4f(1, 1, 1, 0.5);
      for (int i=0; i<selection.size(); i++) {
        Particle p = (Particle) selection.get(i);
        
        displayPos = p.getDisplayPositionVec();
        
        toParticle.sub(displayPos, kamera.pos);
        
        float distToParticle = toParticle.length();
        float scale = 0.25*distToParticle;
        
        beginCylindricalBillboardGL(displayPos.x, displayPos.y, displayPos.z);
          gl.glScalef(scale, scale, scale);
          simpleQuadGL(gl);
        endBillboardGL();
      }
      selectedParticleTexture.disable();
      
      pgl.endGL();
    }
    else {
    
      // PROCESSING SECTION
      imageMode(CENTER);
      
      Vector3f toParticle = new Vector3f();
      float distToParticle;
      
      for (int i=0; i<intersectionCount; i++) {
        Particle p = (Particle)particles.get(i/2);
        
        float[] pos = new float[3];
        intersections[i].get(pos);
        
        toParticle.set(intersections[i]);
        toParticle.sub(kamera.pos);
        
        distToParticle = toParticle.length();
        
        float pulseFactor = 1 - 0.5*sin(p.properTime);
        //float dim = LIGHTING_PARTICLES * constrain(distToParticle * 0.005, 0, 1);
        
        //scale *= PARTICLE_SIZE * 0.1 * pulseFactor*0.0015*log(distToParticle);
        float scale = PARTICLE_SIZE * 0.1 * pulseFactor*0.0015*distToParticle;
        
        tint(lerpColor(#FFFFFF, p.fillColor, 0.5*pulseFactor), pulseFactor);
        
        p.drawHead(pos[0], pos[1], pos[2]);
        drawBillboard(particleImage, scale, kamera, pos[0], pos[1], pos[2]);
        
        noTint();
      }
    }
  }
}

void simpleQuadGL(GL gl, float x, float y, float z) {
  gl.glPushMatrix();
  gl.glTranslatef(x, y, z);
  simpleQuadGL(gl);
  gl.glPopMatrix();
}

void simpleQuadGL(GL gl) {
  gl.glBegin(GL.GL_QUADS);
  gl.glTexCoord2f(1,1); gl.glVertex2f(1,1);
  gl.glTexCoord2f(1,0); gl.glVertex2f(1,-1);
  gl.glTexCoord2f(0,0); gl.glVertex2f(-1,-1);
  gl.glTexCoord2f(0,1); gl.glVertex2f(-1,1);
  gl.glEnd();
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
      
      for (int i=0; i < targets.size(); i++) {
        
        nudge((Particle)targets.get(i), direction + offset, buttonPressure); 
      }
    }
    else {
      buttonPressure *= buttonDecayFactor;
    }
  }
  
  void nudge(Particle particle, float theta, float amt) {
      
      float momentumScale = 0.05;
      float momentumNudge = 0.0001 ;
      
      float v_mag = particle.velocity.magnitude;
      
      float p = particle.mass * particle.velocity.gamma * v_mag;
      
      float vx = targetParticle.velocity.vx;
      float vy = targetParticle.velocity.vy;
      
      float heading_initial = particle.velocity.direction;
      
      float angleDiff = heading_initial - theta;
      
      // Help user slow down at high speeds, quickly but smoothly
      if ((v_mag > 0.99999) && abs(abs(angleDiff)-PI) < TWO_PI/5.0) {
        theta = heading_initial + PI + angleDiff * (1.0 - v_mag);
        momentumScale = 0.5;
      }
  
      float dp = amt * (momentumScale * p + momentumNudge);
  
      float dp_x = dp * cos(theta);
      float dp_y = dp * sin(theta);
      
      //particle.addImpulse(dp_x, dp_y);
      particle.propelSelf(dp_x, dp_y);
  }
}

void mousePressed() {
  
  if (mouseButton == RIGHT) {
    MOUSELOOK = !MOUSELOOK;
    //cursor(MOUSELOOK ? MOVE : ARROW);
    if (MOUSELOOK) {
      cursor(MOVE);
    } else {
      noCursor();
    }
  }
  else if (mouseButton == LEFT) {
    Vector3f direction = new Vector3f();
    
    direction.sub(kamera.screenToModel(mouseX, mouseY), kamera.pos);
    Particle particle = particleSelector.pickPoint(kamera.pos, direction);
    
    particleSelector.invertSelectionStatus(particle);
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
     
  if (key == ' ') {
    int i = (int)random(PARTICLES);
    targetParticle = (Particle) particles.get(i);
    targetParticle.setFillColor(color(#F01B5E));
    targets.add(particles.get(i));
  }
  
  if (key == 'g' || key == 'G') {
    particlesLayer.useGL = !particlesLayer.useGL;
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
}

void intervalSay(int frameInterval, String msg) {
  if (frameCount % frameInterval == 0) {
    Dbg.say(msg);
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

class Selector {
  ArrayList selectables;
  ArrayList selection;
  
  Selector (ArrayList theSelectables, ArrayList theSelection) {
    this.selectables = theSelectables;
    this.selection = theSelection;
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
  
  Particle pickPoint(Vector3f cameraPos, Vector3f pickingRayDirection) {
    
    Particle bestPick = null;
    
    float distToBestPick = Float.MAX_VALUE;
    float angleToBestPick = PI;
    
    float minSelectionAngle = radians(5);
    float minAngleToPreferClosest = radians(1.5);
    
    Particle p;
    
    Vector3f cameraToParticle = new Vector3f();
    
    for (int i=0; i<selectables.size(); i++) {
      
      p = (Particle) selectables.get(i);
      
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
    }
    
    if (angleToBestPick < minSelectionAngle) {
      return bestPick;
    }
    else {
      return null;
    }
  }
}

