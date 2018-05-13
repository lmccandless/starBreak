/**
 * 
 * PixelFlow | Copyright (C) 2016 Thomas Diewald - http://thomasdiewald.com
 * 
 * A Processing/Java library for high performance GPU-Computing (GLSL).
 * MIT License: https://opensource.org/licenses/MIT
 * 
 */
 
import com.jogamp.opengl.GL2ES2;
import com.jogamp.newt.opengl.GLWindow;
import com.thomasdiewald.pixelflow.java.DwPixelFlow;
import com.thomasdiewald.pixelflow.java.dwgl.DwGLSLProgram;
import com.thomasdiewald.pixelflow.java.dwgl.DwGLTexture;
import com.thomasdiewald.pixelflow.java.fluid.DwFluid2D;

import processing.core.PConstants;
import processing.opengl.PGraphics2D;

int viewport_w = 128;
int viewport_h = 128;
int viewport_x = 0;
int viewport_y = 0;

int gui_w = 200;
int gui_x = 20;
int gui_y = 20;
int fluidgrid_scale = 3;
DwFluid2D fluid;
PGraphics2D pg_fluid;
PGraphics2D pg_obstacles;
MyParticleSystem particles;
GLWindow r;

int     BACKGROUND_COLOR           = 0;
boolean UPDATE_FLUID               = true;
boolean DISPLAY_FLUID_TEXTURES     = false;
boolean DISPLAY_FLUID_VECTORS      = false;
int     DISPLAY_fluid_texture_mode = 0;
boolean DISPLAY_PARTICLES          = true;

ArrayList<Bullet> bulletImpacts;

void setupFlow() {
  surface.setLocation(viewport_x, viewport_y);

  // main library context
  DwPixelFlow context = new DwPixelFlow(this);
  context.print();
  context.printGL();

  // fluid simulation
  fluid = new DwFluid2D(context, viewport_w, viewport_h, fluidgrid_scale);

  // set some simulation parameters
  fluid.param.dissipation_density     = 0.699f;
  fluid.param.dissipation_velocity    = 0.26f;
  fluid.param.dissipation_temperature = 0.20f;
  fluid.param.vorticity               = 0.99f;

  // interface for adding data to the fluid simulation
  MyFluidData cb_fluid_data = new MyFluidData();
  fluid.addCallback_FluiData(cb_fluid_data);

  // pgraphics for fluid
  pg_fluid = (PGraphics2D) createGraphics(viewport_w, viewport_h, P2D);
  // pg_fluid.smooth(2);
  pg_fluid.beginDraw();
  //pg_fluid.clear();
 pg_fluid.background(BACKGROUND_COLOR);
  pg_fluid.endDraw();

  // pgraphics for obstacles
  pg_obstacles = (PGraphics2D) createGraphics(viewport_w, viewport_h, P2D);
  // pg_obstacles.smooth(2);
  pg_obstacles.beginDraw();
  pg_obstacles.clear();
  float radius;
  radius = 200;
  pg_obstacles.stroke(64);
  pg_obstacles.strokeWeight(10);
  pg_obstacles.noFill();
  //pg_obstacles.rect(1*width/2f,  1*height/4f, radius, radius, 20);
  // border-obstacle
  pg_obstacles.strokeWeight(20);
  pg_obstacles.stroke(64);
  pg_obstacles.noFill();
  //  pg_obstacles.rect(0, 0, pg_obstacles.width, pg_obstacles.height);
  pg_obstacles.endDraw();

  fluid.addObstacles(pg_obstacles);

  // custom particle object
  particles = new MyParticleSystem(context, 60000 );
}
void updateFluid() {
  if (UPDATE_FLUID) {
    fluid.addObstacles(pg_obstacles);
    fluid.update();
    particles.update(fluid);
  }

  // clear render target
  pg_fluid.beginDraw();
  pg_fluid.background(BACKGROUND_COLOR);
  pg_fluid.endDraw();


  // render fluid stuff
  if (DISPLAY_FLUID_TEXTURES) {
    // render: density (0), temperature (1), pressure (2), velocity (3)
    fluid.renderFluidTextures(pg_fluid, DISPLAY_fluid_texture_mode);
  }

  if (DISPLAY_FLUID_VECTORS) {
    // render: velocity vector field
    fluid.renderFluidVectors(pg_fluid, 10);
  }

  if ( DISPLAY_PARTICLES) {
    // render: particles; 0 ... points, 1 ...sprite texture, 2 ... dynamic points
    particles.render(pg_fluid, BACKGROUND_COLOR);
  }
  // display
  //image(pg_obstacles, 0, 0,width,height);
}
private class MyFluidData implements DwFluid2D.FluidData {
  PVector velAvg = new PVector(0, 0);
  // update() is called during the fluid-simulation update step.
  @Override
    public void update(DwFluid2D fluid) {

    float px, py, radius, vscale;

    radius = 15;
    vscale = 10;
    px     = 64;
    py     = 50;

    radius = 40;

    radius = 1;
    vscale = 38;
    px     = playerLoc.x;
    py     = small- playerLoc.y;  

    velAvg =(vel.copy().mult(vscale));
    velAvg.x*=-1;
    // ROCKET EXHAUST
    int range = 40;
    velAvg.limit(range);

    fluid.addDensity (px, py, radius, 0.04f, 0.0f, 0.04f, 0.7f);
    fluid.addVelocity(px, py, radius*3, velAvg.x, velAvg.y);
    particles.spawn(fluid, px, py, radius*2, min(100, (int)velAvg.magSq()/14));
    
    
    // BULLET IMPACTS
    radius=1;
    vscale = 165;
    for (Bullet b : bulletImpacts) {
       

      px     = b.loc.x;
      py     = small- b.loc.y;  
      PVector heading = new PVector(1,0);
      for (int i = 0; i < 5; i++){
        int rx = (int)random(12)-6;
        int ry = (int)random(12)-6;

      heading.rotate(random(TWO_PI));
      fluid.addDensity (px+rx, py+ry, radius, 0.04f, 0.0f, 0.04f, 0.7f);
      fluid.addVelocity(px+rx, py+ry, radius, (heading.x)*vscale, heading.y*vscale);
      }
        
      particles.spawn(fluid, px, py, radius*2, 40);
    }
    bulletImpacts = new ArrayList<Bullet>();
  }
}


static public class MyParticleSystem {

  public DwGLSLProgram shader_particleSpawn;
  public DwGLSLProgram shader_particleUpdate;
  public DwGLSLProgram shader_particleRender;

  public DwGLTexture.TexturePingPong tex_particles = new DwGLTexture.TexturePingPong();

  DwPixelFlow context;

  public int particles_x;
  public int particles_y;

  public int MAX_PARTICLES;
  public int ALIVE_LO = 0;
  public int ALIVE_HI = 0;
  public int ALIVE_PARTICLES = 0;

  // a global factor, to comfortably reduce/increase the number of particles to spawn
  public float spwan_scale = 1.0f;
  public float point_size  = 2.0f;

  public Param param = new Param();

  static public class Param {
    public float dissipation = 0.99f;
    public float inertia     = 0.40f;
  }

  public MyParticleSystem() {
  }

  public MyParticleSystem(DwPixelFlow context, int MAX_PARTICLES) {
    context.papplet.registerMethod("dispose", this);
    this.resize(context, MAX_PARTICLES);
  }

  public void dispose() {
    release();
  }

  public void release() {
    tex_particles.release();
  }

  public void resize(DwPixelFlow context, int MAX_PARTICLES_WANTED) {
    particles_x = (int) Math.ceil(Math.sqrt(MAX_PARTICLES_WANTED));
    particles_y = particles_x;
    resize(context, particles_x, particles_y);
  }

  public void resize(DwPixelFlow context, int num_particels_x, int num_particels_y) {
    this.context = context;
    context.begin();
    release(); // just in case its not the first resize call
    MAX_PARTICLES = particles_x * particles_y;
    String dir = "data/";
    shader_particleSpawn  = context.createShader(dir + "particleSpawn.frag");
    shader_particleUpdate = context.createShader(dir + "particleUpdate.frag");
    shader_particleRender = context.createShader(dir + "particleRender.glsl", dir + "particleRender.glsl");
    shader_particleRender.vert.setDefine("SHADER_VERT", 1);
    shader_particleRender.frag.setDefine("SHADER_FRAG", 1);

    // allocate texture
    tex_particles.resize(context, GL2ES2.GL_RGBA32F, particles_x, particles_y, GL2ES2.GL_RGBA, GL2ES2.GL_FLOAT, GL2ES2.GL_NEAREST, 4, 4);
    context.end("ParticleSystem.resize");
    reset(); 
  }

  public void reset() {
    ALIVE_LO = ALIVE_HI = ALIVE_PARTICLES = 0;
    tex_particles.src.clear(0);
    tex_particles.dst.clear(0);
    spawn(null, -1, -1, 0, particles_x *particles_y);
    ALIVE_LO = ALIVE_HI = ALIVE_PARTICLES = 0;
  }

  public void spawn(DwFluid2D fluid, float px, float py, float radius, int count) {
    count = Math.round(count * spwan_scale);
    if (ALIVE_HI == MAX_PARTICLES)  ALIVE_HI = 0;
    int spawn_lo = ALIVE_HI; 
    int spawn_hi = Math.min(spawn_lo + count, MAX_PARTICLES); 
    float noise = (float)(Math.random() * Math.PI);
    context.begin();
    context.beginDraw(tex_particles.dst);
    shader_particleSpawn.begin();
    if (fluid != null) shader_particleSpawn.uniform2f("wh_viewport", fluid.viewp_w, fluid.viewp_h);
    shader_particleSpawn.uniform1i("spawn_lo", spawn_lo);
    shader_particleSpawn.uniform1i("spawn_hi", spawn_hi);
    shader_particleSpawn.uniform2f("spawn_origin", px, py);
    shader_particleSpawn.uniform1f("spawn_radius", radius);
    shader_particleSpawn.uniform1f("noise", noise);
    shader_particleSpawn.uniform2f("wh_particles", particles_x, particles_y);
    shader_particleSpawn.uniformTexture("tex_particles", tex_particles.src);
    shader_particleSpawn.drawFullScreenQuad();
    shader_particleSpawn.end();
    context.endDraw();
    context.end("ParticleSystem.spawn");
    tex_particles.swap();
    ALIVE_HI = spawn_hi;
    ALIVE_PARTICLES = Math.max(ALIVE_PARTICLES, ALIVE_HI - ALIVE_LO);
  }

  public void update(DwFluid2D fluid) {
    context.begin();
    context.beginDraw(tex_particles.dst);
    shader_particleUpdate.begin();
    shader_particleUpdate.uniform2f     ("wh_fluid", fluid.fluid_w, fluid.fluid_h);
    shader_particleUpdate.uniform2f     ("wh_particles", particles_x, particles_y);
    shader_particleUpdate.uniform1f     ("timestep", 0.1);
    shader_particleUpdate.uniform1f     ("rdx", 1.0f / 0.5);// fluid.param.gridscale);
    shader_particleUpdate.uniform1f     ("dissipation", param.dissipation);
    shader_particleUpdate.uniform1f     ("inertia", param.inertia);
    shader_particleUpdate.uniformTexture("tex_particles", tex_particles.src);
    shader_particleUpdate.uniformTexture("tex_velocity", fluid.tex_velocity.src);
    shader_particleUpdate.uniformTexture("tex_obstacles", fluid.tex_obstacleC.src);
    shader_particleUpdate.drawFullScreenQuad();
    shader_particleUpdate.end();
    context.endDraw();
    context.end("ParticleSystem.update");
    tex_particles.swap();
  }

  public void render(PGraphics2D dst, int background) {
    int num_points_to_render = ALIVE_PARTICLES;
    int w = dst.width;
    int h = dst.height;
    dst.beginDraw();
    context.begin();
    shader_particleRender.begin();
    shader_particleRender.uniform2f     ("wh_viewport", w, h);
    shader_particleRender.uniform2i     ("num_particles", particles_x, particles_y);
    shader_particleRender.uniform1f     ("point_size", point_size);
    shader_particleRender.uniformTexture("tex_particles", tex_particles.src);
    shader_particleRender.drawFullScreenPoints(num_points_to_render);
    shader_particleRender.end();
    context.end("ParticleSystem.render");
    dst.endDraw();
  }
}