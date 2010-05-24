// Particle
// tflorez

class Particle implements Frame, ISelectableLabel {
  
  // PHYSICAL STATE
  Vector3f position = new Vector3f();
  Velocity velocity = new Velocity();
  
  float properTime;
  float mass = 1.0;
  
  // HISTORY
  int histCount = 0;
  int histCountMax = 1000;
  int frameCountLastHistUpdate = 0;
  
  float[] properTimeHist = new float[histCountMax];
  DefaultFrame[] frameHist = new DefaultFrame[histCountMax];
  
  // EMISSION ACCOUNTING
  int millisLastEmission = 0;
  
  float emissionMomentumX, emissionMomentumY, emissionMomentumTotal;
  float emissionMassTotal;
  
  // Accumulated impulse (add to momentum smoothly)
  float impulseX, impulseY, impulseTotal;
  
  // DISPLAY + APPEARANCE
  boolean isVisible = true;
  
  String name = "";
  String label = "";
  
  ParticleLabelBuilder labelBuilder;
  
  color fillColor = #1B83F0;

  float pathColorR, pathColorG, pathColorB, pathColorA;
  color pathColor;
  
  // FRAME INTERFACE BEGIN
  DefaultFrame headFrame = new DefaultFrame();
  
  float[] getPosition(){
    //return xyt;
    return headFrame.getPosition();
  }
  
  Velocity getVelocity(){
    //return velocity;
    return headFrame.getVelocity();
  }
  
  Vector3f getPositionVec() {
    return headFrame.position;
  }
  
  Vector3f getDisplayPositionVec() {
    return headFrame.displayPosition;
  }
  
  float[] getDisplayPosition() {
    //return xyt_prime;
    //return Relativity.displayTransform(targetParticle.velocity, xyt);
    //return Relativity.selectDisplayComponents(xyt, xyt_prime);
    
    return headFrame.getDisplayPosition();
  }
  
  Plane getSimultaneityPlane(){
    return headFrame.getSimultaneityPlane();
  }
  
  float getAge() {
    return headFrame.getAge() + headFrame.getAncestorsAge();
    //return headFrame.getAge();
  }
  
  float getAncestorsAge() {
    return headFrame.getAncestorsAge();
  }
  
  AxesSettings getAxesSettings() {
    return this.headFrame.axesSettings;
  }
  // FRAME INTERFACE END
  
  {
    colorMode(RGB,1.0);
    setPathColor(color(0,0.8,0.8,prefs.getFloat("LIGHTING_WORLDLINES")));
  }
  
  Particle( Vector3f pos, Vector3f vel ){
    
    this.labelBuilder = new ParticleLabelBuilder();
    
    headFrame = new DefaultFrame(pos, vel);
    recordStateToPathHistory();
    
    setVelocity(vel.x, vel.y);
    setPosition(pos);
  }
  
  Particle( Vector3f pos, Velocity vel) {
    this( pos, new Vector3f(vel.vx, vel.vy, 0) );
  }
  
  Particle () {
    this(new Vector3f(1E-7,0,0), new Vector3f(0,0,0));
  }
  
  void setPosition(Vector3f v){
    setPosition(v.x, v.y, v.z);
  }
  
  void setPosition(float x, float y, float z){
    position.set(x, y, z);
    updatePosition();
  }
  
  void updatePosition() {
    
    headFrame.setPosition(position);
    
    updateHistory();
  }
  
  void setAllVisibility(boolean b) {
    this.isVisible = b;
    this.headFrame.axesSettings.setAllVisibility(b);
  }
  
  void setVelocity(float x, float y){
    velocity.setComponents(x, y);
    headFrame.setVelocity(x, y);
  }
  
  void update(float dt){
    
    updateImpulse();
    
    position.x += velocity.vx * dt;
    position.y += velocity.vy * dt;
    position.z += dt;
    
    setPosition(position);
    setProperTime(this.properTime + dt / this.velocity.gamma);
    
    //updateHist();
    updateLabel();
  }
  
  void setProperTime(float time) {
    this.properTime = time;
    properTimeHist[histCount] = properTime;
    
    headFrame.setAge(this.properTime - frameHist[histCount].getAncestorsAge());
  }
  
  void updateHistory() {
    
    Velocity velLast = frameHist[histCount-1].getVelocity();
    
    int elapsedFrames = frameCount - frameCountLastHistUpdate;
    float directionChange = abs((velLast.direction - headFrame.getVelocity().direction) % PI);
    float velocityChange = abs(velLast.magnitude - headFrame.getVelocity().magnitude);
    
    if ( (elapsedFrames > 12) && 
         ( (directionChange > TWO_PI * 0.01) || (velocityChange > velocity.magnitude * 0.01) ) ) {
      
      recordStateToPathHistory();
    }
  }
  
  void recordStateToPathHistory() {
    
    frameHist[histCount] = headFrame.clone();
    
    histCount++;
    frameHist[histCount] = headFrame;
    headFrame.setAncestorsAge(this.properTime);
    
    frameCountLastHistUpdate = frameCount;
  }
  
  void updateTransformedHist(Matrix3f lorentzMatrix){
    
    Vector3f source = new Vector3f();
    Vector3f target = new Vector3f();
    
    for (int i=0; i<=histCount; i++) {
      
      frameHist[i].updatePosition();
    }
  }
  
  void drawGL(GL gl){
    //drawHeadGL(gl);
    drawPathGL(gl);
  }
  
  void drawHead(){
    float[] displayPos = this.getDisplayPosition();
    drawHead(displayPos[0], displayPos[1], displayPos[2]);
  }
  
  void drawHead(float x, float y, float z) {
    if (! this.isVisible) { return; }
    
    pushMatrix();

    translate(x, y, z);
    rotate(velocity.direction - HALF_PI);

    fill(fillColor);

    triangle(0, 1, -.5, -1, .5, -1);
    popMatrix();
  }
  
  void drawHeadGL(GL gl, float[] pos) {
    if (! this.isVisible) { return; }
    drawHeadGL(gl, pos[0], pos[1], pos[2]);
  }
  
  void drawHeadGL(GL gl){
    float[] displayPos = this.getDisplayPosition();
    drawHeadGL(gl, displayPos);
  }
  
  void drawHeadGL(GL gl, Vector3f V){
    drawHeadGL(gl, V.x, V.y, V.z);
  }
  
  void drawHeadGL(GL gl, float x, float y, float z) {
    gl.glPushMatrix();
    
    glColorGL(gl, fillColor);
    
    gl.glTranslatef(x, y, z);
    gl.glRotatef(degrees(velocity.direction-PI/2), 0, 0, 1);
    
    gl.glBegin(GL.GL_TRIANGLES);
    gl.glVertex2f(0, 1);
    gl.glVertex2f(-0.5, -1);
    gl.glVertex2f(+0.5, -1);
    gl.glEnd();
    
    gl.glPopMatrix();
  }

  Vector3f getIntersection(Frame f) {
    Vector3f theIntersection = new Vector3f();
    
    Plane plane = f.getSimultaneityPlane();
    
    Line intersectingLine;
    DefaultFrame intersectingFrame = null;
    
    if (frameHist[0].isAbove(plane)) {
      return null;
    }
    else if ( ! headFrame.isAbove(plane)
              || histCount == 1) {
      intersectingFrame = headFrame;
    }
    else {
      intersectingFrame = this.findHighestFrameBelow(plane);
    }
    
    if (intersectingFrame == null) {
      theIntersection = null;
    }
    else {
      intersectingLine = intersectingFrame.getVelocityLine();
      plane.getIntersection(intersectingLine, theIntersection);
    }
    
    return theIntersection;
  }
  
  DefaultFrame findHighestFrameBelow(Plane thePlane) {
    DefaultFrame highestBelow = null;
    
    // Bounds on where the intersect lies in this particles frame history
    int lowerIndex = 0;
    int upperIndex = this.histCount + 1;
    
    for (int theIndex = (upperIndex - lowerIndex) / 2;
         (upperIndex - lowerIndex) > 1;
         theIndex = lowerIndex + (upperIndex - lowerIndex) / 2 ) {
      
      if (frameHist[theIndex].isAbove(thePlane)) {
        upperIndex = theIndex;
      }
      else {
        lowerIndex = theIndex;
      }
    }
    
    highestBelow = frameHist[lowerIndex];
    return highestBelow;
  }
  
  void drawIntersectionGL(GL gl, Frame f){
    
    drawHeadGL(gl, getIntersection(f));
  }
  
  // A variation on drawPath using glBegin() and glVertex()
  void drawPathGL(GL gl){
    
    gl.glBegin(GL.GL_LINE_STRIP);
    
    float r, g, b, a;
    
    float alphaFactor = 0.5 * prefs.getFloat("LIGHTING_WORLDLINES");// / ((float)histCount);
    
    float wavenumberFactor = TWO_PI * prefs.getFloat("HARMONIC_FRINGES") / position.z;
    float harmonicFactor = prefs.getFloat("HARMONIC_CONTRIBUTION");
    
    for (int i=0; i <= histCount; i++) {
      
      float harmonic = harmonicFactor * 0.5*(1 - cos((wavenumberFactor * properTimeHist[i])%TWO_PI));
      
      r = (pathColorR+properTimeHist[i]%400)/400;
      g = 0.2 + pathColorG - harmonic;
      b = pathColorB;
      a = 0.2 + alphaFactor * g * i * (1 + sin(TWO_PI * 0.01 * properTimeHist[i]%100));
      
      gl.glColor4f(r, g, b, a);
      gl.glVertex3fv(frameHist[i].getDisplayPosition(), 0);
    }
    //float[] head = this.getDisplayPosition();
    //gl.glVertex3f(head[0], head[1], head[2]);
    gl.glEnd();
  }
  
  void propelSelf(float momentumDeltaX, float momentumDeltaY) {
    //TODO
    addImpulse(momentumDeltaX, momentumDeltaY);
    
    emissionMomentumX += momentumDeltaX;
    emissionMomentumY += momentumDeltaY;
    emissionMomentumTotal = abs(emissionMomentumX) + abs(emissionMomentumY);
  }
  
  void addImpulse(float dp_x, float dp_y) {
    impulseX += dp_x;
    impulseY += dp_y;
  }
  
  void updateEmission() {
    
    int emissionGenerationDelay = 500;
    
    if ( (emissionMomentumTotal > 1E-4) && //0.02 * this.mass * velocity.magnitude) &&
         ((millis() - millisLastEmission) > emissionGenerationDelay) ) {
      
      Particle emission = new Particle(this.position, this.velocity);
      
      //emission.setPosition(this.position);
      emission.mass = 0.001 * this.mass;
      //emission.mass = this.emissionMomentumTotal * C;
      
      emission.addImpulse(-emissionMomentumX / emission.mass, -emissionMomentumY / emission.mass);
      //Dbg.say("emission.velocity.magnitude: " + emission.velocity.magnitude);
      //TODO: more realistic emission velocity; also, photon emissions
      emit(emission);
    }
  }
  
  void emit(Particle emission) {
    
    addEmission(emission);
    millisLastEmission = millis();
    //Dbg.say("emission: millis() = " + millis());
    
    //TODO: more realistic emission energy & mass
    this.mass -= emission.mass;
    //addImpulse(emissionMomentumX, emissionMomentumY);
    emissionMomentumX = emissionMomentumY = emissionMomentumTotal = 0;
  }
  
  // TODO: this emulates photon emissions for now, but this needs its own class
  void emitEnergy(float massEnergy, float direction) {
    
    float theMass = massEnergy / C*C;
    
    Velocity theVelocity = new Velocity();
    theVelocity.setDirection(direction);
    theVelocity.setMagnitude(0.99999); 
    Particle emission = new Particle(this.position, theVelocity);
    emission.mass = theMass;
    addEmission(emission);
    
    this.mass -= theMass;
    
    float impulseMomentum = massEnergy / C;
    addImpulse(-cos(direction)*impulseMomentum, -sin(direction)*impulseMomentum);
  }

  void updateImpulse() {
    
    updateEmission();
    
    float dp_x = impulseX * prefs.getFloat("INPUT_RESPONSIVENESS");
    float dp_y = impulseY * prefs.getFloat("INPUT_RESPONSIVENESS");

    impulseX -= dp_x;
    impulseY -= dp_y;
    
    float p_x = mass * velocity.gamma * velocity.vx;
    float p_y = mass * velocity.gamma * velocity.vy;

    float p_x_final = p_x + dp_x;
    float p_y_final = p_y + dp_y;

    float heading_final = atan2(p_y_final, p_x_final);

    float p_mag_final = sqrt(p_x_final*p_x_final + p_y_final*p_y_final);

    // Checked this result from French prob. 1.15; seems to work
    float v_mag_final = 1.0/sqrt(pow((mass/p_mag_final), 2) + C*C);

    v_mag_final = constrain(v_mag_final, 0.0, 1 - 1E-6);//1E-7);
    
    //velocity.setComponents( cos(heading_final) * v_mag_final, sin(heading_final) * v_mag_final);
    setVelocity( cos(heading_final) * v_mag_final, sin(heading_final) * v_mag_final );
  }
  
  void setFillColor(color c) {
    this.fillColor = c;
  }

  void setPathColor(color c) {
    colorMode(RGB,1.0f);
    pathColor = c;
    pathColorR = red(c);
    pathColorG = green(c);
    pathColorB = blue(c);
    pathColorA = alpha(c);
  }
  
  String getLabel() {
    return this.label;
  }
  String getName() {
    if (this.name == "" || this.name == null) {
      return "p." + particles.indexOf(this);
    }
    else {
      return this.name;
    }
  }
  void setName(String theName) {
    this.name = theName;
  }
  void setLabel(String theLabel) {
    this.label = theLabel;
  }
  void updateLabel() {
    setLabel(
      this.name + "\n" + 
      labelBuilder.buildLabel(this)
     );
  }
}

public class ParticleLabelBuilder {
  
  ParticleLabelBuilder() {
  }
  
  String buildLabel(Particle p) {
    
    String theLabel = (
      "p : " + nfVec(p.getPositionVec(), 3) + "\n" +
      //"p': " + nfVec(p.getDisplayPositionVec(), 3) + "\n" +
      //"fromTarget : " + nfVec(targetToParticle, 3) + "\n" +
      //"fromTarget': " + nfVec(targetToParticlePrime, 3) + "\n" +
      "velocity: (" + nf(p.velocity.magnitude, 0, 6) + ")\n" +
      //"mass: ("  + nf(p.mass, 0, 4) + ")\n" +
      "age: (" + nf(p.properTime, 0, 1) + ")\n"
      
      //"headFrame.getAncestorsAge(): " + nf(p.headFrame.getAncestorsAge(), 0, 2) + "\n" +
      //"headFrame.getAge(): " + nf(p.headFrame.getAge(), 0, 2)  + "\n"
      );
    
    return theLabel;
  }
}

interface ParticleDriver {
  void drive(Particle p);
}

class SineVelocityParticleDriver implements ParticleDriver {
  float velAmplitude;
  float wavelength;
  
  SineVelocityParticleDriver(float wavelength, float velAmplitude) {
    this.wavelength = wavelength;
    this.velAmplitude = velAmplitude;
  }
  
  void drive(Particle p) {
    float t = p.getPositionVec().z;
    float k = TWO_PI / wavelength;
    float vx = sin(k*t) * velAmplitude;
    p.velocity.setComponents(vx, 0);
  }
}

class DrivenParticle extends Particle {
  ParticleDriver particleDriver;
  
  DrivenParticle(ParticleDriver theDriver) {
    this.particleDriver = theDriver;
  }
  
  void update(float dt) {
    particleDriver.drive(this);
    super.update(dt);
  }
}
