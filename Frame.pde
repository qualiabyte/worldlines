// tflorez

interface Frame extends Selectable {

  Velocity getVelocity();
  
  float[] getPosition();
  float[] getDisplayPosition();
  
  Vector3f getPositionVec();
  Vector3f getDisplayPositionVec();
  
  Plane getSimultaneityPlane();
  
  AxesSettings getAxesSettings();
  
  float getAge();
  float getAncestorsAge();
  //void setAge(float age);
}

class DefaultFrame implements Frame {
  
  Vector3f position = new Vector3f();
  Vector3f displayPosition = new Vector3f();
  
  Velocity velocity = new Velocity();
  Plane simultaneityPlane = new Plane();
  Line velocityLine = new Line();
  
  float age;
  float ancestorsAge;
  
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
  
  DefaultFrame clone() {
    DefaultFrame clone = new DefaultFrame(this.position, this.velocity);
    clone.setAge(this.getAge());
    clone.setAncestorsAge(this.getAncestorsAge());
    return clone;  
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
  
  void setAge(float age) {
    this.age = age;
  }
  
  float getAge() {
    return age;
  }
  
  void setAncestorsAge(float ancestorsAge) {
    this.ancestorsAge = ancestorsAge;
  }
  
  float getAncestorsAge() {
    return ancestorsAge;
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
