/*
  A CPU implementation of flow field path finding
  creates an image with grey scale flow field from every point on screen
  to the target. 
*/

color background = color(1, 1, 1, 255);
color wallColor = color(255, 0, 0, 255);

PImage cpuPathTrace() {
  final int[] cardinals  = { 1, -1, small, -small }; 
  final int totPxls = small*small - 1;
  
  PVector target = playerLoc.copy();
  if (game.gameFrameCount%3 ==0) target =new PVector(10,64+random(24)-48);
  //target.lerp(new PVector(64,10),(sin(frameCount/20.0)+1)/2.0);
  final int mousePx = round(target.x) + round(target.y)*small;//constrain(mouseX +mouseY*small, 0, totPxls);
  
  IntList curPxs = new IntList();
  IntList nextPxs = new IntList();
  int pathStep = 255*3;
  PGraphics pgPathMap = createGraphics(small,small,P2D);
  curPxs.append(mousePx);
  pgPathMap.beginDraw();
  pgPathMap.background(background);
  pgPathMap.tint(wallColor);
  pgPathMap.image(asteroids, 0, 0);
  
  pgPathMap.loadPixels();
  
  for (Pather p : game.pathers){
    if (p.loc.y<small-1)
    pgPathMap.pixels[round(p.loc.x) + round(p.loc.y)*small] = wallColor;
  }
 /*  preload targets into curPxs, which serve as starting points for the reverse path search
     while there are still neighbors to search,
        set currentPixel brightness to the current calculation step, the walking distance from target
        add it's available neighbors to be searched in the next step                         */
  while ((curPxs.size()>0)) {
    pathStep--;
    for (int ci : curPxs) {
      ci = constrain(ci, small, totPxls-small);
      if (pgPathMap.pixels[ci]==background) {
        int i3 = int( pathStep/3);
        //brightness encoding, 255*3 levels
        pgPathMap.pixels[ci] =  color(i3 ,   (i3 + ((pathStep%3>1)?1:0))  ,   (i3 + ((pathStep%3>0)?1:0)) ,255);
        // Add neighbors that have not been processed
        int j = 4;
        while (j-- > 0){
          int k = ci+cardinals[j];
          if (pgPathMap.pixels[k] == background) nextPxs.append(k); 
        }
      }
    }
    curPxs=nextPxs.copy();
    nextPxs.clear();
  }
  pgPathMap.endDraw();
  pgPathMap.updatePixels();
  return pgPathMap; // can be drawn for debugging
}