boolean [] keys = new boolean[256];
boolean [] lastKeys = new boolean[256];

void setCursorState() {
  r = (GLWindow)surface.getNative();
  if (mouseLock) r.confinePointer(true);   
  else r.confinePointer(false);
}

boolean keyHit(int c) {
  return (keys[c] && !lastKeys[c]);
}

boolean shift;
boolean escape;
boolean mouseHit = false;

char keyHit= ' ';
void setKey(boolean state) {
  int rawKey = key;
 // println(rawKey);
  if (key == 27) {
    escape = state;
     key = 0;
     if (state)asMenu.trigger();
  }
  if (rawKey==65535) shift = state;
  if (rawKey < 256) {
    if ((rawKey>64)&&(rawKey<91)) rawKey+=32;
    if ((state) && (!lastKeys[rawKey])) {
      keyHit = (char) (rawKey);
    }
    keys[rawKey] = state;
  }
}

void keyPressed() { 
  setKey(true);
}

void keyReleased() { 
  setKey(false);
}

void mousePressed(){
  mouseHit = true;
}

void mouseReleased(){
}

void changeScreenSize() {
  if (keyHit('1')) {
    if (width==small) surface.setSize((int)large, (int)large);
    else surface.setSize((int)small, (int)small);
  }
  scl = width/small;
}