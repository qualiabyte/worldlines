// Particle
// tflorez

class Particle implements Frame {
  
  // FRAME INTERFACE BEGIN
  Velocity velocity;  
  
  float[] getPosition(){
    return xyt;
  }
  
  Velocity getVelocity(){
    return velocity;
  }
  
  float[] getDisplayPosition(){
    //return xyt_prime;
    //return Relativity.displayTransform(targetParticle.velocity, xyt);
    return Relativity.selectDisplayComponents(xyt, xyt_prime);
  }
  // FRAME INTERFACE END

  Particle () {
    this(
      new PVector(0,0,0), //pos
      new PVector(0,0)    //vel
    );
  }
  
  Particle( PVector pos, PVector vel ){
    this.pos = pos;
    this.velocity = new Velocity(vel.x, vel.y);
    
    colorMode(RGB,1.0);
    setPathColor(color(0,0.8,0.8,LIGHTING_WORLDLINES));

    updateHist();
  }

  void update(float dt){
    
    updateImpulse();
    
    xyt[0] = pos.x += velocity.vx * dt;
    xyt[1] = pos.y += velocity.vy * dt;
    xyt[2] = pos.z += dt;
    
    //Relativity.applyTransforms(xyt, xyt_prime);
    xyt_prime = Relativity.displayTransform(targetParticle.velocity, xyt);
    
    properTime += dt / this.velocity.gamma;
    
    if((frameCount & 0xF) == 0 && frameCount > frameCountLastHistUpdate) {
      frameCountLastHistUpdate = frameCount;
      histCount++;
    }
    updateHist();
  }

  void updateHist(){
    xyt_hist[histCount][0] = posHistX[histCount] = pos.x;
    xyt_hist[histCount][1] = posHistY[histCount] = pos.y;
    xyt_hist[histCount][2] = posHistZ[histCount] = pos.z;
    
    System.arraycopy(xyt_prime, 0, xyt_prime_hist[histCount], 0, 3);
    
    properTimeHist[histCount] = properTime;
  }
  
  void updateTransformedHist(){
    
    for (int i=0; i<=histCount; i++){
      Relativity.applyTransforms(xyt_hist[i], xyt_prime_hist[i]);
    }
    Relativity.applyTransforms(xyt, xyt_prime);
  }

  void drawGL(GL gl){
    drawPathGL(gl);
  }
  
  /*
  void drawHead(){
    drawHead( 
      TOGGLE_SPATIAL_TRANSFORM ? xyt_prime[0] : pos.x,
      TOGGLE_SPATIAL_TRANSFORM ? xyt_prime[1] : pos.y,
      TOGGLE_TEMPORAL_TRANSFORM ? xyt_prime[2]: pos.z );
  }
  */
  void drawHead(float x, float y, float z) {
    pushMatrix();

    translate(x, y, z);
    rotate(velocity.direction - PI/2);

    fill(fillColor);

    triangle(0, 1, -.5, -1, .5, -1); // box(5, 5, 1);
    popMatrix();
  }
  
  void drawHeadGL(GL gl){
    gl.glPushMatrix();
    
    //gl.glColor4f(0.941, 0.105, 0.367, 1.0);
    gl.glColor4fv(fillColor4fv, 0);
    
    gl.glTranslatef(xyt_prime[0], xyt_prime[1], xyt_prime[2]);
    gl.glRotatef(degrees(velocity.direction-PI/2), 0, 0, 1);
    
    gl.glBegin(GL.GL_TRIANGLES);
    gl.glVertex2f(0, 1);
    gl.glVertex2f(-0.5, -1);
    gl.glVertex2f(+0.5, -1);
    gl.glEnd();
    
    gl.glPopMatrix();
  }

  // A variation on drawPath using glBegin() and glVertex()

  void drawPathGL(GL gl){

    gl.glBegin(GL.GL_LINE_STRIP);

    float r, g, b, a;

    //float alphaFactor = 0.5 * pathColorA / ((float)histCount);
    float alphaFactor = 0.5 * LIGHTING_WORLDLINES / ((float)histCount);


    float wavenumberFactor = TWO_PI * HARMONIC_FRINGES / pos.z;
    //float redWavenumberFactor = TWO_PI / 800;
    
    for (int i=0; i <= histCount; i++) {

      float harmonic = HARMONIC_CONTRIBUTION * 0.5*(1 - cos((wavenumberFactor * properTimeHist[i])%TWO_PI));

      r = (pathColorR+properTimeHist[i]%400)/400;
      g = pathColorG - harmonic;
      b = pathColorB;
      a = alphaFactor * g * i * (1 + sin(TWO_PI * 0.01 * properTimeHist[i]%100));
/*
      xyt[0] = posHistX[i];
      xyt[1] = posHistY[i];
      xyt[2] = posHistZ[i];

      Relativity.applyTransforms(xyt, xyt_prime);
*/
      gl.glColor4f(r, g, b, a);
      gl.glVertex3f(xyt_prime_hist[i][0], xyt_prime_hist[i][1], xyt_prime_hist[i][2]);
    }
    gl.glVertex3f(xyt_prime[0], xyt_prime[1], xyt_prime[2]);
    gl.glEnd();
  }

  void addImpulse(float dp_x, float dp_y) {
    impulseX += dp_x;
    impulseY += dp_y;
  }

  void updateImpulse() {

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
    
    velocity.setComponents( cos(heading_final) * v_mag_final, sin(heading_final) * v_mag_final);
  }

  float[] getColor4fv(color c) {
    return new float[] {
      red(c),
      blue(c),
      green(c),
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
  
  PVector pos;

  float properTime;
  float mass = 1.0;
  
  int histCount = 1;
  int histCountMax = 1000;
  int frameCountLastHistUpdate = 0;

  // Permanent record of particle's path
  float[] posHistX = new float[histCountMax];
  float[] posHistY = new float[histCountMax];
  float[] posHistZ = new float[histCountMax];
  
  float[] properTimeHist = new float[histCountMax];

  // Predeclare arrays
  float[] xyt = new float[3];
  float[] xyt_prime = new float[3];
  
  float[][] xyt_hist = new float[histCountMax][3];
  float[][] xyt_prime_hist = new float[histCountMax][3];

  // Accumulated impulse (add to momentum smoothly)
  float impulseX, impulseY;

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

