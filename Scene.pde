// Scene
// tflorez

abstract class Scene {
  
  void update() {};
  void draw() {};
}

//class World {
//}

abstract class ParticleScene extends Scene {
  List particles;
  
  ParticleScene () {
    this.particles = new ArrayList();
  }
}

class TwinParticleScene extends ParticleScene {
  
  TwinParticlePair twinParticlePair;
  Infobar ageDiffInfobar;
  
  TwinParticleScene(float relativeSpeed, float turnaroundTime) {
    
    this.twinParticlePair = new TwinParticlePair(relativeSpeed, turnaroundTime);
    
    //addTarget(twinParticlePair.twinA);
    addParticle(twinParticlePair.twinA);
    addParticle(twinParticlePair.twinB);
    
    println(twinParticlePair.twinA);
    println(twinParticlePair.twinB);
    
    FloatControl ageDiffFloatControl = new FloatControl("ageDiff", twinParticlePair.getAgeDiff());
    ageDiffFloatControl.setUnitsLabel("s");
    this.ageDiffInfobar = new Infobar(ageDiffFloatControl);
  }
  
  void draw() {
    this.ageDiffInfobar.draw();
  }
  
  void update() {
    ageDiffInfobar.floatControl.setValue(twinParticlePair.getAgeDiff());
    
    this.twinParticlePair.update();
    
    if (twinParticlePair.isTripComplete()) {
      //prefs.getStateControl("playStatus").setState("paused");
      twinParticlePair.beginDeparture();
    }
  }
}

class TwinParticlePair {
  Particle twinA, twinB;
  float relativeSpeed;
  float turnaroundTime;
  float initialAgeTwinB;
  float elapsedTime;
  
  float separation, separationLastUpdate;
  
  boolean returnHasBegun;
  
  /** Returns a list containing a new pair of "twin" Particles
    * @param relativeSpeed
    *    The relative speed between the frames of twins A and B,
    *    as a fraction of C
    * @param turnaroundTime
    *    Elapsed time before twinB decelerates and begins to return,
    *    in seconds as measured by twinB
    */
  TwinParticlePair(float relativeSpeed, float turnaroundTime) {
    
    this.relativeSpeed = relativeSpeed;
    this.turnaroundTime = turnaroundTime;
    
    twinA = new Particle();
    twinB = new Particle();
    
    this.beginDeparture();
  }
  
  void update() {
    
    elapsedTime = twinB.properTime - initialAgeTwinB;
    
    if (!returnHasBegun && elapsedTime > turnaroundTime) {
      this.beginReturn();
    }
    
    separationLastUpdate = separation;
    separation = this.getSeparation();
  }
  
  float getAgeDiff() {
    return twinA.getAge() - twinB.getAge();
  }
  
  float getSeparation() {
    return getDistance(twinA.getPositionVec(), twinB.getPositionVec());
  }
  
  boolean isTripComplete() {
    
    return (elapsedTime >= 2 * turnaroundTime && separation > separationLastUpdate );
  }
  
  void beginReturn() {
    twinB.setVelocity(-twinB.velocity.vx, -twinB.velocity.vy);
    returnHasBegun = true;
  }
  void beginDeparture() {
    twinB.setVelocity(relativeSpeed, 0);
    initialAgeTwinB = twinB.properTime;
    returnHasBegun = false;
  }
}

class RandomParticleScene extends ParticleScene {
  
  RandomParticleScene(int count) {
    
    this.particles.addAll( buildRandomParticles() );
  }
  
  List buildRandomParticles (
    //int count,
    //float xScale,
    //float yScale,
    //float dispersionScale,
    //float velocityDispersionScale,
    //float velocityEccentricity
    )
  {
    List theParticles = new ArrayList();
    
    for (int i=1; i<prefs.getInteger("PARTICLES"); i++) {
      
      float xScale = prefs.getFloat("START_POS_X_SCALE");
      float yScale = prefs.getFloat("START_POS_Y_SCALE");
      
      float x, y;
      
      float rScale = pow(10, prefs.getFloat("START_POS_DISPERSION"));
      
      if (prefs.getString("startPosWeight") == "cauchy") {
        
        float cauchyGamma = prefs.getFloat("cauchyGamma");
        float radius = rScale * cauchyWeightedRandom(cauchyGamma);
        float theta = random(0, TWO_PI);
        
        x = radius * cos(theta) * xScale;
        y = radius * sin(theta) * yScale;
      }
      else {
        x = random(-xScale, +xScale);
        y = random(-yScale, +yScale);
      }
      
      Vector3f pos = new Vector3f(x, y, 0);
      
      // Exponentially weight distribution of velocities towards lightspeed
      float vel_mag = 1-pow(random(1, 2), -prefs.getFloat("START_VEL_DISPERSION"));
      float heading = random(TWO_PI);
      
      float velXScale = prefs.getFloat("START_VEL_X_SCALE");
      float velYScale = prefs.getFloat("START_VEL_Y_SCALE");
      
      float vx = velXScale * vel_mag * cos(heading);
      float vy = velYScale * vel_mag * sin(heading) * (pow(1.5, -prefs.getFloat("START_VEL_ECCENTRICITY")));
      
      Vector3f vel = new Vector3f(vx, vy, 0);
      
      Particle p = new Particle(pos, vel);
      p.setFillColor(color(#1B83F0));
      
      theParticles.add(p);
    }
    
    return theParticles;
  }
}
