// Particle
// tflorez

public class Particle implements Frame, ISelectableLabel {
  
  
  // PHYSICAL STATE
  
  /** Position as measured in the world frame. */
  public Vector3f position = new Vector3f();
  
  /** Velocity as measured in the world frame. */
  public Velocity velocity = new Velocity();
  
  /** Proper time elapsed since the creation of the particle, in seconds. */
  public float properTime;
  
  /** Rest mass of the particle. (Default is 1.0 kg). */
  public double mass = 1.0;
  
  
  // DECAY
  
  /** If enabled, probabilistic decay of this particle will be simulated on update(). */
  public boolean isDecaying = false;
  
  /** If true, simulation will continue for the particle on each call to update(). */
  public boolean isActive = true;
  
  /** Average proper time elapsed before decaying, in seconds. */
  public double meanLifetime = 1e3;
  
  private float ageLastDecayUpdate = this.properTime;
  
  
  // ENERGY & MOMENTUM
  
  /** @return  The total energy of the particle in the world frame: E = gamma m c^2 */
  public double getEnergy() {
    
    return velocity.gamma * mass * C * C;
  }
  
  /** @return  The total relativistic momentum of the particle in the world frame: |p| = gamma m |v| */
  public double getMomentum() {
    
    return velocity.gamma * mass * velocity.magnitude;
  }
  
  
  // DECAY ROUTINES
  
  /**
   * Split this particle into two particles by decay, adding and terminating particles
   * within the scene as necessary. @see #simulateSplitDecay for parameters and details.
   *
   * The original particle will be terminated and the resulting particles
   * will be added to the scene.
   *
   *  @returns   A list of particles created in the decay
   */
  List splitDecay(double m1, double m2, double angle) {

    List createdParticles = this.simulateSplitDecay(m1, m2, angle);
    
    addParticles(createdParticles);
    
    this.terminate();
    
    // If target particle decays, target the first created particle instead
    Particle recoil = (Particle) createdParticles.get(0);
    swapTargetStatus(this, recoil);
    swapSelectionStatus(this, recoil);
    
    return createdParticles;
  }
  
  /**
   * Simulate the decay of this particle into a pair of particles with rest masses m1 and m2,
   * where m1 + m2 < M.
   *
   * The decay process is first modeled in the rest frame of the initial particle,
   * and the result is then transformed into to the world frame.
   *
   * In the initial rest frame, the total kinetic energy of the produced pair is due to the
   * mass difference with the initial particle: delta_M = M - (m1 + m2).
   *
   * @param m1      The rest mass of the first produced particle.
   * @param m2      The rest mass of the second produced particle.
   * @param angle   The direction at which m2 is emitted in the decay,
   *                as angle (in radians) from the x-axis in the world frame.
   *
   * @return        A list of the particle pair produced in the split, with masses m1 and m2.
   */
  public List simulateSplitDecay(double m1, double m2, double angle) {
  
    // Accept any angle, then sanitize
    angle = modulus(angle, TWO_PI, -PI);
    
    // Direction of m2 in world and rest frames
    Vector3f angleDirWorld = new Vector3f((float)Math.cos(angle), (float)Math.sin(angle), 0f);
    Vector3f angleDirRest = new Vector3f();
    
    Relativity.lorentzTransform(this.velocity, angleDirWorld, angleDirRest);
    
    float angleRest = (float) Math.atan2(angleDirRest.y, angleDirRest.x);
    
    List createdParticles = new ArrayList();
    
    double M = this.mass;

    // Find momentum magnitudes
    // p1 == c * Sqrt( ((Ei^2 + E1_rest^2 - E2_rest^2) / (2Ei))^2 - (E1_rest)^2 )
    double p1 = Math.sqrt(Math.pow( (M*M + m1*m1 - m2*m2) / (2*M), 2 ) - m1*m1);
    double p2 = p1;
    
    // Find velocity magnitudes
    // v1 = c / Sqrt(1 + (m1*c/p1)^-2)
    double v1 = 1.0 / Math.sqrt(1 + m1*m1 / (p1*p1));
    double v2 = 1.0 / Math.sqrt(1 + m2*m2 / (p2*p2));
    
    Velocity vel1Rest = new Velocity();
    Velocity vel2Rest = new Velocity();
    
    vel1Rest.setMagnitude((float)v1);
    vel1Rest.setDirection(((float)angleRest + PI) % TWO_PI);
    
    vel2Rest.setMagnitude((float)v2);
    vel2Rest.setDirection((float)angleRest);
    
    // Transform rest frame velocities to world frame
    Velocity vel1 = vel1Rest.mapFrom(this.velocity);
    Velocity vel2 = vel2Rest.mapFrom(this.velocity);
    
    Dbg.say(vel1.toString());
    Dbg.say(vel2.toString());
    
    Particle particle1 = new Particle(m1, this.position, vel1);
    Particle particle2 = new Particle(m2, this.position, vel2);
    
    createdParticles.add(particle1);
    createdParticles.add(particle2);
    
    return createdParticles;
  }
  
  /**
   * Trigger the decay of this particle within the scene,
   * producing a pair of new particles.
   */
  public List decay() {
    
    double deltaM = this.mass * Math.random();
    
    double m1 = (this.mass - deltaM) * Math.random();
    double m2 = this.mass - deltaM - m1;
    
    return this.splitDecay(m1, m2, random(-PI, PI));
  }
  
  public void updateDecay() {

    if (this.isDecaying) {
      
      float timespan = this.properTime - this.ageLastDecayUpdate;
      float chanceOfDecay = 1.0f - exp(-timespan / (float) this.meanLifetime);
      
      if (chanceOfDecay >= random(1.0f)) {
        this.decay();
      }
    }
    ageLastDecayUpdate = this.properTime;
  }
  
  /** End the worldline of this particle at its current position, and stop updating it. */
  public void terminate() {
    
    Dbg.say("Terminate: Particle" + this.getName());
    this.isActive = false;
  }
  
  
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
  
  color fillColor = 0xFF1B83F0;

  float pathColorR, pathColorG, pathColorB, pathColorA;
  color pathColor;
  
  
  // FRAME INTERFACE BEGIN
  
  DefaultFrame headFrame = new DefaultFrame();
  
  public float[] getPosition(){
    return headFrame.getPosition();
  }
  
  public Velocity getVelocity(){
    //return velocity;
    return headFrame.getVelocity();
  }
  
  public Vector3f getPositionVec() {
    return headFrame.position;
  }
  
  public Vector3f getDisplayPositionVec() {
    return headFrame.displayPosition;
  }
  
  public float[] getDisplayPosition() {
    
    return headFrame.getDisplayPosition();
  }
  
  public Plane getSimultaneityPlane(){
    return headFrame.getSimultaneityPlane();
  }
  
  public float getAge() {
    return headFrame.getAge() + headFrame.getAncestorsAge();
  }
  
  public float getAncestorsAge() {
    return headFrame.getAncestorsAge();
  }
  
  public AxesSettings getAxesSettings() {
    return this.headFrame.axesSettings;
  }
  // FRAME INTERFACE END
  
  {
    colorMode(RGB,1.0);
    
    try {
      setPathColor(color(0,0.8,0.8,prefs.getFloat("LIGHTING_WORLDLINES")));
    }
    catch (Exception e) {
      setPathColor(color(0, 0.8, 0.8, 1.0));
    }
  }
  
  public Particle(Vector3f pos, Vector3f vel ){
    this.labelBuilder = new ParticleLabelBuilder();
    
    headFrame = new DefaultFrame(pos, vel);
    recordStateToPathHistory();
    
    setVelocity(vel.x, vel.y);
    setPosition(pos);
  }
  
  public Particle(double mass, Vector3f pos, Velocity vel) {
  
    this(pos, vel);
    this.mass = mass;
  }
  
  public Particle( Vector3f pos, Velocity vel) {
    this( pos, new Vector3f(vel.vx, vel.vy, 0) );
  }
  
  public Particle () {
    this(new Vector3f(1E-7,0,0), new Vector3f(0,0,0));
  }
  
  public void setPosition(Vector3f v){
    setPosition(v.x, v.y, v.z);
  }
  
  public void setPosition(float x, float y, float z){
    position.set(x, y, z);
    updatePosition();
  }
  
  public void updatePosition() {
    
    headFrame.setPosition(position);
    
    updateHistory();
  }
  
  public void setAllVisibility(boolean b) {
    this.isVisible = b;
    this.headFrame.axesSettings.setAllVisibility(b);
  }
  
  public void setVelocity(float x, float y){
    velocity.setComponents(x, y);
    headFrame.setVelocity(x, y);
  }
  
  public void update(float dt){
    
    if ( this.isActive ) {
      
      updateImpulse();
      
      position.x += velocity.vx * dt;
      position.y += velocity.vy * dt;
      position.z += dt;
      
      setPosition(position);
      setProperTime(this.properTime + dt / this.velocity.gamma);
      
      updateDecay();
    }
    updateLabel();
  }
  
  public void setProperTime(float time) {
    this.properTime = time;
    properTimeHist[histCount] = properTime;
    
    headFrame.setAge(this.properTime - frameHist[histCount].getAncestorsAge());
  }
  
  public void updateHistory() {
    
    Velocity velLast = frameHist[histCount-1].getVelocity();
    
    int elapsedFrames = frameCount - frameCountLastHistUpdate;
    float directionChange = abs((velLast.direction - headFrame.getVelocity().direction) % PI);
    float velocityChange = abs(velLast.magnitude - headFrame.getVelocity().magnitude);
    
    if ( (elapsedFrames > 12) && 
         ( (directionChange > TWO_PI * 0.01) || (velocityChange > velocity.magnitude * 0.01) ) ) {
      
      recordStateToPathHistory();
    }
  }
  
  private void recordStateToPathHistory() {
    
    frameHist[histCount] = headFrame.clone();
    
    histCount++;
    
    if (histCount >= frameHist.length) {
      // For now, just reset path history if out of space
      histCount = 0;
      recordStateToPathHistory();
      Dbg.warn("Resetting path history for particle: " + this.getName());
    }
    
    frameHist[histCount] = headFrame;
    headFrame.setAncestorsAge(this.properTime);
    
    frameCountLastHistUpdate = frameCount;
  }
  
  public void updateTransformedHist(Matrix3f lorentzMatrix){
    
    Vector3f source = new Vector3f();
    Vector3f target = new Vector3f();
    
    for (int i=0; i<=histCount; i++) {
      
      frameHist[i].updatePosition();
    }
  }
  
  public void drawGL(GL gl){
    //drawHeadGL(gl);
    drawPathGL(gl);
  }
  
  public void drawHead(){
    float[] displayPos = this.getDisplayPosition();
    drawHead(displayPos[0], displayPos[1], displayPos[2]);
  }
  
  public void drawHead(float x, float y, float z) {
    if (! this.isVisible) { return; }
    
    pushMatrix();

    translate(x, y, z);
    rotate(velocity.direction - HALF_PI);

    fill(fillColor);

    triangle(0, 1, -.5, -1, .5, -1);
    popMatrix();
  }
  
  public void drawHeadGL(GL gl, float[] pos) {
    if (! this.isVisible) { return; }
    drawHeadGL(gl, pos[0], pos[1], pos[2]);
  }
  
  public void drawHeadGL(GL gl){
    float[] displayPos = this.getDisplayPosition();
    drawHeadGL(gl, displayPos);
  }
  
  public void drawHeadGL(GL gl, Vector3f V){
    drawHeadGL(gl, V.x, V.y, V.z);
  }
  
  public void drawHeadGL(GL gl, float x, float y, float z) {
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

  public Vector3f getIntersection(Frame f) {
    Vector3f theIntersection = new Vector3f();
    
    Plane plane = f.getSimultaneityPlane();
    
    Line intersectingLine;
    DefaultFrame intersectingFrame = null;
    
    if (frameHist[0].isAbove(plane)) {
      return null;
    }
    else if ( !headFrame.isAbove(plane) || histCount == 1 ) {
      intersectingFrame = (this.isActive) ? headFrame : null;
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
  
  public DefaultFrame findHighestFrameBelow(Plane thePlane) {
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
  
  public void drawIntersectionGL(GL gl, Frame f){
    
    drawHeadGL(gl, getIntersection(f));
  }
  
  // A variation on drawPath using glBegin() and glVertex()
  public void drawPathGL(GL gl){
    
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
    gl.glEnd();
  }
  
  
  // OLD PROPELSELF, EMISSION, AND IMPULSE
  // TODO: MODEL WITH DECAY EMISSIONS INSTEAD
  
  public void propelSelf(float momentumDeltaX, float momentumDeltaY) {
    
    addImpulse(momentumDeltaX, momentumDeltaY);
    
    emissionMomentumX += momentumDeltaX;
    emissionMomentumY += momentumDeltaY;
    emissionMomentumTotal = abs(emissionMomentumX) + abs(emissionMomentumY);
  }
  
  private void addImpulse(double dp_x, double dp_y) {
    impulseX += dp_x;
    impulseY += dp_y;
  }
  
  private void updateEmission() {
    
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
  
  private void emit(Particle emission) {
    
    addEmission(emission);
    millisLastEmission = millis();
    
    // TEMPORARY, SWITCH TO DECAY EMISSION
    this.mass -= emission.mass;
    emissionMomentumX = emissionMomentumY = emissionMomentumTotal = 0;
  }
  
  public void emitEnergy(float massEnergy, float direction) {
    
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

  private void updateImpulse() {
    
    updateEmission();
    
    float dp_x = impulseX * prefs.getFloat("INPUT_RESPONSIVENESS");
    float dp_y = impulseY * prefs.getFloat("INPUT_RESPONSIVENESS");

    impulseX -= dp_x;
    impulseY -= dp_y;
    
    float p_x = (float) mass * velocity.gamma * velocity.vx;
    float p_y = (float) mass * velocity.gamma * velocity.vy;

    float p_x_final = p_x + dp_x;
    float p_y_final = p_y + dp_y;

    float heading_final = atan2(p_y_final, p_x_final);

    float p_mag_final = sqrt(p_x_final*p_x_final + p_y_final*p_y_final);

    // Checked this result from French prob. 1.15; seems to work
    float v_mag_final = 1.0/sqrt(pow(((float)mass/p_mag_final), 2) + C*C);

    v_mag_final = constrain(v_mag_final, 0.0, 1 - 1E-6);//1E-7);
    
    //velocity.setComponents( cos(heading_final) * v_mag_final, sin(heading_final) * v_mag_final);
    setVelocity( cos(heading_final) * v_mag_final, sin(heading_final) * v_mag_final );
  }
  
  public void setFillColor(color c) {
    this.fillColor = c;
  }

  public void setPathColor(color c) {
    colorMode(RGB,1.0f);
    pathColor = c;
    pathColorR = red(c);
    pathColorG = green(c);
    pathColorB = blue(c);
    pathColorA = alpha(c);
  }
  
  // Selectable Label Interface Functions
  
  public String getLabel() {
    return this.label;
  }
  
  public String getName() {
    if (this.name == "" || this.name == null) {
      return "p." + particles.indexOf(this);
    }
    else {
      return this.name;
    }
  }
  
  public void setName(String theName) {
    this.name = theName;
  }
  
  public void setLabel(String theLabel) {
    this.label = theLabel;
  }
  
  public void updateLabel() {
    setLabel(
      this.name + "\n" + 
      labelBuilder.buildLabel(this)
     );
  }
}

public class ParticleLabelBuilder {
  
  public ParticleLabelBuilder() {
  }
  
  public String buildLabel(Particle p) {
    
    String theLabel = (
      "p : " + nfVec(p.getPositionVec(), 3) + "\n" +
      //"p': " + nfVec(p.getDisplayPositionVec(), 3) + "\n" +
      //"fromTarget : " + nfVec(targetToParticle, 3) + "\n" +
      //"fromTarget': " + nfVec(targetToParticlePrime, 3) + "\n" +
      "velocity: (" + nf(p.velocity.magnitude, 0, 6) + ")\n" +
      "mass: ("  + nf((float)p.mass, 0, 4) + ")\n" +
      "age: (" + nf(p.properTime, 0, 1) + ")\n"
      
      //"headFrame.getAncestorsAge(): " + nf(p.headFrame.getAncestorsAge(), 0, 2) + "\n" +
      //"headFrame.getAge(): " + nf(p.headFrame.getAge(), 0, 2)  + "\n"
      );
    
    return theLabel;
  }
}

public interface ParticleDriver {
  public void drive(Particle p);
}

public class SineVelocityParticleDriver implements ParticleDriver {
  public float velAmplitude;
  public float wavelength;
  
  public SineVelocityParticleDriver(float wavelength, float velAmplitude) {
    this.wavelength = wavelength;
    this.velAmplitude = velAmplitude;
  }
  
  public void drive(Particle p) {
    float t = p.getPositionVec().z;
    float k = TWO_PI / wavelength;
    float vx = sin(k*t) * velAmplitude;
    p.velocity.setComponents(vx, 0);
  }
}

public class DrivenParticle extends Particle {
  ParticleDriver particleDriver;
  
  public DrivenParticle(ParticleDriver theDriver) {
    this.particleDriver = theDriver;
  }
  
  public void update(float dt) {
    particleDriver.drive(this);
    super.update(dt);
  }
}
