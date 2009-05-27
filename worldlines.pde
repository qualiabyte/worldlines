//Worldlines
//tflorez

import processing.opengl.*;
import javax.media.opengl.GL;
import controlP5.*;

PGraphicsOpenGL pgl;
GL gl;

Kamera kamera;

Particle origin;
Particle[] particles;

Particle targetParticle;
PVector target;
PVector prevTarget;

float timeDelta = 0.2;

boolean MOUSELOOK = true;

int MAX_PARTICLES = 1000;
int PARTICLES = MAX_PARTICLES/3;

float MAX_START_POS_DISPERSION = 6;
float START_POS_DISPERSION = 0;

float MAX_START_VEL_DISPERSION = 20;
float START_VEL_DISPERSION = 1.8;

float MAX_START_VEL_ECCENTRICITY = 15;
float START_VEL_ECCENTRICITY = 0;

float HARMONIC = 3.4;
float HARMONIC_MAX = 16;

String bundledFont = "VeraMono.ttf";

float fpsRecent, prevFrameCount;
float seconds, prevSeconds, deltaSeconds;
float fpsMovingAvg;

ControlP5 controlP5;
boolean toggleTimestepScaling = false;
float LIGHTING = 0.75;
float STROKE_WIDTH = 0.8;

Infobox myInfobox;

void setup() {
  size(900, 540, OPENGL);
  
  int nControls = 0;
  int bWidth = 20;
  int bHeight = 20;
  int bSpacingY = bHeight + 15;
  int sliderWidth = bWidth*5;
  
  controlP5 = new ControlP5(this);
  controlP5.setAutoDraw(false);
  controlP5.addButton("setup", 0, 10, ++nControls*bSpacingY, 2*bWidth, bHeight).setLabel("RESTART");
  controlP5.addSlider("START_POS_DISPERSION", 0, MAX_START_POS_DISPERSION, START_POS_DISPERSION, 10, ++nControls*bSpacingY, sliderWidth, bHeight);
  controlP5.addSlider("START_VEL_DISPERSION", 0, MAX_START_VEL_DISPERSION, START_VEL_DISPERSION, 10, ++nControls*bSpacingY, sliderWidth, bHeight);
  controlP5.addSlider("START_VEL_ECCENTRICITY", 0, MAX_START_VEL_ECCENTRICITY, START_VEL_ECCENTRICITY, 10, ++nControls*bSpacingY, sliderWidth, bHeight);
  controlP5.addToggle("toggleTimestepScaling",false,10,++nControls*bSpacingY,bWidth,bHeight);
  controlP5.addSlider("PARTICLES", 0, MAX_PARTICLES, PARTICLES, 10, ++nControls*bSpacingY, sliderWidth, bHeight);
  controlP5.addSlider("HARMONIC", 0, HARMONIC_MAX, HARMONIC, 10, ++nControls*bSpacingY, sliderWidth, bHeight);
  controlP5.addSlider("LIGHTING", 0f, 1.0f, 1.0f, 10, ++nControls*bSpacingY, sliderWidth, bHeight);
  controlP5.addSlider("STROKE_WIDTH", 0f, 5f, 0.8f, 10, ++nControls*bSpacingY, sliderWidth, bHeight);

  File fontFile = new File(dataPath(bundledFont));
  myInfobox = new Infobox(fontFile, (int)(0.025 * height));

  origin = new Particle(new PVector(0,0,0), new PVector(0,0,0));
  origin.fillColor = color(#F01B5E);//#48F01B);//
  
  particles = new Particle[MAX_PARTICLES];

  for(int i=0; i<MAX_PARTICLES; i++){

    //PVector pos = new PVector(0,0);
    //PVector pos = new PVector(random(-100, 100), random(-100, 100), 0);
    PVector pos = new PVector(random(pow(10, -START_POS_DISPERSION)),random(pow(10, START_POS_DISPERSION)));

    float heading = random(TWO_PI);
    
    // Exponentially weight distribution of velocities towards lightspeed
    float vel_mag = 1-pow(random(1, 2), -START_VEL_DISPERSION);
    
    PVector vel = new PVector(vel_mag*cos(heading), vel_mag*sin(heading)*(pow(1.5, -START_VEL_ECCENTRICITY)));
    
    particles[i] = new Particle(pos, vel);
    particles[i].fillColor = color(#1B83F0);
    /*
    colorMode(HSB, 1.0);
    color c = color(random(1), 0.8, 1.0);

    particles[i].setPathColor(c);
    
    colorMode(RGB, 255);
    */
  }
  
  targetParticle = origin;
  
  kamera = new Kamera();
  kamera.target = targetParticle.pos.get();

//  strokeWeight(1);
  frameRate(90);
  //hint(DISABLE_DEPTH_SORT);
}

void draw() {
  
  pgl = (PGraphicsOpenGL)g;
  gl = pgl.beginGL();
  
  gl.glEnable(GL.GL_BLEND);
  gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE);
  gl.glDisable(GL.GL_DEPTH_TEST);
  gl.glDepthMask(false);
  
  gl.glClear(GL.GL_DEPTH_BUFFER_BIT);
  pgl.endGL();
  background(30);
  noLights();
  
  directionalLight(LIGHTING, LIGHTING, LIGHTING, 0.5, 0.5, -1);
  directionalLight(LIGHTING, LIGHTING, LIGHTING, -0.5, -0.5, -1);
  
  kamera.target = targetParticle.pos.get();
  kamera.update(timeDelta);
  
  kamera.azimuthVel += PI * 0.002;
  
  float dilationFactor = toggleTimestepScaling ? 
                         Relativity.gamma(targetParticle.vel) : 1;
  
  for (int i=0; i<PARTICLES; i++) {
    particles[i].draw();
    particles[i].update(timeDelta * dilationFactor);
  }
  
  origin.draw();
  origin.update(timeDelta * dilationFactor);
  
  seconds = 0.001 * millis();
  deltaSeconds = seconds - prevSeconds;
  
  if (deltaSeconds > 1) {
    fpsRecent = (frameCount - prevFrameCount) / deltaSeconds;
    prevSeconds = seconds; 
    prevFrameCount = frameCount;
  }
  
  myInfobox.print( 
  //(int) frameRate + "fps\n"
  + (int) seconds + " seconds\n"
  + (int) fpsRecent +  "fps (" + (int)(frameCount / seconds) + "avg)\n"
  + "CameraZ: " + nf(kamera.pos.z, 3, 2) + "\n"
  + "targetParticle.pos.z:      " + nf(targetParticle.pos.z, 3, 2) + "c\n"
  + "targetParticle.properTime: " + nf(targetParticle.properTime, 3, 2) + "c\n"
  + "targetParticle.vel.mag():  " + nf(targetParticle.vel.mag(), 1, 6) + "c\n"
  );

  camera();
  noLights(); //lights();
  
  float fov = PI/3.0;
  float cameraZ = (height/2.0) / tan(fov);
  perspective(fov, float(width)/float(height), 0.1, 10E9);
  
  controlP5.draw();
}

void mousePressed() {
  if (mouseButton == RIGHT) {
    MOUSELOOK = (MOUSELOOK) ? false : true;
  }
}

void keyPressed() {
  if (key == 'w' || key == 's' || key == 'a' || key == 'd' ) {

    float angleOffset = 0;

    switch (key) {
      case 'w' : angleOffset = 0; break;
      case 'a' : angleOffset = -HALF_PI; break;
      case 's' : angleOffset = PI; break;
      case 'd' : angleOffset = HALF_PI; break;
     }
    
    // Placeholder rest mass
    float m_o = 1;
    
    // Speed of light
    float c = 1;
    
    float momentumScaleFactor = 0.3;
    float momentumNudge = 0.01;
    
    float v_mag = targetParticle.vel.mag();
    float gamma_o = Relativity.gamma(v_mag);
    
    float p = m_o * gamma_o * v_mag;
    
    float theta = kamera.azimuth + PI + angleOffset;
    float heading_initial = atan2(targetParticle.vel.y, targetParticle.vel.x);
    
    float momentumScale = 0.3 - momentumScaleFactor * cos(heading_initial - theta % TWO_PI);
    
    float dp = momentumScale * p + momentumNudge;
    
    
    //if ((heading_initial - theta % TWO_PI) > PI) {
      momentumScaleFactor = (1 - momentumScaleFactor)*(heading_initial-theta)/2;
    //}
    
    float dp_x = dp * cos(theta);
    float dp_y = dp * sin(theta);
    
    float p_x = m_o * gamma_o * targetParticle.vel.x;
    float p_y = m_o * gamma_o * targetParticle.vel.y;
    
    float p_x_final = p_x + dp_x;
    float p_y_final = p_y + dp_y;
    
    float heading_final = atan2(p_y_final, p_x_final);
    
    float p_mag_final = sqrt(p_x_final*p_x_final + p_y_final*p_y_final);
    println("p_mag_final:   " + p_mag_final);
    
    //TODO: double check this result (from French prob. 1.15)
    float v_mag_final = 1.0/sqrt(pow((m_o/p_mag_final), 2) + c*c);
    
    v_mag_final = constrain(v_mag_final, 0.0, 1 - 1E-7);
/*    
    println("p:     " + p);
    println("dp:    " + dp);
    println("theta: " + theta / PI);
    println("heading_final: " + heading_final / PI);
    println("v_mag_final:   " + v_mag_final);
*/    
    targetParticle.vel.x = cos(heading_final) * v_mag_final;
    targetParticle.vel.y = sin(heading_final) * v_mag_final;
    
//    targetParticle.vel.x = cos(theta) * 0.5;
//    targetParticle.vel.y = sin(theta) * 0.5;
//    targetParticle.vel.x = cos(heading_final) * 0.5;
//    targetParticle.vel.y = sin(heading_final) * 0.5;
  }
}

double constrain(double val, double low, double high) {
  return (val < low) ? low : ((val > high) ? high : val);
}

class Kamera {
  
  Kamera() {
    radius = 100;
    azimuth = PI;
    zenith = PI/6;
    target = new PVector(0,0,0);
    
    pos = new PVector();
    updatePosition();
    
    radiusVel = azimuthVel = zenithVel = 0;
    velDecay = 0.9;
    
    mouseWheel = 0;
    
    perspective(PI/3.0, width/height, 1, 15000000);
    
    addMouseWheelListener(new java.awt.event.MouseWheelListener() { 
      public void mouseWheelMoved(java.awt.event.MouseWheelEvent evt) { 
      mouseWheel(evt.getWheelRotation());
      }
    });
  }
  
  void mouseWheel(int delta) {
    mouseWheel -= delta;
    println(mouseWheel);
    
    radiusVel += mouseWheel;
  }
  
  void updatePosition() {
    pos.x = target.x + radius * sin(zenith) * cos(azimuth);
    pos.y = target.y + radius * sin(zenith) * sin(azimuth);
    pos.z = target.z + radius * cos(zenith);
  }
  
  void update(float dt) {
    
    if (MOUSELOOK) {
      zenithVel -= (float)(mouseY - pmouseY)/10;
      azimuthVel += (float)(mouseX - pmouseX)/10;
    }
    
    radiusVel += mouseWheel;
    mouseWheel *= 0.1;
    
    radius = abs(radius - radius * radiusVel / 60);
    radiusVel *= velDecay;
    
    azimuth = (azimuth + azimuthVel / 60) % (TWO_PI);
    azimuthVel *= velDecay;
    
    zenith = constrain(zenith + zenithVel / 60, 0.001, PI - 0.001);
    zenithVel *= velDecay;
    
    updatePosition();
    
    camera(pos.x,     pos.y,     pos.z,
           target.x,  target.y,  target.z,
           0,         0,         -1 );
  }
  
  float mouseWheel;
  
  float velDecay;
  
  float radiusVel;
  float azimuthVel;
  float zenithVel;
  
  float radius;
  float azimuth;
  float zenith;
  
  PVector pos;
  PVector target;
}
