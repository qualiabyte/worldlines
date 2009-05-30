//Worldlines
//tflorez

import processing.opengl.*;
import javax.media.opengl.GL;
import controlP5.*;

PGraphicsOpenGL pgl;
GL gl;

Kamera kamera;

Particle[] particles;
Particle targetParticle;

PVector target;
PVector prevTarget;

float timeDelta = 0.2;

public boolean MOUSELOOK = true;

public int MAX_PARTICLES = 1000;
public int PARTICLES = MAX_PARTICLES/3;

public float MAX_START_POS_DISPERSION = 6;
public float START_POS_DISPERSION_X = 0;
public float START_POS_DISPERSION_Y = 0;

public float MAX_START_VEL_DISPERSION = 20;
public float START_VEL_DISPERSION = 5.4; //4.2; //1.8;

public float MAX_START_VEL_ECCENTRICITY = 15;
public float START_VEL_ECCENTRICITY = 1.95; //0;

public float HARMONIC = 3.4;
public float HARMONIC_MAX = 16;

public boolean TOGGLE_TIMESTEP_SCALING;
public boolean TOGGLE_SPATIAL_TRANSFORM;

public float LIGHTING = 0.75;
public float STROKE_WIDTH = 0.8;

String bundledFont = "VeraMono.ttf";

float fpsRecent, prevFrameCount;
float seconds, prevSeconds, deltaSeconds;
float fpsMovingAvg;

ControlP5 controlP5;

Infobox myInfobox;

void setup() {
  size(900, 540, OPENGL);
  
  myInfobox = new Infobox(loadBytes(bundledFont), (int)(0.025 * height));
  
  int nControls = 0;
  int bWidth = 20;
  int bHeight = 20;
  int bSpacingY = bHeight + 15;
  int sliderWidth = bWidth*5;
  
  controlP5 = new ControlP5(this);
  controlP5.setAutoDraw(false);
  controlP5.addButton("setup", 0, 10, ++nControls*bSpacingY, 2*bWidth, bHeight).setLabel("RESTART");
  controlP5.addSlider("PARTICLES", 0, MAX_PARTICLES, PARTICLES, 10, ++nControls*bSpacingY, sliderWidth, bHeight);
  controlP5.addSlider("START_POS_DISPERSION_X", 0, MAX_START_POS_DISPERSION, START_POS_DISPERSION_X, 10, ++nControls*bSpacingY, sliderWidth, bHeight);
  controlP5.addSlider("START_POS_DISPERSION_Y", 0, MAX_START_POS_DISPERSION, START_POS_DISPERSION_Y, 10, ++nControls*bSpacingY, sliderWidth, bHeight);
  controlP5.addSlider("START_VEL_DISPERSION", 0, MAX_START_VEL_DISPERSION, START_VEL_DISPERSION, 10, ++nControls*bSpacingY, sliderWidth, bHeight);
  controlP5.addSlider("START_VEL_ECCENTRICITY", 0, MAX_START_VEL_ECCENTRICITY, START_VEL_ECCENTRICITY, 10, ++nControls*bSpacingY, sliderWidth, bHeight);
  controlP5.addToggle("TOGGLE_TIMESTEP_SCALING",false,10,++nControls*bSpacingY,bWidth,bHeight);
  controlP5.addToggle("TOGGLE_SPATIAL_TRANSFORM", false, 10, ++nControls*bSpacingY,bWidth,bHeight);
  controlP5.addSlider("HARMONIC", 0, HARMONIC_MAX, HARMONIC, 10, ++nControls*bSpacingY, sliderWidth, bHeight);
  controlP5.addSlider("LIGHTING", 0f, 1.0f, 1.0f, 10, ++nControls*bSpacingY, sliderWidth, bHeight);
  controlP5.addSlider("STROKE_WIDTH", 0f, 5f, 0.8f, 10, ++nControls*bSpacingY, sliderWidth, bHeight);
  
  particles = new Particle[MAX_PARTICLES];

  for(int i=0; i<MAX_PARTICLES; i++){

    float x = random(pow(10, START_POS_DISPERSION_X));
    float y = random(pow(10, START_POS_DISPERSION_Y));
    
    PVector pos = new PVector(x, y);

    float heading = random(TWO_PI);
    
    // Exponentially weight distribution of velocities towards lightspeed
    float vel_mag = 1-pow(random(1, 2), -START_VEL_DISPERSION);
    
    float vx = vel_mag*cos(heading);
    float vy = vel_mag*sin(heading)*(pow(1.5, -START_VEL_ECCENTRICITY));
    
    PVector vel = new PVector(vx, vy);
    
    particles[i] = new Particle(pos, vel);
    particles[i].fillColor = color(#1B83F0);
  }

  particles[0] = new Particle(new PVector(0,0,0), new PVector(0,0,0));
  targetParticle = particles[0];
  targetParticle.fillColor = color(#F01B5E); //#48F01B);
    
  kamera = new Kamera();
  kamera.target = targetParticle.pos.get();

  strokeWeight(STROKE_WIDTH);
  frameRate(90);
  hint(DISABLE_DEPTH_SORT);
}

void draw() {
  
  pgl = (PGraphicsOpenGL)g;
  gl = pgl.beginGL();
  
  gl.glEnable(GL.GL_BLEND);
  gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE);
  gl.glDisable(GL.GL_DEPTH_TEST);
  gl.glDepthMask(false);
  
  //gl.glClear(GL.GL_DEPTH_BUFFER_BIT);
  pgl.endGL();
  background(30); //noLights();
  
  directionalLight(LIGHTING, LIGHTING, LIGHTING, 0.5, 0.5, -1);
  directionalLight(LIGHTING, LIGHTING, LIGHTING, -0.5, -0.5, -1);
  

  
  //Smoothly vary some variables over time for slick effect
  kamera.azimuthVel += PI * 0.002;
  //HARMONIC = (HARMONIC - 0.02) % HARMONIC_MAX;
  
  float dilationFactor = TOGGLE_TIMESTEP_SCALING ? 
                         targetParticle.gamma : 1.0;
  
  strokeWeight(STROKE_WIDTH);
  
  for (int i=0; i<PARTICLES; i++) {
    particles[i].update(timeDelta * dilationFactor);
  }
  
  kamera.target = targetParticle.pos.get();
  kamera.update(timeDelta);
  
  for (int i=0; i<PARTICLES; i++) {
    particles[i].draw();
  }
  
  seconds = 0.001 * millis();
  deltaSeconds = seconds - prevSeconds;
  
  if (deltaSeconds > 1) {
    fpsRecent = (frameCount - prevFrameCount) / deltaSeconds;
    prevSeconds = seconds; 
    prevFrameCount = frameCount;
  }
  
  myInfobox.print(
  + (int) seconds + " seconds\n"
  + (int) fpsRecent +  "fps (" + (int)(frameCount / seconds) + "avg)\n"
  //+ "CameraZ: " + nf(kamera.pos.z, 3, 2) + "\n"
  + "targetParticle.pos.z:      " + nf(targetParticle.pos.z, 3, 2) + "c\n"
  + "targetParticle.properTime: " + nf(targetParticle.properTime, 3, 2) + "c\n"
  + "targetParticle.vel.mag():  " + nf(targetParticle.vel.mag(), 1, 6) + "c\n"
  );

  camera();
  noLights(); //lights();
  
  perspective(PI/3.0, float(width)/float(height), 0.1, 10E9);
  
  controlP5.draw();
}

void mousePressed() {
  if (mouseButton == RIGHT) {
    MOUSELOOK = !MOUSELOOK;
    cursor(MOUSELOOK ? MOVE : ARROW);
  }
}

void keyPressed() {
  
  float angleOffset = -1;
  
  switch (key) {
    case 'w' : angleOffset = 0; break;
    case 'W' : angleOffset = 0; break;
    case 'a' : angleOffset = -HALF_PI; break;
    case 'A' : angleOffset = -HALF_PI; break;
    case 's' : angleOffset = PI; break;
    case 'S' : angleOffset = PI; break;
    case 'd' : angleOffset = HALF_PI; break;
   }
  
  if (angleOffset != -1) {
    
    // Placeholder rest mass
    float m_o = 1;
    
    // Speed of light
    float c = 1;
    
    float momentumScaleFactor = 0.3;
    float momentumNudge = 0.01;
    
    float v_mag = targetParticle.velMag;
    float gamma_initial = Relativity.gamma(v_mag);
    
    float p = m_o * gamma_initial * v_mag;
    
    float vx = targetParticle.vel.x;
    float vy = targetParticle.vel.y;
    
    float theta = kamera.azimuth + PI + angleOffset;
    float heading_initial = atan2(vy, vx);

    float momentumScale = 0.3 - momentumScaleFactor * cos(heading_initial - theta % TWO_PI);

    if ((heading_initial - theta % TWO_PI) > PI) {
      momentumScaleFactor = (1 - momentumScaleFactor)*(heading_initial-theta)/(2*frameRate);
    }

    float dp = momentumScale * p + momentumNudge;

    float dp_x = dp * cos(theta);
    float dp_y = dp * sin(theta);
    
    float p_x = m_o * targetParticle.gamma * vx;
    float p_y = m_o * targetParticle.gamma * vy;
    
    float p_x_final = p_x + dp_x;
    float p_y_final = p_y + dp_y;
    
    float heading_final = atan2(p_y_final, p_x_final);
    
    float p_mag_final = sqrt(p_x_final*p_x_final + p_y_final*p_y_final);
    
    // Checked this result from French prob. 1.15; seems to work
    float v_mag_final = 1.0/sqrt(pow((m_o/p_mag_final), 2) + c*c);
    
    v_mag_final = constrain(v_mag_final, 0.0, 1 - 1E-7);
    
    targetParticle.setVel( cos(heading_final) * v_mag_final, sin(heading_final) * v_mag_final);
  }
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
    
    float fov = PI/3.0;
    perspective(fov, width/height, 1, 15000000);
    
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
