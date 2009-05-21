//Worldlines
//tflorez

import processing.opengl.*;
import javax.media.opengl.GL;

PGraphicsOpenGL pgl;
GL gl;

Kamera kamera;

Particle origin;
Particle[] particles;

Particle targetParticle;
PVector target;
PVector prevTarget;

float timeDelta = 0.2;

int n_particles = 300;

String bundledFont = "VeraMono.ttf";

Infobox myInfobox;

void setup() {
  size(1200, 900, OPENGL);

  File fontFile = new File(dataPath(bundledFont));
  myInfobox = new Infobox(fontFile, (int)(0.025 * height));

  origin = new Particle(new PVector(0,0,0), new PVector(0,0,0));
  origin.fillColor = color(#F01B5E);//#48F01B);//
  
  particles = new Particle[n_particles];

  for(int i=0; i<n_particles; i++){

    PVector pos = new PVector(0,0);
    //PVector pos = new PVector(random(-100, 100), random(-100, 100), 0);

    float heading = random(TWO_PI);
    
    // Exponentially weight distribution of velocities towards lightspeed
    float vel_mag = 1-pow(random(1, 2), -15.0);
    
    PVector vel = new PVector(vel_mag*cos(heading), vel_mag*sin(heading));
    
    particles[i] = new Particle(pos, vel);
    particles[i].fillColor = color(#1B83F0);
    /*
    colorMode(HSB, 1.0);
    color c = color(random(1), 0.8, 1.0);

    particles[i].setPathColor(c);
    
    colorMode(RGB, 255);
    */
  }
  //colorMode(RGB);
  
  targetParticle = origin;
  
  kamera = new Kamera();
  kamera.target = targetParticle.pos.get();

  //strokeWeight(1);
}

void draw(){
  pgl = (PGraphicsOpenGL)g;
  gl = pgl.beginGL();
  
  gl.glEnable(GL.GL_BLEND);
  gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE);
  gl.glDisable(GL.GL_DEPTH_TEST);
  gl.glDepthMask(false);
  
  pgl.endGL();
  
  lights();
  background(30);
  
  directionalLight(3, 115, 140, // Color 
    10, 10, -1); // The x-, y-, z-axis direction' 
  directionalLight(2, 83, 115, // Color 
    1, 10, -1); // The x-, y-, z-axis direction' 

  kamera.target = targetParticle.pos.get();
  kamera.update(timeDelta);
  pointLight(220, 0, 0, kamera.pos.x, kamera.pos.y, kamera.pos.z);

  kamera.azimuthVel += PI * 0.002;

  for (int i=0; i<n_particles; i++){
    particles[i].draw();
    particles[i].update(timeDelta);
  }
  
  origin.draw();
  origin.update(timeDelta);
  
  myInfobox.print( 
  (int) frameRate + " fps / " + (int)(frameCount / (millis() / 1000)) + "avg\n"
  + (int) millis() / 1000 + " seconds\n"
  + "targetParticle.pos.z:      " + nf(targetParticle.pos.z, 3, 2) + "c\n"
  + "targetParticle.properTime: " + nf(targetParticle.properTime, 3, 2) + "c\n"
  + "CameraZ: " + nf(kamera.pos.z, 3, 2)
  );
}
/*
PVector PVector(float[] v){
  return new PVector(v[0], v[1], v[2]);  
}
*/
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
    
    perspective(PI/3.0, width/height, 1, 15000);
    
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
//    if (mousePressed && mouseButton == RIGHT){
      zenithVel -= (float)(mouseY - pmouseY)/10;
      azimuthVel += (float)(mouseX - pmouseX)/10;
//    }
    
    radiusVel += mouseWheel;
    mouseWheel *= 0.1;
    
    radius = abs(radius - radius * radiusVel / 60);
    radiusVel *= velDecay;
    
    azimuth = (azimuth + azimuthVel / 60) % (TWO_PI);
    azimuthVel *= velDecay;
    
    zenith = constrain(zenith + zenithVel / 60, 0.00001, PI - 0.00001);
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
