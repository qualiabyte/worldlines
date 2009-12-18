
class Position extends PVector{
  float t, x, y;
  //float[] pos_xyt;
  //float[] pos_xyt_prime;
  
  void getDisplayPos(float[] target_xyt){
    target_xyt[0] = x;
    target_xyt[1] = y;
    target_xyt[2] = t;
  }
}

static class Basis {
  static float scale = 15;
  static float[] x_hat = new float[] {scale,0,0};
  static float[] y_hat = new float[] {0,scale,0};
  static float[] z_hat = new float[] {0,0,scale};
}

class Axes {

  Frame frame;

  Axes (Frame f) {
    this.frame = f;
  }
  
  /*
  float[] displayPos() {
    return new float[] {
      TOGGLE_SPATIAL_TRANSFORM ? pos_xyt_prime[0] : pos_xyt[0],
      TOGGLE_SPATIAL_TRANSFORM ? pos_xyt_prime[1] : pos_xyt[1],
      TOGGLE_TEMPORAL_TRANSFORM ? pos_xyt_prime[2] : pos_xyt[2]
    };
  }
  */
  
  void drawAxes () {
    drawAxes(this.frame);
  }
  
  void drawAxes (Frame f) {
    
    Velocity vel = f.getVelocity();
    
    float[] x_hat_prime = Relativity.inverseDisplayTransform(vel, Basis.x_hat);
    float[] y_hat_prime = Relativity.inverseDisplayTransform(vel, Basis.y_hat);
    float[] z_hat_prime = Relativity.inverseDisplayTransform(vel, Basis.z_hat);
    
    //Relativity.applyInverseDisplayTransforms(Basis.x_hat, x_hat_prime);
    //Relativity.applyInverseDisplayTransforms(Basis.y_hat, y_hat_prime);
    //Relativity.applyInverseDisplayTransforms(Basis.z_hat, z_hat_prime);
    
    float[] p1 = f.getDisplayPosition();
    
    Matrix3f M = Relativity.getRotationMatrix(millis()/300.0, 0, 0, 1);
    Vector3f V = new Vector3f(15, 0, 0);
    Vector3f V_prime = new Vector3f();
    
    M.transform(V, V_prime);
    
    float[] v_prime = new float[3];
    V_prime.get(v_prime);
    
    strokeWeight(2);
    stroke(1, 1, 1, 0.5);
    lyne(p1, sum(p1, v_prime));
    
    stroke(1, 0.5, 0.5, 0.5);
    lyne(p1, sum(p1, x_hat_prime));
    
    stroke(0.5, 0.5, 1, 0.5);
    lyne(p1, sum(p1, y_hat_prime));
    
    stroke(0.5, 1, 0.5, 0.5);
    lyne(p1, sum(p1, z_hat_prime));
  }
  
  void lyne (float[] a, float[] b) {
    line(a[0], a[1], a[2], b[0], b[1], b[2]);
  }

  float[] sum(float[] a, float[] b) {
  
    return new float[] {a[0] + b[0], a[1] + b[1], a[2] + b[2]};
  }
}
