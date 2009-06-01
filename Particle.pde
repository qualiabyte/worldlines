class Particle{

  Particle( PVector pos, PVector vel ){
    this.pos = pos;
    setVel(vel);

    colorMode(RGB,255);
    setPathColor(color(0,200,200,180));

    updateHist();
  }

  void update(float dt){
    
    updateImpulse();
    
    pos.x += vel.x * dt;
    pos.y += vel.y * dt;
    pos.z += dt;
    
    properTime += dt / this.gamma;

    if((frameCount & 0xF) == 0) {
      histCount++;
    }
    updateHist();
  }

  void updateHist(){
    posHistX[histCount] = pos.x;
    posHistY[histCount] = pos.y;
    posHistZ[histCount] = pos.z;

    properTimeHist[histCount] = properTime;
  }

  void draw(){
    //drawHead();
    drawPathGL();
  }

  void drawHead(){
    drawHead(pos.x, pos.y, pos.z);
  }
  
  void drawHead(float x, float y, float z) {
    float heading = atan2(vel.y, vel.x)-PI/2;

    pushMatrix();
    
    translate(x, y, z);
    rotate(heading);

    fill(fillColor); //noStroke();

    triangle(0, 1, -.5, -1, .5, -1); // box(5, 5, 1);
    popMatrix();
    stroke(255);
  }

  // A variation on drawPath using glBegin() and glVertex()

  void drawPathGL(){

    pgl = (PGraphicsOpenGL)g;
    gl = pgl.beginGL();

    gl.glBegin(GL.GL_LINE_STRIP);

    float r, g, b, a;

    float targ_x = targetParticle.pos.x;
    float targ_y = targetParticle.pos.y;

    float vx = targetParticle.vel.x;
    float vy = targetParticle.vel.y;
    float vx_norm = targetParticle.velNormX;
    float vy_norm = targetParticle.velNormY;
    float v_mag = targetParticle.velMag;
    float gamma_v = targetParticle.gamma;
    
    float alphaFactor = 0.5 * pathColorA / ((float)histCount);
    
    float wavenumberFactor = TWO_PI * HARMONIC_FRINGES / pos.z;
    //float redWavenumberFactor = TWO_PI / 800;
    
    float draw_x, draw_y, draw_z;
    draw_x = draw_y = draw_z = 0;
    
    for (int i=0; i <= histCount; i++) {
      
      float harmonic = HARMONIC_CONTRIBUTION * 0.5*(1 - cos((wavenumberFactor * properTimeHist[i])%TWO_PI));
      
      r = (pathColorR+properTimeHist[i]%400)/400;
      g = pathColorG + harmonic;
      b = pathColorB;
      a = alphaFactor * g * i * (1 + sin(TWO_PI * 0.01 * properTimeHist[i]%100));
      
      if (TOGGLE_SPATIAL_TRANSFORM && (v_mag > 0.00001)) {
        //Distance in 2D from target to point on path
        float rx = posHistX[i] - targ_x;
        float ry = posHistY[i] - targ_y;
        
        float r_dot_v = rx * vx + ry * vy;
  
        // Projection |r| Cos(angle) gives the component of r parallel to v
        float r_cos_theta = r_dot_v / v_mag;
        
        // Get components of r parallel and perpendicular to v
        float r_para_x = r_cos_theta * vx_norm;
        float r_para_y = r_cos_theta * vy_norm;
        
        float r_perp_x = rx - r_cos_theta * vx;
        float r_perp_y = ry - r_cos_theta * vy;
        
        // Apply inverse lorentz transform to parallel component
        // this should give spatial scale as seen by the target
        // Note the graphical result for now is combination of the X' and T axis,
        // like the Brehme diagram, a mix of "my space and your time"
        float r_para_x_final = r_para_x * gamma_v;
        float r_para_y_final = r_para_y * gamma_v;
  
        float rx_final = r_perp_x + r_para_x_final;
        float ry_final = r_perp_y + r_para_y_final;
        
        // Final positions for graphics display of transformed space-time position
        draw_x = targ_x + rx_final;
        draw_y = targ_y + ry_final;
        draw_z = posHistZ[i];
      }
      else {
         draw_x = posHistX[i];
         draw_y = posHistY[i];
         draw_z = posHistZ[i];
      }
      gl.glColor4f(r, g, b, a);
      gl.glVertex3f(draw_x, draw_y, draw_z);
    }
    gl.glEnd();

    pgl.endGL();
    
    drawHead(draw_x, draw_y, draw_z);
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
    
    float p_x = mass * gamma * vel.x;
    float p_y = mass * gamma * vel.y;
    
    float p_x_final = p_x + dp_x;
    float p_y_final = p_y + dp_y;
    
    float heading_final = atan2(p_y_final, p_x_final);
    
    float p_mag_final = sqrt(p_x_final*p_x_final + p_y_final*p_y_final);
    
    // Checked this result from French prob. 1.15; seems to work
    float v_mag_final = 1.0/sqrt(pow((mass/p_mag_final), 2) + C*C);
    
    v_mag_final = constrain(v_mag_final, 0.0, 1 - 1E-7);
    
    setVel( cos(heading_final) * v_mag_final, sin(heading_final) * v_mag_final);
  }
  
  void setVel(PVector vel) {
    this.vel = vel;
    setVel(vel.x, vel.y);
  }
  
  void setVel(float x, float y) {
    vel.x = x;
    vel.y = y;
    
    velMag = sqrt(x*x + y*y);

    velNormX = vel.x / velMag;
    velNormY = vel.y / velMag;
    
    gamma = Relativity.gamma(velMag);    
  }
  
  void setPathColor(color c) {
    colorMode(RGB,1.0f);
    pathColor = c;
    pathColorR = red(c);
    pathColorG = green(c);
    pathColorB = blue(c);
    pathColorA = alpha(c);
  }
  
  int histCount;
  int histCountMax = 1000;

  float[] posHistX = new float[histCountMax];
  float[] posHistY = new float[histCountMax];
  float[] posHistZ = new float[histCountMax];
  
  //float[][] velHist = new float[histCountMax][3];
  float[] properTimeHist = new float[histCountMax];

  float mass = 1.0;
  
  PVector pos;
  PVector vel = new PVector(0, 0, 0);
  
  // Convenience vars
  float velMag;
  float velNormX, velNormY;
  float gamma;
  
  // Accumulated impulse (add to momentum smoothly)
  float impulseX, impulseY;

  color fillColor;

  float pathColorR, pathColorG, pathColorB, pathColorA;
  color pathColor;

  float properTime=0;
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

