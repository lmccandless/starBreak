/*
  Navigates the flow field image to plan a path
*/

class Pather {
  PVector loc, vel;
  final int radius = 5;
  final int s = radius+1;
  final int ws = small*small;
  final int wsm = small*small-1;
  int health = 4;
  Pather(PVector nloc) {
    loc = nloc.copy();
    vel = new PVector(0, 0);
  }

  boolean damage(){
    health--;
    if (health<=0) return true;
    return false;
  }

  void update() {
    if (loc.y > small-10) {
      vel.y-=0.04;
    }

    if (loc.y<small-1) {
      vel.mult(7.0);
      vel.add(pathPlan().mult(1.3));
      vel.div(8.0);
    }

    loc.add(vel);
    if (loc.x < 1) loc.x = small-2;
    if (loc.x > small-1) loc.x = 2;
    loc.x = constrain(loc.x, 1, small-1);
    loc.y = constrain(loc.y, 1, small-1);
  }

  PVector pathPlan() { // Plans several steps ahead 
    PVector t = loc.copy();
    for (int i = 0; i < 8; i++) {
      t.add(getDirection(t).mult(0.5));
    }
    return t.sub(loc).normalize().mult(0.5);
  }

  PVector getDirection(PVector l) { // converts PVec location to pixel location
    return getDirection(round(l.x)+round(l.y)*small);
  }

  PVector getDirection(int ijq) { 
    PVector dir = new PVector(0, 0);
    for (int d = 1; d < 8; d+=2) {
      int ind =  constrain(ijq+d,0,wsm);
      dir.x +=  brightnessDecode(pathMap.pixels[ind])/d;
      ind = constrain(ijq-d,0,wsm);
      dir.x -= brightnessDecode(pathMap.pixels[ind])/d;
      ind = constrain(ijq+small*d,0,wsm);
      dir.y += brightnessDecode(pathMap.pixels[ind])/d;
      ind = constrain(ijq-small*d, 0,wsm);   
      dir.y -= brightnessDecode(pathMap.pixels[ind])/d;
    }
    dir.normalize();
    return dir;
  }

  int brightnessDecode(color c) {
    return int(red(c)+blue(c)+green(c));
  }
}