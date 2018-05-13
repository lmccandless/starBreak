PFont font;

PImage[][] healthIcon;
PImage heart;
PImage pathMap = null;

AudioSample asCrash, asFire, asHeal, asMenu, asHit;
AudioPlayer groove;
AudioOutput out;
Noise       theNoise;
LowPassSP lpf;
BitCrush bitCrush;
int audioBuffer= 1024;

void loadAudio() {
  groove = minim.loadFile("data/audio/The Void.mp3", audioBuffer);
  asCrash = minim.loadSample( "data/audio/crash.wav", audioBuffer);
  asFire = minim.loadSample( "data/audio/fire.wav", audioBuffer);
  asHeal = minim.loadSample( "data/audio/heal.wav", audioBuffer);
  asMenu = minim.loadSample( "data/audio/menu.wav", audioBuffer);
  asHit =  minim.loadSample( "data/audio/hit.wav", audioBuffer);


  asMenu.setGain(masterVolume+(-8));
  asCrash.setGain(masterVolume+(-6));
  out = minim.getLineOut(Minim.STEREO, audioBuffer);
  lpf = new LowPassSP(100, out.sampleRate());
  theNoise = new Noise( 0.5f );
  bitCrush = new BitCrush(5, out.sampleRate());
  theNoise.patch(lpf).patch(bitCrush).patch(out);
}

void  updateVolumes(){
  groove.setGain(masterVolume);
  asCrash.setGain(masterVolume);
  asFire.setGain(masterVolume);
  asHeal.setGain(masterVolume);
  asMenu.setGain(masterVolume);
  asHit.setGain(masterVolume);
}

void loadGfx() {
  font = loadFont("Ebrima-9.vlw");//, 11);
  heart = loadImage("heart.png");
  PImage healthSheet = loadImage("health2.png");
  heart = loadImage("heart.png");
  healthIcon = new PImage[4][8];
  for (int i = 0; i < 4; i++) {
    for (int q = 0; q <8; q++) {
      healthIcon[i][q] = healthSheet.get(q*10, i*10, 10, 10);
    }
  }
}