class Health { 
  PVector loc;
  int cycle = 7;
  int countdown = -1;
  int c = cycle;
  int r = 0;
  Health(PVector nloc) {
    loc =nloc;
  }
  void update() {
    loc.y+=0.15;
    if (game.gameFrameCount%5==0) {
      if (countdown>0) {
        if (countdown==7) {
          cycle = 0; 
          c = 0;
        }
        countdown--;
        r = 3;
        c = 7-countdown;
      } else {
        cycle++;
        if (cycle>16) cycle = 0;
        c = cycle;
        if (c>7) c=7-((cycle-7));
        c = constrain(c, 0, 7);
      }
    }
  }

  void draw() {
    pg.pushMatrix();      
    pg.translate(loc.x,loc.y);

   // pg.rotate(game.gameFrameCount/20.0);
          
    pg.image(healthIcon[r][c], -5, -5);
    pg.popMatrix();
    if (countdown>0) pg.image(healthIcon[2][7-countdown], 128-12, 128-(game.health+10));
  }
}

class Bullet {
  PVector loc;
  PVector origin;
  float heading;
  PVector pheading;
  int age = 0;
  int penetration = 2;
  Bullet(float x, float y, float nheading) {
    heading = nheading;
    loc = new PVector(x, y);
    origin = loc.copy();
    pheading = new PVector(sin(heading), cos(heading));
  }
  void update() {
    origin.lerp(loc, 0.1);
    age++;
    loc.x += pheading.x*bulletSpeed;
    loc.y += pheading.y*bulletSpeed;
  }
}