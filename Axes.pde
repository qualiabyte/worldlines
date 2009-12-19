
class Axes {

  Frame frame;

  float basisScale = 10;
  
  String[] restFrameBasisLabels = new String[] { "x", "y", "t" };
  String[] axesFrameBasisLabels = new String[] { "x'", "y'", "t'" };

  Vector3f[] restFrameBasis = new Vector3f[] { new Vector3f(1,0,0), new Vector3f(0,1,0), new Vector3f(0,0,1) };
  Vector3f[] restFrameDisplayBasis = new Vector3f[] { new Vector3f(), new Vector3f(), new Vector3f() };
  Vector3f[] axesFrameDisplayBasis = new Vector3f[] { new Vector3f(), new Vector3f(), new Vector3f() };
  
  float alpha = 0.4;
  float[][] axisColors = new float[][] {
    {1.0, 0.5, 0.5, alpha+0.2},
    {0.5, 0.5, 1.0, alpha+0.2},
    {0.15, 0.9, 1.0, alpha+0.2}, // {0.5, 1.0, 0.5, alpha+0.2},
  };
  
  Axes(Frame f) {
    this.frame = f;
  }
    
  void drawGL(GL gl) {
    drawGL(gl, this.frame);
  }
  
  void drawGL(GL gl, Frame f) {
    //drawAxesGL(gl, f);
    drawAxesGLVec(gl, f);
  }
  
  void drawAxesGLVec(GL gl, Frame f) {
    
    Vector3f pos = f.getDisplayPositionVec();
    Velocity vel = f.getVelocity();
    
    for (int i=0; i<3; i++) {
      Relativity.displayTransform(lorentzMatrix, vel.basisInverse[i], axesFrameDisplayBasis[i]);
      axesFrameDisplayBasis[i].scale(basisScale);
    }
    
    // XY PLANE
    drawPlane(pos, axesFrameDisplayBasis[0], axesFrameDisplayBasis[1]); //, axisColors[0], axisColors[1]);
    
    // AXES GRID LINES
    if ( prefs.getBoolean("showAllAxesGrid") ||
         ( prefs.getBoolean("showTargetAxesGrid") && f == targetParticle ) ) {
      //drawGrid(pos, axesFrameDisplayBasis, 0, 2);
      drawGrid(pos, axesFrameDisplayBasis[0], axesFrameDisplayBasis[2], axisColors[0], axisColors[2]);
      drawGridLabels(pos, axesFrameDisplayBasis);
    }
    
    // AXES FRAME BASIS
    drawBasis(pos, axesFrameDisplayBasis, axisColors);
    
    // REST FRAME BASIS   
    for (int i=0; i<3; i++) {
      Relativity.displayTransform(lorentzMatrix, restFrameBasis[i], restFrameDisplayBasis[i]);
      restFrameDisplayBasis[i].scale(basisScale);
    }
    drawBasis(pos, restFrameDisplayBasis, axisColors);

    if (prefs.getBoolean("showAllAxesLabels") || (prefs.getBoolean("showTargetAxesLabels") && f == targetParticle) ) {
      
      // LABELS
      drawBasisLabels(pos, axesFrameDisplayBasis, axesFrameBasisLabels);
      drawBasisLabels(pos, restFrameDisplayBasis, restFrameBasisLabels);
    }
  }

  void drawBasisLabels(Vector3f pos, Vector3f[] theBasis, String[] theBasisLabels) {
    Vector3f labelPos = new Vector3f();
    
    for (int i=0; i<3; i++) {
      labelPos.add(pos, theBasis[i]);
      myLabelor.drawLabelGL(gl, theBasisLabels[i], labelPos, 0.5);
    }
  }
  
  void drawGridLabels(Vector3f pos, Vector3f[] theBasis) {
    Vector3f labelPos = new Vector3f();
    
    for (int i=0; i<3; i++) {
      
      float basisLabelScale = 0.5 * 10;
      labelPos.scaleAdd(basisLabelScale, theBasis[i], pos);
      myLabelor.drawLabelGL(gl, "" + 10 * basisLabelScale, labelPos, 0.05);
    }
  }
  
  void drawBasis(Vector3f pos, Vector3f[] theBasis, float[][] theBasisColors) {
    
    gl.glLineWidth(2);
    gl.glBegin(GL.GL_LINES);
    for (int i=0; i<3; i++) {
      gl.glColor4fv(theBasisColors[i], 0);
      gl.glVertex3f(pos.x, pos.y, pos.z);
      gl.glVertex3f(pos.x + theBasis[i].x, pos.y + theBasis[i].y, pos.z + theBasis[i].z);
    }
    gl.glEnd();
  }
  
  void drawPlane(Vector3f pos, Vector3f v1, Vector3f v2) { //float[] color1, float[] color2) {
    Vector3f tmp = new Vector3f();
    
    gl.glBegin(GL.GL_QUADS);
      tmp.set(pos); gl.glVertex3f(pos.x, pos.y, pos.z);
      tmp.add(v1); gl.glColor4f(1.0, 0.5, 0.5, 0.3); gl.glVertex3f(tmp.x, tmp.y, tmp.z);
      tmp.add(v2); gl.glColor4f(0.1, 0.1, 0.1, 0.1); gl.glVertex3f(tmp.x, tmp.y, tmp.z);
      tmp.sub(v1); gl.glColor4f(0.5, 0.5, 1.0, 0.3); gl.glVertex3f(tmp.x, tmp.y, tmp.z);
    gl.glEnd();
  }
  
  void drawGrid(Vector3f pos, Vector3f v1, Vector3f v2, float[] color1, float[] color2) {
    
    int numlines = 10;

    Vector3f[] gridBasis = new Vector3f[] { v1, v2 };
    float[][] gridColors = new float[][] { color1, color2 };
    
    Vector3f lineStart = new Vector3f();
    Vector3f lineEnd = new Vector3f();
    
    gl.glBegin(GL.GL_LINES);
    for (int i=0; i<gridBasis.length; i++) {
    
      Vector3f lineBasis = gridBasis[i];
      Vector3f spacingBasis = gridBasis[ (i==0) ? 1 : 0 ];
      
      gl.glColor4fv(gridColors[i], 0);
      
      for (int j=0; j<numlines; j++) {
        
        lineStart.scaleAdd(j, spacingBasis, pos);
        gl.glVertex3f(lineStart.x, lineStart.y, lineStart.z);

        gl.glColor4fv(gridColors[i], 0);
        lineEnd.scaleAdd(numlines, lineBasis, lineStart);
        gl.glVertex3f(lineEnd.x, lineEnd.y, lineEnd.z);
      }
    }
    gl.glEnd();
  }
}

/*
  void drawGrid(float[] pos, float[] v1, float[] v2) {
    int numlines = 10;
    
    float[] p_tmp = new float[3];
    
    float[][] v = new float[][] {v1, v2};
    
    gl.glBegin(GL.GL_LINES);
    for (int i=0; i<2; i++) {
    
      System.arraycopy(pos, 0, p_tmp, 0, 3);
      gl.glColor4fv(axisColors[i], 0);
      
      for (int j=0; j<numlines; j++) {
        
        sum(p_tmp, v[(i+1)%2], p_tmp);
        gl.glVertex3fv(p_tmp, 0);
        gl.glVertex3fv(sum(p_tmp, v[i]), 0);
      }
    }
    gl.glEnd();
  }

  // Variation on drawAxes which iterates over basis array
  void drawAxesGL(GL gl, Frame f) {
    
    float[] pos = f.getDisplayPosition();
    Velocity vel = f.getVelocity();
    
    float[][] basis_prime = new float[3][3];
    
    for (int i=0; i<3; i++) {
      
      //basis_inverse[i] = Relativity.inverseTransform(vel, basis[i]);
      //basis_display[i] = Relativity.displayTransform(targetParticle.velocity, basis_prime[i]);
      
      vel.basisInverse[i].get(basis_prime[i]);
      basis_prime[i] = Relativity.displayTransform(targetParticle.velocity, basis_prime[i]);
    }
    
    drawPlane(pos, basis_prime[0], basis_prime[1]);
    if ( prefs.getBoolean("showAxesGridAll") ) {
      drawGrid(pos, basis_prime[0], basis_prime[1]);
    }
    
    gl.glLineWidth(2);
    gl.glBegin(GL.GL_LINES);
    for (int i=0; i<3; i++) {
      gl.glColor4fv(axisColors[i], 0);
      gl.glVertex3fv(pos, 0);
      gl.glVertex3fv(sum(pos, basis_prime[i]), 0);
    }
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
    
//    PVector V1 = new PVector(v1[0], v1[1], v1[2]);
//    PVector V2 = new PVector(v2[0], v2[1], v2[2]);
//    
//    PVector normVec = V1.cross(V2);
//    
//    normVec.normalize();
//    
//    float[] norm = new float[3];
//    normVec.get(norm);
//    gl.glNormal3fv(norm, 0);
//    
//    gl.glBegin(GL.GL_LINES);
//    gl.glColor4f(0.5, 1, 1, alpha);
//    gl.glVertex3fv(origin, 0);
//    gl.glVertex3fv(sum(origin, norm), 0);
//    gl.glEnd();
  }
*/

/*
static class Basis {
  static float scale = 15;
  static float[] x_hat = new float[] {scale,0,0};
  static float[] y_hat = new float[] {0,scale,0};
  static float[] z_hat = new float[] {0,0,scale};
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
    
    //strokeWeight(2);
    
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
  
  float[] sum(float[] a, float[] b) {
    return new float[] {a[0] + b[0], a[1] + b[1], a[2] + b[2]};
  }
  
  float[] sum(float[] a, float[] b, float[] target){
    target[0] = a[0] + b[0];
    target[1] = a[1] + b[1];
    target[2] = a[2] + b[2];
    return target;
  }
  
  void lyne (float[] a, float[] b) {
    line(a[0], a[1], a[2], b[0], b[1], b[2]);
  }
*/
