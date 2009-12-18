
class ParticleGrid {
  float spacing;
  float distance;
  float rows;
  
  ParticleGrid (float spacing, float distance) {
    this.spacing = spacing;
    this.distance = distance;
    this.rows = 2 * (int) (distance / spacing);
  }
  
  // Draw worldlines of grid elements lying below observer's plane of simult.
  void draw(float[] xyt_obs){ // float[] vel_obs) {
  
    float x_corner = (int) (xyt_obs[0] / spacing) * spacing - distance;
    float y_corner = (int) (xyt_obs[1] / spacing) * spacing - distance;
    float z_corner = (int) (xyt_obs[2] / spacing) * spacing;
    
    //float [][] M_duv
    //fill(255, 150, 0, 255);
    //stroke(255, 150, 0, 255);
    //stroke(255);
    
    pgl = (PGraphicsOpenGL)g;
    gl = pgl.beginGL();
    
    gl.glBegin(GL.GL_POINTS);
    
    
    float[] xyz = new float[3];
    float[] xyz_prime = new float[3];
    
    for(int i=0; i<rows; i++){
      float x = x_corner + i*spacing;
  
      for(int j=0; j<rows; j++){
        float y = y_corner + j*spacing;
        
        //for(int k=0; x * xyt_obs[0] + y * xyt_obs[1] + k * spacing * xyt_obs[2] > 0; k++)
        //for(int k=0; k * spacing < xyt_obs[2]; k++ ) {
        for(int k=0; k < 3; k++) {
         
          float z = z_corner - k * spacing;
          //float z = xyt_obs[2] - k * spacing;
          
          xyz[0] = x;
          xyz[1] = y;
          xyz[2] = z;
          
          Relativity.applyTransforms(xyz, xyz_prime);
          
          gl.glColor4f(1.0, 0.3, 0.6, 0.9);
          gl.glVertex3f(x, y, z);
          
          gl.glColor3f(0.3, 0.3, 1);
          gl.glVertex3f(xyz_prime[0], xyz_prime[1], xyz_prime[2]);
        }
        //line(x, y, 0, x, y, );
      }
    }
    gl.glEnd();
  }
  
  //getLinePlaneIntersect(p1x, p1y, p1z, nx, ny, nz, p2x, p2y, p2z, dx, dy, dz)
  //getLinePlaneIntersect(float[] p1, float[] n, float[] p2, float[] d) {
  //float[][] M_duv;
  //}
}

