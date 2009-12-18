public class Velocity extends PVector {
  float vx,  vy;
  float direction;
  float magnitude;
  float gamma;
  
  Velocity (float vx, float vy) {
    setComponents(vx, vy);
  }
  
  Velocity () {
    this(0f, 0f);
  }
  
  void setComponents(float vx, float vy) {
    this.vx = vx;
    this.vy = vy;
    
    direction = atan2(vy, vx);
    magnitude = (float)Math.sqrt(vx*vx + vy*vy);
    updateGamma();
  }
  
  void setDirection(float direction) {

    this.direction = direction;
    updateComponents();
  }
  
  void setMagnitude(float magnitude) {

    this.magnitude = magnitude;
    updateGamma();
    updateComponents();
  }
  
  void updateComponents() {
    vx = magnitude * cos(direction);
    vy = magnitude * sin(direction);
  }
  
  void updateGamma() {
    gamma = Relativity.gamma(magnitude);
  }
}
