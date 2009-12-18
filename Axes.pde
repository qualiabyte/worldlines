
class Position {
  float t, x, y;
  //float[] pos_xyt;
  //float[] pos_xyt_prime;
  /*
  float[] getXyt();
  
  float getX();
  float getY();
  float getT();
  */
  void getDisplayPos(float[] target_xyt){
    target_xyt[0] = x;
    target_xyt[1] = y;
    target_xyt[2] = t;
  }
  
  //static float[] getDisplayPos(float[] xyt);
}

class Velocity extends PVector {
  float vx,  vy;
  float direction;
  float magnitude;
  
  Velocity () {
    setComponents(0, 0);
  }
  
  void setComponents(float vx, float vy) {
    this.vx = vx;
    this.vy = vy;
    
    direction = atan2(vy, vx);
    magnitude = (float)Math.sqrt(vx*vx + vy*vy);
  }
  
  void setDirection(float direction) {

    this.direction = direction;
    updateComponents();
  }
  
  void setMagnitude(float magnitude) {

    this.magnitude = magnitude;
    updateComponents();
  }
  
  void updateComponents() {
    vx = magnitude * cos(direction);
    vy = magnitude * sin(direction);
  }
}

/*
class Frame {
  //float[] pos_xyt;
  //float[] pos_xyt_prime
  //float[] vel_xy;
  Position p;
  Velocity v;
}
*/

class Axes {

  Frame frame;
  
  float[] pos_xyt, pos_xyt_prime;
  float[] vel_xy;
/*
  Axes (float[] pos_xyt, float[] pos_xyt_prime, float[] vel_xy) {
    this.pos_xyt = pos_xyt;
    this.pos_xyt_prime = pos_xyt_prime;
    this.vel_xy = vel_xy;
  }
*/
  
  Axes (Frame f) {
    this.frame = f;
  }
  
  float[] displayPos() {
    return new float[] {
      TOGGLE_SPATIAL_TRANSFORM ? pos_xyt_prime[0] : pos_xyt[0],
      TOGGLE_SPATIAL_TRANSFORM ? pos_xyt_prime[1] : pos_xyt[1],
      TOGGLE_TEMPORAL_TRANSFORM ? pos_xyt_prime[2] : pos_xyt[2]
    };
  }
  
  void drawAxes () {
    drawAxes(this.frame);
  }
  
  void drawAxes (Frame f) {
    
    float[] x_hat = new float[] {15,0,0};
    float[] x_hat_prime = new float[3];
    float[] y_hat = new float[] {0,15,0};
    float[] y_hat_prime = new float[3];
    float[] z_hat = new float[] {0,0,15};
    float[] z_hat_prime = new float[3];
    
    
    Relativity.applyInverseDisplayTransforms(x_hat, x_hat_prime);
    Relativity.applyInverseDisplayTransforms(y_hat, y_hat_prime);
    Relativity.applyInverseDisplayTransforms(z_hat, z_hat_prime);
    
    //x_hat_prime = rotate_T(-theta_heading).inverseLorentz(gamma).rotate_T(theta_heading);
    
    float[] p1 = f.getDisplayPosition();
    //float[] p1 = f.getPosition();
    //float[] p1 = this.displayPos();
    
    Matrix3f M = Relativity.getRotationMatrix(millis()/300.0, 0, 0, 1);
    Vector3f V = new Vector3f(15, 0, 0);
    Vector3f V_prime = new Vector3f();
    
    M.transform(V, V_prime);
    
    float[] v_prime = new float[3];
    V_prime.get(v_prime);
    
    strokeWeight(2);
    stroke(1, 1, 1);
    lyne(p1, sum(p1, v_prime));
        
    stroke(1, 0.5, 0.5);
    lyne(p1, sum(p1, x_hat_prime));
    
    stroke(0.5, 0.5, 1);
    lyne(p1, sum(p1, y_hat_prime));
    
    stroke(0.5, 1, 0.5);
    lyne(p1, sum(p1, z_hat_prime));
  }
  
  void lyne (float[] a, float[] b) {
    line(a[0], a[1], a[2], b[0], b[1], b[2]);
  }

  float[] sum(float[] a, float[] b) {
  
    return new float[] {a[0] + b[0], a[1] + b[1], a[2] + b[2]};
  }
}
