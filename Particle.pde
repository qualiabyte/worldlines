// Particle
// tflorez

import geometry.*;

class Particle implements Frame {
  
  // FRAME INTERFACE BEGIN
  Velocity velocity = new Velocity();
  DefaultFrame headFrame = new DefaultFrame();
  
  float[] getPosition(){
    //return xyt;
    return headFrame.getPosition();
  }
  
  Velocity getVelocity(){
    //return velocity;
    return headFrame.getVelocity();
  }
  
  float[] getDisplayPosition(){
    //return xyt_prime;
    //return Relativity.displayTransform(targetParticle.velocity, xyt);
    //return Relativity.selectDisplayComponents(xyt, xyt_prime);
    
    return headFrame.getDisplayPosition();
  }
  
  Plane getSimultaneityPlane(){
    return headFrame.getSimultaneityPlane();
  }
  // FRAME INTERFACE END
  
  {
    colorMode(RGB,1.0);
    setPathColor(color(0,0.8,0.8,LIGHTING_WORLDLINES));
  }
  
  Particle( Vector3f pos, Vector3f vel ){
    
    setPosition(pos);
    setVelocity(vel.x, vel.y);
  }
  
  Particle () {
  }
  
  void setPosition(Vector3f v){
    setPosition(v.x, v.y, v.z);
  }
  
  void setPosition(float x, float y, float z){
    position.set(x, y, z);
    updatePosition();
  }
  
  void updatePosition() {
    xyt[0] = position.x;
    xyt[1] = position.y;
    xyt[2] = position.z;
    
    xyt_prime = Relativity.displayTransform(targetParticle.velocity, xyt);
        
    updateHistory();
    
    headFrame.setPosition(position);
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
  }
  
  void setProperTime(float time){
    this.properTime = time;
    properTimeHist[histCount] = properTime;
  }

  void updateHistory(){
    
    if(((frameCount & 0xF) == 2) && (frameCount > frameCountLastHistUpdate)) {
      
      frameCountLastHistUpdate = frameCount;
      histCount++;
    }
    xyt_hist[histCount][0] = position.x;
    xyt_hist[histCount][1] = position.y;
    xyt_hist[histCount][2] = position.z;
    
    System.arraycopy(xyt, 0, xyt_hist[histCount], 0, 3);
    System.arraycopy(xyt_prime, 0, xyt_prime_hist[histCount], 0, 3);
    
    velHistX[histCount] = velocity.vx;
    velHistY[histCount] = velocity.vy;
  }
  
  void updateTransformedHist(){
    
    for (int i=0; i<=histCount; i++){
      Relativity.applyTransforms(xyt_hist[i], xyt_prime_hist[i]);
    }
    //Relativity.applyTransforms(xyt, xyt_prime);
  }

  void drawGL(GL gl){
    //drawHeadGL(gl);
    drawPathGL(gl);
  }
  
  void drawHead(){
    drawHead(xyt_prime[0], xyt_prime[1], xyt_prime[2]);
  }
  
  void drawHead(float x, float y, float z) {
    pushMatrix();

    translate(x, y, z);
    rotate(velocity.direction - HALF_PI);

    fill(fillColor);

    triangle(0, 1, -.5, -1, .5, -1); // box(5, 5, 1);
    popMatrix();
  }
  
  void drawHeadGL(GL gl, float[] pos){
    drawHeadGL(gl, pos[0], pos[1], pos[2]); 
  }
  
  void drawHeadGL(GL gl){
    drawHeadGL(gl, xyt_prime);
  }
  
  void drawHeadGL(GL gl, Vector3f V){
    drawHeadGL(gl, V.x, V.y, V.z);
  }
  
  void drawHeadGL(GL gl, float x, float y, float z) {
    gl.glPushMatrix();
    
    //gl.glColor4f(0.941, 0.105, 0.367, 1.0);
    gl.glColor4fv(fillColor4fv, 0);
    
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
    
    Plane plane = f.getSimultaneityPlane();
    Line line = this.headFrame.getVelocityLine();
    
    // Testing with initial state for now:
    //line.setPoint(xyt_hist[1]);
    //line.setDirection(velHistX[1], velHistY[1], 1);
    
    //Velocity vel = this.headFrame.getVelocity();
    //line.setPoint(this.headFrame.getPosition());
    //line.setDirection(vel.vx, vel.vy, 1);
    
    Vector3f intersection = new Vector3f();
    
    plane.getIntersection(line, intersection);
    
    intersection = Relativity.displayTransform(targetParticle.velocity, intersection);
    
    return intersection;
  }
  
  void drawIntersectionGL(GL gl, Frame f){
    
    drawHeadGL(gl, getIntersection(f));
  }
  
  // A variation on drawPath using glBegin() and glVertex()
  void drawPathGL(GL gl){
    
    gl.glBegin(GL.GL_LINE_STRIP);
    
    float r, g, b, a;
    
    //float alphaFactor = 0.5 * pathColorA / ((float)histCount);
    float alphaFactor = 0.5 * LIGHTING_WORLDLINES / ((float)histCount);
    
    float wavenumberFactor = TWO_PI * HARMONIC_FRINGES / position.z;
    //float redWavenumberFactor = TWO_PI / 800;
    
    for (int i=0; i <= histCount; i++) {
      
      float harmonic = HARMONIC_CONTRIBUTION * 0.5*(1 - cos((wavenumberFactor * properTimeHist[i])%TWO_PI));
      
      r = (pathColorR+properTimeHist[i]%400)/400;
      g = pathColorG - harmonic;
      b = pathColorB;
      a = alphaFactor * g * i * (1 + sin(TWO_PI * 0.01 * properTimeHist[i]%100));
      
      gl.glColor4f(r, g, b, a);
      gl.glVertex3f(xyt_prime_hist[i][0], xyt_prime_hist[i][1], xyt_prime_hist[i][2]);
    }
    //gl.glVertex3f(xyt_prime[0], xyt_prime[1], xyt_prime[2]);
    gl.glEnd();
  }
  
  void propelSelf(float momentumDeltaX, float momentumDeltaY) {
    
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
    
    /*
    if (this == targetParticle) {
      println("emissionMomentum Total: " + emissionMomentumTotal);
      println("millisDiff: " + millisDiff);
    }
    */
    if ( (emissionMomentumTotal > 1E-4) && //0.02 * this.mass * velocity.magnitude) &&
         ((millis() - millisLastEmission) > 3000) ) {
      
      Particle emission = new Particle();
      
      emission.setPosition(this.position);
      emission.mass = 0.001 * this.mass;
      emission.addImpulse(-emissionMomentumX / emission.mass, -emissionMomentumY / emission.mass);
      //println("emission.velocity.magnitude: " + emission.velocity.magnitude);
      //TODO: more realistic emission velocity; also, photon emissions
      emit(emission);
    }
  }
  
  void emit(Particle emission) {
    
    addEmission(emission);
    emissionMomentumX = emissionMomentumY = emissionMomentumTotal = 0;
    millisLastEmission = millis();
    //println("emission: millis() = " + millis());
    //TODO: more realistic emission energy & mass
    this.mass -= emission.mass;
  }

  void updateImpulse() {
    
    updateEmission();
    
    float dp_x = impulseX * INPUT_RESPONSIVENESS;
    float dp_y = impulseY * INPUT_RESPONSIVENESS;

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

    v_mag_final = constrain(v_mag_final, 0.0, 1 - 1E-7);
    
    //velocity.setComponents( cos(heading_final) * v_mag_final, sin(heading_final) * v_mag_final);
    setVelocity( cos(heading_final) * v_mag_final, sin(heading_final) * v_mag_final );
  }

  float[] getColor4fv(color c) {
    colorMode(RGB, 1.0f);
    
    return new float[] {
      red(c),
      green(c),
      blue(c),
      alpha(c)
    };
  }
  
  void setFillColor(color c) {
    this.fillColor = c;
    fillColor4fv = getColor4fv(c);
  }

  void setPathColor(color c) {
    colorMode(RGB,1.0f);
    pathColor = c;
    pathColorR = red(c);
    pathColorG = green(c);
    pathColorB = blue(c);
    pathColorA = alpha(c);
  }
  
  Vector3f position = new Vector3f();

  float properTime;
  float mass = 1.0;
  
  int histCount = 0;
  int histCountMax = 1000;
  int frameCountLastHistUpdate = 0;
  int millisLastEmission = 0;
  
  float emissionMomentumX, emissionMomentumY, emissionMomentumTotal;

  float[] velHistX = new float[histCountMax];
  float[] velHistY = new float[histCountMax];
    
  float[] properTimeHist = new float[histCountMax];
  
  // Predeclare arrays
  float[] xyt = new float[3];
  float[] xyt_prime = new float[3];
  
  float[][] xyt_hist = new float[histCountMax][3];
  float[][] xyt_prime_hist = new float[histCountMax][3];

  // Accumulated impulse (add to momentum smoothly)
  float impulseX, impulseY, impulseTotal;
  Particle impulseParticle;
  
  color fillColor;
  float[] fillColor4fv;

  float pathColorR, pathColorG, pathColorB, pathColorA;
  color pathColor;
}

/* Original drawPath(), replaced by drawPathGL()
 
 void drawPath(){
 float[] from, to;
 
 for(int i=0; i<histCount-1; i++){
 from = posHist[i];
 to = posHist[i+1];
 stroke(pathColor, 255*i/histCount);
 
 line(from[0], from[1], from[2], to[0], to[1], to[2]);
 }
 
 line( posHist[histCount-1][0], posHist[histCount-1][1], posHist[histCount-1][2],
 pos.x, pos.y, pos.z );
 }
 */

/* A variation on drawPath() which pulses
 
 void drawPath(){
 float[] from, to;
 
 int alpha = abs((3*frameCount + (this.hashCode() >> 19)) % 510 - 255);
 
 for(int i=0; i<histCount-1; i++){
 from = posHist[i];
 to = posHist[i+1];
 stroke(pathColor, 255*i/histCount - alpha);
 
 line(from[0], from[1], from[2], to[0], to[1], to[2]);
 }
 
 line( posHist[histCount-1][0], posHist[histCount-1][1], posHist[histCount-1][2],
 pos.x, pos.y, pos.z );
 }
 */


/* A variation on drawPath using beginShape() and vertex()
 
 void drawPath(){
 
 beginShape();
 for(int i=0; i<histCount-1; i++){
 //stroke(pathColor, 255*i/histCount - alpha);
 vertex(posHist[i+1][0], posHist[i+1][1], posHist[i+1][2]);
 }
 vertex(pos.x,pos.y,pos.z);
 endShape();
 }
 */

