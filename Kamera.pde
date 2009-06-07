// Kamera
// tflorez

class Kamera {
  
  Kamera() {
    radius = 100;
    azimuth = PI;
    zenith = PI/6.0;
    target = new PVector(0,0,0);
    
    pos = new PVector();
    updatePosition();
    
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
    radiusVel += mouseWheel;
    
    println("mouseWheel: " + mouseWheel);
  }
  
  void update(float dt) {
    
    if (MOUSELOOK) {
      zenithVel -= (mouseY - pmouseY)/10.0;
      azimuthVel += (mouseX - pmouseX)/10.0;
    }
    
    radiusVel += mouseWheel;
    mouseWheel *= 0.1;
    
    radius = abs((float)(radius - radius * radiusVel / 60.0));
    radiusVel *= velDecay;
    
    azimuth = (azimuth + azimuthVel / 60.0) % (TWO_PI);
    azimuthVel *= velDecay;
    
    zenith = constrain(zenith + zenithVel / 60.0, 0.0001, PI - 0.0001);
    zenithVel *= velDecay;
    
    updatePosition();
    updateUp();
    commit();
  }
  
  void updateTarget(float[] xyz) {
    
    updateTarget(xyz[0], xyz[1], xyz[2]);    
  }
  
  void updateTarget(float x, float y, float z) {
    target.x = x;
    target.y = y;
    target.z = z;
    
    updatePosition();
    updateUp();
    commit();
  }
   
  void updatePosition() {
    pos.x = target.x + radius * sin(zenith) * cos(azimuth);
    pos.y = target.y + radius * sin(zenith) * sin(azimuth);
    pos.z = target.z + radius * cos(zenith);
    
    updateLook();
  }
  
  void updateLook() {
    look.x = target.x - pos.x;
    look.y = target.y - pos.y;
    look.z = target.z - pos.z;
    
    updateRight();
  }
  
  void updateRight() {
    
    PVector.cross(look, up, right);
  }
  
  void updateUp() {
    upX = 0;
    upY = 0;
    upZ = -1;
    
    // Keep rotation smooth at zenith extremes, when pos gets near limit for floats
    // Done piecewise to work around oddities of the camera up vector in processing
    if (zenith < PI / 10.0) {
      upX = cos(azimuth);
      upY = sin(azimuth);
      upZ = 0;
    }
    else if((PI - zenith) < PI / 10.0) {
      upX = -cos(azimuth);
      upY = -sin(azimuth);
      upZ = 0;
    }
    up.set(upX, upY, upZ);
  }
  
  void commit() {
    camera(pos.x,     pos.y,     pos.z,
           target.x,  target.y,  target.z,
           upX,       upY,      upZ);
  }
  
  float mouseWheel;
  
  float radiusVel;
  float azimuthVel;
  float zenithVel;
  
  float velDecay = 0.9;
  
  float radius;
  float azimuth;
  float zenith;
  
  float upX, upY, upZ;
  
  PVector pos;
  PVector target;
  PVector look = new PVector();
  PVector up = new PVector();
  PVector right= new PVector();
}
