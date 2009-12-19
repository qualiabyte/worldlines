// tflorez

interface Frame extends Selectable {

  Velocity getVelocity();
  
  float[] getPosition();
  float[] getDisplayPosition();
  
  Vector3f getPositionVec();
  Vector3f getDisplayPositionVec();
  
  Plane getSimultaneityPlane();
  
  AxesSettings getAxesSettings();
}

class DefaultFrame implements Frame {
  
  Vector3f position = new Vector3f();
  Vector3f displayPosition = new Vector3f();

  Velocity velocity = new Velocity();
  Plane simultaneityPlane = new Plane();
  Line velocityLine = new Line();

  AxesSettings axesSettings = new AxesSettings();
//  boolean axesVisible = true;
//  boolean axesGridVisible = false;
//  boolean simultaneityPlaneVisible = true;
  
  DefaultFrame(Vector3f position, Vector3f vel){
    setPosition(position);
    setVelocity(vel);
  }
  
  DefaultFrame(Vector3f position, Velocity vel) {
    this();    //this(position, vel.velocity);
    setPosition(position);
    setVelocity(vel);
  }
  
  DefaultFrame() {
    this(new Vector3f(), new Vector3f());
  }
  
  void setPosition(float x, float y, float z) {
    position.set(x, y, z);
    updatePosition();
  }
  
  void updatePosition() {
    
    //displayPosition = Relativity.displayTransform(targetParticle.velocity, position);
    Relativity.displayTransform(lorentzMatrix, position, displayPosition);
    
    simultaneityPlane.setPoint(position);
    velocityLine.setPoint(position);
  }

  void setPosition(float[] pos) {
    setPosition(pos[0], pos[1], pos[2]);
  }
  
  void setPosition(Vector3f pos) {
    setPosition(pos.x, pos.y, pos.z);
  }
  
  void setVelocity(float x, float y) {
    
    velocity.setComponents(x, y);
    
    simultaneityPlane.setNormal(this.velocity.normal);
    velocityLine.setDirection(this.velocity.vx, this.velocity.vy, 1);
  }
  
  void setVelocity(Velocity theVel) {
    setVelocity(theVel.vx, theVel.vy);
  }
  
  void setVelocity(float[] vel) {
    setVelocity(vel[0], vel[1]);    
  }
  
  void setVelocity(Vector3f v) {
    setVelocity(v.x, v.y);
  }
  
  Velocity getVelocity(){
    return velocity;
  }
  
  Vector3f getPositionVec() {
    return position;
  }
  
  float[] getPosition(){
    float[] pos = new float[3];
    position.get(pos);
    return pos;
  }
  
  float[] getDisplayPosition(){
    float[] pos = new float[3];
    displayPosition.get(pos);
    return pos;
  }
  
  Vector3f getDisplayPositionVec() {
    return displayPosition;
  }
  
  Plane getSimultaneityPlane() {
    return simultaneityPlane;
  }
  
  Line getVelocityLine() {
    return velocityLine;
  }
  
  AxesSettings getAxesSettings() {
    return this.axesSettings;
  }
  
  /*
  Vector3f getPosition(){
    return position;
  }
  
  Vector3f getDisplayPosition(){
    return displayPosition;
  }
  */
}
