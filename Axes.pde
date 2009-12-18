static class Basis {
  static float scale = 15;
  static float[] x_hat = new float[] {scale,0,0};
  static float[] y_hat = new float[] {0,scale,0};
  static float[] z_hat = new float[] {0,0,scale};
}

class Axes {

  Frame frame;
  float alpha = 0.4;
  float length = 50;//15;
  
  float[][] basis = {{1,0,0},{0,1,0},{0,0,1}};
  float[][] basis_prime = new float[3][3];
  
  float[][] axis_colors = new float[][] {
    {1.0, 0.5, 0.5, alpha+0.1},
    {0.5, 0.5, 1.0, alpha+0.1},
    {0.5, 1.0, 0.5, alpha+0.1}
  };
  
  Axes(Frame f) {
    this.frame = f;
    setLength(length);
  }
  
  void setLength(float L) {
    length = L;
    
    basis = new float[][] {
      {L, 0, 0},
      {0, L, 0},
      {0, 0, L}
    };
  }
  
  /*
  void drawAxes() {
    drawAxes(this.frame);
  }
  */
  
  void drawGL(GL gl, Frame f) {
    drawAxesGL(gl, f);
  }
  
  // Variation on drawAxes which iterates over basis array
  void drawAxesGL(GL gl, Frame f) {
    
    float[] pos = f.getDisplayPosition();
    Velocity vel = f.getVelocity();
    
    //float[][] basis_inverse = new float[3][3];
    
    for (int i=0; i<3; i++) {
           
      //basis_inverse[i] = Relativity.inverseTransform(vel, basis[i]);
      //basis_display[i] = Relativity.displayTransform(targetParticle.velocity, basis_prime[i]);
      
      vel.basis_inverse[i].get(basis_prime[i]);      
      basis_prime[i] = Relativity.displayTransform(targetParticle.velocity, basis_prime[i]);
    }
    
    drawPlane(pos, basis_prime[0], basis_prime[1]);
    //drawGrid(pos, basis_prime[0], basis_prime[1]);
    
    gl.glLineWidth(2);
    gl.glBegin(GL.GL_LINES);
    for (int i=0; i<3; i++) {
      gl.glColor4fv(axis_colors[i], 0);
      gl.glVertex3fv(pos, 0);
      gl.glVertex3fv(sum(pos, basis_prime[i]), 0);
    }
    gl.glEnd();
  }
  
  // Old function repeats calls for each named basis vector
  void drawNamedAxes(Frame f) {
    float[] pos = f.getDisplayPosition();
    Velocity vel = f.getVelocity();
    
    float[] x_hat_prime = Relativity.inverseTransform(vel, Basis.x_hat);
    float[] y_hat_prime = Relativity.inverseTransform(vel, Basis.y_hat);
    float[] z_hat_prime = Relativity.inverseTransform(vel, Basis.z_hat);
    
    x_hat_prime = Relativity.displayTransform(targetParticle.velocity, x_hat_prime);
    y_hat_prime = Relativity.displayTransform(targetParticle.velocity, y_hat_prime);
    z_hat_prime = Relativity.displayTransform(targetParticle.velocity, z_hat_prime);
    
    
    Matrix3f M = Relativity.getRotationMatrix(millis()/300.0, 0, 0, 1);
    Vector3f V = new Vector3f(15, 0, 0);
    Vector3f V_prime = new Vector3f();
    
    M.transform(V, V_prime);
    
    float[] v_prime = new float[3];
    V_prime.get(v_prime);
    
    /*
    strokeWeight(2);
    
    //stroke(1, 1, 1, 0.5);
    //lyne(pos, sum(pos, v_prime));
    
    //stroke(1, 0.5, 0.5, alpha);
    
    //lyne(pos, sum(pos, x_hat_prime));
    
    //drawGrid(pos, x_hat_prime, y_hat_prime);
    
    //stroke(0.5, 0.5, 1, alpha);
    //lyne(pos, sum(pos, y_hat_prime));
    //drawGrid(pos, y_hat_prime, x_hat_prime);
    //drawPlane(pos, y_hat_prime, x_hat_prime);
    
    //stroke(0.5, 1, 0.5, alpha);
    //lyne(pos, sum(pos, z_hat_prime));
    */
    
    //float[] norm = new float[] {-z_hat_prime[0], -z_hat_prime[1], z_hat_prime[2]};
    drawPlane(pos, x_hat_prime, y_hat_prime);
    
    gl.glLineWidth(2);
    
    gl.glBegin(GL.GL_LINES);
    
    gl.glColor4f(1, 0.5, 0.5, alpha);
    gl.glVertex3fv(pos, 0);
    gl.glVertex3fv(sum(pos, x_hat_prime), 0);
    
    gl.glColor4f(0.5, 0.5, 1, alpha);
    gl.glVertex3fv(pos, 0);
    gl.glVertex3fv(sum(pos, y_hat_prime), 0);
    
    gl.glColor4f(0.5, 1, 0.5, alpha);
    gl.glVertex3fv(pos, 0);
    gl.glVertex3fv(sum(pos, z_hat_prime), 0);
    
    gl.glEnd();
  }
  
  void drawPlane(float[] origin, float[] v1, float[] v2) {
    
    gl.glBegin(GL.GL_QUADS);
    
    gl.glVertex3fv(origin, 0);
    
    gl.glColor4f(1, 0.5, 0.5, 0.3);
    gl.glVertex3fv(sum(origin, v1), 0);
    
    gl.glColor4f(0.1, 0.1, 0.1, 0.1);
    gl.glVertex3fv(sum(sum(origin, v1), v2), 0);
    
    gl.glColor4f(0.5, 0.5, 1, 0.3);
    gl.glVertex3fv(sum(origin, v2), 0);
    
    gl.glEnd();
    
    /*
    PVector V1 = new PVector(v1[0], v1[1], v1[2]);
    PVector V2 = new PVector(v2[0], v2[1], v2[2]);
    
    PVector normVec = V1.cross(V2);
    
    normVec.normalize();
    
    float[] norm = new float[3];
    normVec.get(norm);
    //gl.glNormal3f(0,0,1);
    gl.glNormal3fv(norm, 0);
    
    gl.glBegin(GL.GL_LINES);
    gl.glColor4f(0.5, 1, 1, alpha);
    gl.glVertex3fv(origin, 0);
    gl.glVertex3fv(sum(origin, norm), 0);
    gl.glEnd();
    */
  }
  
  void drawGrid(float[] pos, float[] v1, float[] v2) {
    int numlines = 10;
    
    float[] p_tmp = new float[3];
    
    float[][] v = new float[][] {v1, v2};
    
    gl.glBegin(GL.GL_LINES);
    for (int i=0; i<2; i++) {
    
      System.arraycopy(pos, 0, p_tmp, 0, 3);
      gl.glColor4fv(axis_colors[i], 0);
      
      for (int j=0; j<numlines; j++) {
        
        sum(p_tmp, v[(i+1)%2], p_tmp);
        gl.glVertex3fv(p_tmp, 0);
        gl.glVertex3fv(sum(p_tmp, v[i]), 0);
      }
    }
    gl.glEnd();
  }
  /*
  void lyne (float[] a, float[] b) {
    line(a[0], a[1], a[2], b[0], b[1], b[2]);
  }
  */

  float[] sum(float[] a, float[] b) {
  
    return new float[] {a[0] + b[0], a[1] + b[1], a[2] + b[2]};
  }
  
  float[] sum(float[] a, float[] b, float[] target){
    target[0] = a[0] + b[0];
    target[1] = a[1] + b[1];
    target[2] = a[2] + b[2];
    return target;
  }
}
