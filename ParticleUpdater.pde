class ParticleUpdater implements Runnable {
  Thread t;
  
  Particle targetParticle;
  Particle[] particles;
  float dt;

  public ParticleUpdater(Particle targetParticle, Particle[] particles) {
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
      targetParticle.updateTransformedHist();

      for (int i=0; i<PARTICLES; i++) {
        if (particles[i] == targetParticle)
          continue;
        
        //particles[i].updateTransformedHist();

        int updates_count = 0;
        int updates_max = 30;

        while ( updates_count < updates_max && 
                particles[i].xyt_prime[2] < targetParticle.xyt_prime[2]// + 0.001
          ){
          particles[i].update(dt);
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

