/*
 * Star Break | Copyright (C) 2018  Logan McCandless
 * MIT License: https://opensource.org/licenses/MIT
 */
 
// starBreak requires the minim and pixelflow libraries!
import ddf.minim.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;

Minim minim;

final float speedLimit = 4, drag = 0.95, acceleration = 0.06, 
  bulletSpread = 1000.0, bulletSpeed = 2;
final int small = 128, large = 512,
  fireRate = 3,
  bulletHitDistance = 36,
  healthPickupDistance = 16,
  shieldDistance = 14,
  shieldDistanceSq = shieldDistance*shieldDistance;
  
final color yellow = color(247, 222, 7), 
  white = color(255, 255, 255), 
  black = color(0, 0, 0), 
  red = color(255, 0, 0), 
  transparent = color(0, 0, 0, 0);

PVector playerLoc, vel;
boolean mouseLock = true, 
  gameOver = true, 
  gameRunning = true;
int bestScore = 0; 
float masterVolume = -8, 
  mouseSensitivity = 2.0, 
  scl = 4,
  mouseXscl =0, 
  mouseYscl = 0;

Game game;
PGraphics pg;
PGraphics2D asteroids;

void setup() {
  size(512, 512, P3D);
  noSmooth();
  frameRate(75);
  
  minim = new Minim(this);
  loadAudio();
  loadGfx();

  pg = createGraphics(small, small, P3D);
  pg.noSmooth();
  asteroids = (PGraphics2D)createGraphics(small, small, P2D);
  ((PGraphicsOpenGL)asteroids).textureSampling(2);
  ((PGraphicsOpenGL)g).textureSampling(2);
  ((PGraphicsOpenGL)pg).textureSampling(2);
  r = (GLWindow)surface.getNative();
  r.setPointerVisible(false);
  rectMode(CENTER);
  setupFlow();
  game = new Game();
   surface.setLocation(displayWidth/2 -512, displayHeight/2-256);
}

void mainMenuFluid() {
  background(black);
  pg.loadPixels(); 
  // Drip the main logo
  for (int i = 10; i < small-10; i++) {
    for (int q = 10; q < small/2; q++) {
      if ((random(2000)<1) && (pg.pixels[i+q*small] == yellow)) {
        bulletImpacts.add(new Bullet(i, q, random(TWO_PI)));
      }
    }
  }
  // follow the mouse or do pattern
  pg.beginDraw();
  pg.clear();
   pg.image(pg_fluid, 0, 0, small, small);
  pg.textFont(font);
 
  // for menu fluid graphics
  vel = new PVector(mouseX-pmouseX, mouseY-pmouseY);
  if (vel.mag()>1) {
    vel.mult(245);
    playerLoc = new PVector(mouseXscl, mouseYscl);
  } else {
    PVector p = playerLoc.copy();
    playerLoc = new PVector(sin(frameCount/25.0)*48+ 64, 64 + cos(frameCount/70.0)*48);
    vel = p.sub(playerLoc).mult(-300);
  }
  
}

void mainMenu() {
  //Mute music
  groove.mute();
  out.setGain(masterVolume-40);
  
  // Fluid logo
  updateFluid();
  game.applyFluidObstacles();
  mainMenuFluid();
  
  // Logo Text
  pg.textSize(22);
  pg.fill(white);
  pg.text("Star Break", 14, 39);
  pg.text("Star Break", 13, 40);
  pg.fill(yellow);
  pg.text("Star Break", 14, 40);
  pg.textSize(10);
  pg.fill(white);
  
  // Click Start
  if ((mouseXscl>50)&&(mouseXscl<70)&&(mouseYscl>70)&&(mouseYscl<82)) {
    if (mouseHit) {
      game.gameStart();
      asMenu.trigger();
    }
    pg.fill(red);
  }
  pg.text("start", 50, 80);
  pg.fill(white);
  if (bestScore>0)pg.text(" best score: " + (int)bestScore, 30, 100);
  pg.text("L/R click=  shoot/shield ,esc", 2, 121);
  drawCursor();
  pg.endDraw();
  image(pg, 0, 0, width, height);
}

void drawCursor() {
  pg.fill(white);
  pg.stroke(yellow);
  pg.strokeWeight(1);
  int mX = round(mouseXscl);
  int mY = round(mouseYscl);
  pg.pushMatrix();
  pg.translate(mX, mY);
  pg.beginShape();
  pg.vertex(0, 0);
  pg.vertex(2, 6);
  pg.vertex(5, 4);
  pg.endShape(CLOSE);
  pg.popMatrix();
}

void draw() {
  mouseXscl = mouseX/scl; // scale mouse to 128x128
  mouseYscl = mouseY/scl;
  if (gameOver) mainMenu(); 
  else game.gameFrame();
  mouseHit = false;
}