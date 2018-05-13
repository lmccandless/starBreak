class Game {
  ArrayList<Pather> pathers = new ArrayList<Pather>();
  ArrayList<Health> healths = new ArrayList<Health>();
  ArrayList<Bullet> bullets = new ArrayList<Bullet>();
  ArrayList<Bullet> bToRemove = new ArrayList<Bullet>();
  ArrayList<Pather> pToRemove = new ArrayList<Pather>();
  float health = 10;
  int score = 0;
  int gameFrameCount = 0;
  PVector mouseAvg = new PVector(0, 0);
  boolean shield;

  Game() {
    gameInit();
  }

  void gameStart() {
    groove.unmute();
    groove.loop();
    gameRunning = true;
    gameOver = false;
    mouseLock = true;
    setCursorState();
    gameInit();
  }

  void gameInit() {
    asteroids = (PGraphics2D)createGraphics(small, small, P2D);
    asteroids.loadPixels();
    for (int i = 0; i < small; i++) {
      for (int q = 0; q < small; q++) {
        asteroids.pixels[i+q*small] = transparent;
      }
    }
    asteroids.updatePixels();
    playerLoc = new PVector(64, 64);
    vel = new PVector(0, 0);
    bullets = new ArrayList<Bullet>();
    bulletImpacts = new ArrayList<Bullet>();
    pathers = new ArrayList<Pather>();
    health = 10;
    score = 0;
    gameFrameCount=0;
  }

  void spawnEnemies() {
    if ( ((gameFrameCount % max(1, (int)(100+score/10))) == 0) && (gameFrameCount%2000 >600)) {
      int r = ceil(3+score/30);
      while (r-->0) pathers.add(new Pather(new PVector(64+random(54)-27, small+4)));
    }
  }

  void gameInput() {
    mouseAvg.mult(23);
    mouseAvg.add(new PVector(mouseX-width/2, mouseY-height/2));
    mouseAvg.div(24);
    vel.add(mouseAvg.mult(acceleration*mouseSensitivity));
    float boost = 1;
    if (shift) boost = 2;
    if (keys['a']) vel.x-=acceleration*boost;
    if (keys['d']) vel.x+=acceleration*boost;
    if (keys['w']) vel.y-=acceleration*boost;
    if (keys['s']) vel.y+=acceleration*boost;

    if ((keys[' '] || (mousePressed && mouseButton==LEFT)) && (gameFrameCount%fireRate==0)) addBullet();
    if ((mousePressed && mouseButton==RIGHT) && health>1) shield = true;
    else shield = false;

    if (escape) {
      gameRunning = false;
      mouseLock = false;
      setCursorState();
    }
  }

  void bulletUpdate() {
    for (Bullet b : bullets) {
      b.update();
      for (Pather p : pathers) {
        if (b.loc.copy().sub(p.loc).magSq() < bulletHitDistance) {
          bulletImpacts.add(b);
          asHit.setPan(b.loc.x/small-0.5);
          asHit.setGain(masterVolume-2-random(2));
          asHit.trigger();
          if (p.damage()) {
            score++;
            pToRemove.add(p);
          } else bToRemove.add(b);
        }
      }
      if (b.age>50)bToRemove.add(b);
    }
    pathers.removeAll(pToRemove);
    bullets.removeAll(bToRemove);
    bToRemove = new ArrayList<Bullet>();
    pToRemove = new ArrayList<Pather>();
  }

  void gameFrame() {
    if (score>bestScore)bestScore = score;
    gameDraw();
    applyFluidObstacles();
    if (gameRunning) {
      if (mouseLock) r.warpPointer(width/2, height/2);

      updateFluid();
      // Rocket noise
      lpf.setFreq(vel.magSq()*1800);
      out.setPan(playerLoc.x/small - 0.5);
      out.setGain(masterVolume-10+vel.mag()*1.5);

      // End Game
      if (health<=0) {
        gameRunning = false;
        gameOver = true;
        mouseLock = false;
        setCursorState();
      }

      // Add Healths, enemies
      if (gameFrameCount % 330 ==0) healths.add(new Health(new PVector(random(128), random(64))));
      spawnEnemies();

      gameInput();
      // Move Player
      playerLoc.add(vel.copy());
      vel.limit(speedLimit);
      vel.mult(drag);
      if (playerLoc.x < 1) playerLoc.x = small-1;
      if (playerLoc.x > small-1) playerLoc.x = 1;
      playerLoc.y = constrain(playerLoc.y, 0, small);
      
      // Shield health drain and enemy kill
      if (shield) {
        health -= 0.05;
        for (Pather p : pathers) {
          if ((p.loc.copy().sub(playerLoc)).magSq() < shieldDistanceSq) {
            score++;
            pToRemove.add(p);
          }
        }
      }

      bulletUpdate();
      
      // Health collection, add, remove
      ArrayList hToRemove = new ArrayList<Health>();
      for (Health h : healths) {
        h.update();
        if (playerLoc.copy().sub(h.loc).magSq()<healthPickupDistance) {
          if (h.countdown<0) {
            asHeal.trigger();
            health+=2; 
            health = min(health, 10);
            h.countdown = 7;
          }
        }
        if ((h.loc.y>small)||(h.countdown == 1)) hToRemove.add(h);
      }
      healths.removeAll(hToRemove);
      
      // Enemy collision with player, dmg, remove enemy
      if (pathMap!=null) {
        for (Pather p : pathers) {
          p.update();
          if (p.loc.copy().sub(playerLoc).magSq() < 8) {
            if (!shield)health-=1.0;
            asCrash.trigger();
            pToRemove.add(p);
          }
          health = constrain(health, 0, 10);
        }
      }
      gameFrameCount++;
    } else {
      gameMenu();
    }
  }

  void gameMenu() {
    out.setGain(masterVolume-40);
    pg.beginDraw();
    pg.stroke(red);
    pg.strokeWeight(2);
    pg.fill(black);
    pg.rect(32, 32, 64, 75);
    pg.fill(white);
    pg.text("Resume \nMouseSen  \n\nRestart\nVolume\nExit Game", 32+4, 32+12);
    pg.text(nf(mouseSensitivity, 1, 1), 64+16, 32+23);
    pg.stroke(white);
    pg.strokeWeight(1);
    pg.line(38, 63, 90, 63);
    float sv = map(mouseSensitivity, 1, 10, 38, 90);
    pg.line(sv, 63-3, sv, 63+4);
    float mv = map(masterVolume, -40, 0, 70, 90);
    pg.line(70, 87, 90, 87);
    pg.line(mv, 84, mv, 90);
    int box = -1;
    box = floor(map(mouseYscl, 32, 10+32+48, 0, 5));
    if ((mouseXscl > 38)&&(mouseXscl < 90)) {
      if ((box>=0)&&(box!=1)&&(box<6)) {
        pg.strokeWeight(1);
        pg.stroke(yellow);
        pg.noFill();
        pg.rect(32+3, 34+11.7*box, 64-5, 11);
      }
      if (mousePressed) {
        if  ((box==0) && (mouseHit)) {
          gameRunning = true;
          mouseLock = true;
          setCursorState();
        } else if (box==2) {
          mouseSensitivity = map(mouseXscl, 38, 90, 1, 10);
        } else if  ((box==3) && (mouseHit)) {
          gameStart();
          gameRunning = false;
          gameOver = true;
          mouseLock = false;
          setCursorState();
        } else if (box==4) {
          masterVolume = map(mouseXscl, 70, 90, -40, 0);
          masterVolume = constrain(masterVolume, -40, 0);
          updateVolumes();
        } else if ((box==5) && (mouseHit)) exit();
      }
    }
    drawCursor();
    pg.endDraw();
    image(pg, 0, 0, width, height);
  }

  void addBullet() {
    PVector l = playerLoc.copy().add(vel.copy().mult(4));
    asFire.setPan(l.x/small - 0.5);
    asFire.setGain(masterVolume-(4+random(8)));
    asFire.trigger();
    bullets.add(  new Bullet(l.x, l.y, -vel.heading() + HALF_PI + (random(100)-50)/bulletSpread));
  }

  void drawPlayer() {
    pg.strokeWeight(0.4);
    pg.stroke(red);
    pg.fill(white);
    pg.pushMatrix();
    pg.translate(playerLoc.x, playerLoc.y);
    pg.rotate(vel.heading());
    pg.rect(-1, -1, 5, 2);
    pg.ellipse(0, 0, 3, 3);

    if (shield) {
      pg.stroke(red);
      pg.noFill();
      pg.strokeWeight(0.3);
      pg.ellipse(0, 0, shieldDistance, shieldDistance);
    }
    pg.popMatrix();
  }

  void drawBullets() {
    pg.stroke(yellow);
    pg.strokeWeight(0.5);
    pg.beginShape(LINES);
    for (Bullet b : bullets) {
      pg.stroke(white, 255);// 255-b.age*8);
      pg.strokeWeight(random(1));
      pg.vertex(b.origin.x, b.origin.y);
      pg.vertex(b.loc.x, b.loc.y);
      pg.stroke(yellow);
      pg.strokeWeight(1.5);
      pg.vertex(b.loc.x, b.loc.y);
      pg.vertex(b.loc.x + sin(b.heading)*bulletSpeed, b.loc.y + cos(b.heading)*bulletSpeed);
    }
    pg.endShape();
  }

  void drawEnemies() {
    pg.fill(red);
    pg.stroke(yellow);
    color c1, c2, c3;
    if (gameFrameCount%30 < 15) {
      c1 = yellow;
      c2 = white;
      c3 = red;
    } else { 
      c1 = red;
      c2 = yellow;
      c3 = white;
    }
    for (Pather p : pathers) {
      pg.fill(c1);
      pg.stroke(c2);
      pg.strokeWeight((float)p.health/8.0);
      pg.ellipse(p.loc.x, p.loc.y, 4-(4-p.health)/2, 4-(4-p.health)/2);
      pg.fill(c3);
      pg.noStroke();
      pg.ellipse(p.loc.x, p.loc.y, 2, 2);
    }
  }

  void applyFluidObstacles() {
    pg_obstacles.beginDraw();
    pg_obstacles.clear();
    pg_obstacles.image(asteroids, 0, 0);
    pg_obstacles.filter(INVERT);
    pg_obstacles.endDraw();
    fluid.addObstacles((PGraphics2D)pg_obstacles);
  }

  void gameDraw() {
    pathMap = cpuPathTrace() ;
    updateAsteroids();
    pg.beginDraw();
    pg.clear();

    pg.image(asteroids, 0, 0);
    pg.blendMode(ADD);
    pg.image(pg_fluid, 0, 0, small, small);
    pg.blendMode(REPLACE);
    pg.fill(transparent);
    pg.blendMode(BLEND);
    pg.noStroke();
    pg.image(heart, 128-13, 128-13);
    if ( health<9) pg.rect(128-13, 128-13, 13, 10-health);
    for (Health h : healths) h.draw();
    drawPlayer();
    drawBullets();
    drawEnemies();
    pg.stroke(white);
    pg.fill(white);
    pg.textFont(font);
    pg.text("Score: " + (int)score, 0, 128-1);


    pg.endDraw();
    image(pg, 0, 0, width, height);
    lastKeys = keys.clone();
  }

  int bar = 0; // for spawning yellow horizontal lines
  int barL = 0, barR = 0;
  void updateAsteroids() {
    asteroids.beginDraw();
    asteroids.loadPixels();
    //asteroids.blendMode(REPLACE);
    if ((gameRunning) && (gameFrameCount % 6 == 0)) {

      // shift all asteroid pixels down 1
      for (int i = 0; i < small; i++) {
        for (int q = small-1; q > 0; q--) { 
          asteroids.pixels[i+q*small] = asteroids.pixels[i+(q-1)*small];
        }
      }

      if (shield) {
        int pX = round(playerLoc.x), pY = round(playerLoc.y);
        int rad = shieldDistance;
        int xl = max(pX-rad, 0), xu = min(pX+rad, small-1), 
          yl = max(pY-rad, 0), yu = min(pY+rad, small-1);

        for (int i = xl; i < xu; i++) {
          for (int q = yl; q < yu; q++) {
            if ( (pow(pX-i, 2)+pow(pY-q, 2))<(shieldDistanceSq/2.7)) {
              asteroids.pixels[i+q*small] = transparent;
            }
          }
        }

        /*asteroids.fill(transparent);
         asteroids.stroke(transparent);
         asteroids.ellipseMode(CENTER);
         asteroids.strokeCap(ROUND);
         asteroids.strokeWeight(shieldDistance);
         // asteroids.line(pX, pY, pX-vel.x, pY-vel.y);
         asteroids.ellipse(pX, pY, rad, rad);*/
      }

      // generate top row of asteroids from perlin noise
      noiseDetail(12, 0.45);
      bar--;
      if (random(30)<2) {

        bar = 3;
        barL = round(random(128+16)-16);
        barR = round(barL + random(32));
      }
      for (int i = 0; i < small; i++) {
        float n = noise(i/10.0, gameFrameCount/60.0);
        if ((bar>0) && (i>barL) && (i<barR)) n = 1; //create horizontal bar
        if ( n > 0.67) {                            //create asteroid
          if ((n>0.7) && (n%0.2>0.09)) asteroids.pixels[i] = yellow;
          else asteroids.pixels[i] = white;
        } else asteroids.pixels[i] = transparent;
      }
    }

    // Enemy collides with asteroid
    for (Pather p : pathers) {
      PVector clr = p.loc.copy();
      clr.x += random(6)-3;
      clr.y += random(6)-3;
      if ((clr.x>0)&&(clr.x<small-1)&&(clr.y>0)&&(clr.y<small-1)) {
        asteroids.pixels[round(clr.x)+round(clr.y)*small] = transparent;
      }
    }

    // Bullet collides with asteroid
    for (Bullet b : bullets) {
      int i = round(b.loc.x) + round(b.loc.y)*small;
      if ((i>0)&&(i<small*small -1)) {

        asteroids.strokeWeight(4);
        asteroids.stroke(transparent);

        PVector l = b.loc.copy();
        PVector f = new PVector(sin(b.heading)*bulletSpeed, cos(b.heading)*bulletSpeed);
        f.mult(1/5.0);
        for (int q = 0; q<4; q++) { // lerp to make sure we hit all pixels
          if ((l.x<0)||(l.x>small-1)) break;
          int w = round(l.x) + round(l.y)*small;
          if ((w>0)&&(w<small*small -1)) {
            if ((asteroids.pixels[w] == white) || (asteroids.pixels[w] == yellow)) {
              asHit.setPan(b.loc.x/small-0.5);
              asHit.setGain(masterVolume-12-random(6));
              asHit.trigger();
              bulletImpacts.add(b);
              if (b.penetration--<1) bToRemove.add(b);
            }
            asteroids.pixels[w] = transparent;
          }
          l.add(f);
        }
      }
    }

    // Player collides with asteroid
    if (!shield) {
      int pi = constrain(round(playerLoc.x) + round(playerLoc.y)*small, 0, small*small-1);
      if ((asteroids.pixels[pi] == yellow) ||(asteroids.pixels[pi] == white)) {
        health -=0.1;
        asCrash.trigger();
        PVector col = new PVector(round(playerLoc.x), round(playerLoc.y));
        col.sub(playerLoc);
        vel.mult(-1.0);
        int w = round(playerLoc.x) + round(playerLoc.y)*small;
        asteroids.pixels[w] = transparent;
        playerLoc.sub(col.normalize().mult(2));
      }
    }
    asteroids.updatePixels();
    asteroids.endDraw();
  }
}