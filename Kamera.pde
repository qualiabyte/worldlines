// Kamera
// tflorez

class Kamera {
  
  Kamera() {
    radius = 101;
    azimuth = PI/2.1;//PI;
    zenith = PI/2.1;
    
    target = new Vector3f();
    pos = new Vector3f();
    
    updatePosition();
    updateTarget(target.x, target.y, target.z);
    
    //float fov = PI/3.0; //perspective(fov, width/height, 1, 15000000);
    
    addMouseWheelListener(new java.awt.event.MouseWheelListener() { 
      public void mouseWheelMoved(java.awt.event.MouseWheelEvent evt) { 
      mouseWheel(evt.getWheelRotation());
      }
    });
    
    updateScreenToKameraMap();
  }
  
  void setFov(float fov) {
    perspective(radians(fov), (float)width/(float)height, 1, 150000);
    updateScreenToKameraMap();
  }
  
  void updateScreenToKameraMap() {
    
    distToKameraPlane = 100;
    screenToKameraMap = getScreenToKameraCoordinateMap();
    //Dbg.say("screenToKameraMap: \n" + screenToKameraMap);
  }
  
  Matrix3f getScreenToKameraCoordinateMap()
  {
    // PICKING (SETUP)
    // FIND RATIOS BETWEEN KAMERA AND SCREEN XY PLANES
    Vector3f kamX = new Vector3f();
    Vector3f kamY = new Vector3f();
    
    //float n = prefs.getFloat("kam_units_scale");
    float n = 1;
    
    kamX.set(this.pos);
    kamX.scaleAdd(distToKameraPlane, this.look, kamX);
    
    kamY.set(kamX);
    
    kamX.scaleAdd(n, this.right, kamX);
    kamY.scaleAdd(n, this.up, kamY);
    
    float screenx = screenX(kamX.x, kamX.y, kamX.z) - width / 2;
    float screeny = screenY(kamY.x, kamY.y, kamY.z) - height / 2;
    
    float kameraToScreenRatioX = n / screenx;
    float kameraToScreenRatioY = n / screeny;
    
    // MATRIX TO MAP SCREEN TO KAMERA COORDS
    Matrix3f screenToKameraMatrix = new Matrix3f(new float[] {
      kameraToScreenRatioX, 0,                    0,
      0,                    kameraToScreenRatioY, 0,
      0,                    0,                    0
    } );
    
    return screenToKameraMatrix;
  }
  
  Vector3f screenToModel(float theScreenX, float theScreenY) {
    
    Vector3f screenVec = new Vector3f(theScreenX - width/2, theScreenY - height/2, 0);
    Vector3f kameraVec = new Vector3f();
    
    // SCALE TO KAMERA XY
    screenToKameraMap.transform(screenVec, kameraVec);
    
    // TRANSLATE TO MODEL XYZ
    Vector3f modelPos = new Vector3f();
    
    modelPos.set(this.pos);
    modelPos.scaleAdd(distToKameraPlane, this.look,  modelPos);
    modelPos.scaleAdd(kameraVec.x, this.right, modelPos);
    modelPos.scaleAdd(kameraVec.y, this.up,    modelPos);
    
    return modelPos;
  }
  
  void mouseWheel(int delta) {
    mouseWheel -= delta;
    radiusVel += mouseWheel;
  }
  
  void update() {
    
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
    target.set(x, y, z);
    
    updatePosition();
    //updateUp();
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
    look.normalize();
    
    updateRight();
    updateUp();
  }
  
  /*
  void updateRight() {
    
    right.cross(look, up);
    //PVector.cross(look, up, right);
  }
  */
  void updateRight() {
    right.cross(look, zBasis);
    right.normalize();
  }
  
  void updateUp() {
    up.cross(right, look);
    up.normalize();
  }
  
  void commit() {

    camera(
      pos.x,     pos.y,     pos.z,
      target.x,  target.y,  target.z,
      up.x,      up.y,      up.z
      );
  }
  
  float distToKameraPlane;
  Matrix3f screenToKameraMap;
  
  float mouseWheel;
  
  float radiusVel;
  float azimuthVel;
  float zenithVel;
  
  float velDecay = 0.9;
  
  float radius;
  float azimuth;
  float zenith;
  
  Vector3f pos;
  Vector3f target;
  Vector3f look = new Vector3f();
  Vector3f up = new Vector3f();
  Vector3f right= new Vector3f();
  
  Vector3f zBasis = new Vector3f(0,0,-1);
}
