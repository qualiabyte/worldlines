class ParticleUpdater implements Runnable {
  Thread t;
  
  Particle targetParticle;
  ArrayList particles; //Particle[] particles;
  float dt;

  public ParticleUpdater(Particle targetParticle, ArrayList particles) {
    this.targetParticle = targetParticle;
    this.particles = particles;
    t = new Thread(this);
  }
  
  public void start() {
    t.start();
  }

  public void run() {
    while(true) {

      targetParticle.update(dt);
      targetParticle.updateTransformedHist(lorentzMatrix);

      for (int i=0; i<PARTICLES; i++) {
        Particle p = (Particle) particles.get(i);
        if (p == targetParticle)
          continue;
        
        //p.updateTransformedHist();

        int updates_count = 0;
        int updates_max = 30;
        
        while ( updates_count < updates_max && 
                p.getDisplayPosition()[2] < targetParticle.getDisplayPosition()[2]// + 0.001
          ){
          p.update(dt);
          updates_count++;
        }
      }
      
      try {
        t.sleep(100);
      }
      catch (InterruptedException e) {
        e.printStackTrace();
      }
    }
  }
}

