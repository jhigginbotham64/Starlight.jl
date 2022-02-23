#include <vulkan/vulkan.hpp>
#include <jlcxx/jlcxx.hpp>

#include <SDL2/SDL.h>
#include <SDL2/SDL_mixer.h>
#include <SDL2/SDL_image.h>
#include <SDL2/SDL_ttf.h>

#include <iostream>
#include <algorithm>
#include <cmath>

SDL_Window *win = NULL;
SDL_Renderer *rnd = NULL;

void getSDLError()
{
  return std::string(SDL_GetError());
}

void fill(UInt8 r, UInt8 g, UInt8 b, UInt8 a)
{
  SDL_SetRenderDrawColor(rnd, r, g, b, a);
  SDL_RenderClear(rnd);
}

void init(const char * ttl = "Hello SDL", int wdth = 800, int hght = 400)
{
  SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 4);
  SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 4);
  
  if (SDL_Init(SDL_INIT_EVERYTHING) != 0)
  {
    std::cerr << "Unable to initialize SDL: " << getSDLError() << std::endl;
  }

  TTF_Init()

  int mix_init_flags = MIX_INIT_FLAC | MIX_INIT_MP3 | MIX_INIT_OGG;
  if (Mix_Init(mix_init_flags) & mix_init_flags != mix_init_flags)
  {
    std::cerr << "Failed to initialise audio mixer properly. All sounds may not play correctly." << std::endl << getSDLError() << std::endl; 
  }

  if (Mix_OpenAudio(22050, MIX_DEFAULT_FORMAT, 2, 1024) != 0)
  {
    std::cerr << "No audio device available, sounds and music will not play." << std::endl << getSDLError() << std::endl;
    Mix_CloseAudio();
  }

  win = SDL_CreateWindow(ttl, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, wdth, hght, SDL_WINDOW_ALLOW_HIGHDPI|SDL_WINDOW_VULKAN|SDL_WINDOW_SHOWN);
  SDL_SetWindowMinimumSize(win, wdth, hght);
  rnd = SDL_CreateRenderer(win, -1, SDL_RENDERER_ACCELERATED|SDL_RENDERER_PRESENTVSYNC);
  SDL_SetRenderDrawBlendMode(rnd, SDL_BLENDMODE_BLEND);
}

void quit()
{
  SDL_DestroyRenderer(rnd);
  SDL_DestroyWindow(win);

  Mix_HaltMusic();
  Mix_HaltChannel(-1);
  Mix_CloseAudio();

  TTF_Quit();
  Mix_Quit();
  SDL_Quit();
}

void present()
{
  SDL_RenderPresent(rnd);
}

void play_sound(const char* sound_file, int loops=0, int ticks=-1)
{
  Mix_Chunk *sample = Mix_LoadWAV_RW(SDL_RWFromFile(sound_file, "rb"), 1);
  if (sample == NULL)
  {
    std::cerr << "Could not load sound file: " << std::string(sound_file) << std::endl << getSDLError() << std::endl;]
    return;
  }
  if (Mix_PlayChannelTimed(-1, sample, loops, ticks) == -1)
  {
    std::cerr << "Unable to play sound " << sound_file << std::endl << getSDLError() << std::endl;
  }
}

void drawLine(int r, int g, int b, int a, int x1, int y1, int x2, int y2)
{
  SDL_SetRenderDrawColor(rnd, r, g, b, a);
  SDL_RenderDrawLine(rnd, x1, y1, x2, y2);
}

void drawRect(int r, int g, int b, int a, bool fill, int x, int y, int w, int h)
{
  SDL_SetRenderDrawColor(rnd, r, g, b, a);
  SDL_Rect r = {x, y, w, h};
  if (!fill)
  {
    SDL_RenderDrawRect(rnd, &r);
  }
  else
  {
    SDL_RenderFillRect(rnd, &r);
  }
}

void drawCircle(int r, int g, int b, int a, bool fill, int x, int y, int rad)
{
  int left = x - rad;
  int top = y - rad;

  SDL_SetRenderDrawColor(rnd, r, g, b, a);

  for (int i = left; i <= x; ++i)
  {
    for (int j = top; j <= y; ++j)
    {
      int rel_x = x - i;
      int rel_y = y - j;
      double dist = sqrt(pow(rel_x, 2) + pow(rel_y, 2));
      if (dist <= rad + 0.5 && dist >= rad - 0.5)
      {
        // quads
        int q1x = i;
        int q1y = j;
        int q2x = x + rel_x;
        int q2y = j;
        int q3x = i;
        int q3y = y + rel_y;
        int q4x = q2x;
        int q4y = q3y;

        SDL_RenderDrawPoint(rnd, q1x, q1y);
        SDL_RenderDrawPoint(rnd, q2x, q2y);
        SDL_RenderDrawPoint(rnd, q3x, q3y);
        SDL_RenderDrawPoint(rnd, q4x, q4y);

        if (fill)
        {
          SDL_RenderDrawLine(rnd, q1x, q1y, q2x, q2y);
          SDL_RenderDrawLine(rnd, q2x, q2y, q4x, q4y);
          SDL_RenderDrawLine(rnd, q4x, q4y, q3x, q3y);
          SDL_RenderDrawLine(rnd, q3x, q3y, q1x, q1y);
        }
      }
    }
  }
}

void drawTriangle(int r, int g, int b, int a, bool fill, int p1x, int p1y, int p2x, int p2y, int p3x, int p3y)
{
  SDL_SetRenderDrawColor(rnd, r, g, b, a);

  SDL_Point pts[4] = {
    {p1x,p1y},
    {p2x,p2y},
    {p3x,p3y},
    {p1x,p1y}
  };

  SDL_RenderDrawLines(rnd, pts, 4);

  int ymax = std::max(p1y, p2y, p3y);
  int ymin = std::min(p1y, p2y, p3y);
  if (fill && ymin != ymax)
  {
    int q1x = (p1y != ymax != p2y) * p3x +
        (p2y != ymax != p3y) * p1x +
        (p3y != ymax != p1y) * p2x +
        (p1y == p2y == ymax) * p2x +
        (p2y == p3y == ymax) * p3x +
        (p3y == p1y == ymax) * p1x;
    int q3x = (p1y != ymin != p2y) * p3x +
        (p2y != ymin != p3y) * p1x +
        (p3y != ymin != p1y) * p2x +
        (p1y == p2y == ymin) * p2x +
        (p2y == p3y == ymin) * p3x +
        (p3y == p1y == ymin) * p1x;
    int q1y = (p1y != ymax != p2y) * p3y +
        (p2y != ymax != p3y) * p1y +
        (p3y != ymax != p1y) * p2y +
        (p1y == p2y == ymax) * p2y +
        (p2y == p3y == ymax) * p3y +
        (p3y == p1y == ymax) * p1y;
    int q3y = (p1y != ymin != p2y) * p3y +
        (p2y != ymin != p3y) * p1y +
        (p3y != ymin != p1y) * p2y +
        (p1y == p2y == ymin) * p2y +
        (p2y == p3y == ymin) * p3y +
        (p3y == p1y == ymin) * p1y;
    int q2x = ((q1x == p1x && q3x == p3x && q1y == p1y && q3y == p3y) || (q1x == p3x && q3x == p1x && q1y == p3y && q3y == p1y)) * p2x +
        ((q1x == p1x && q3x == p2x && q1y == p1y && q3y == p2y) || (q1x == p2x && q3x == p1x && q1y == p2y && q3y == p1y)) * p3x +
        ((q1x == p2x && q3x == p3x && q1y == p2y && q3y == p3y) || (q1x == p3x && q3x == p2x && q1y == p3y && q3y == p2y)) * p1x;
    int q2y = ((q1x == p1x && q3x == p3x && q1y == p1y && q3y == p3y) || (q1x == p3x && p2x == p1x && q1y == p3y && q3y == p1y)) * p2y +
        ((q1x == p1x && q3x == p2x && q1y == p1y && q3y == p2y) || (q1x == p2x && q3x == p1x && q1y == p2y && q3y == p1y)) * p3y +
        ((q1x == p2x && q3x == p3x && q1y == p2y && q3y == p3y) || (q1x == p3x && q3x == p2x && q1y == p3y && q3y == p2y)) * p1y;
    
    int n = q1y - q2y;
    double x0 = q1x + (q2y - q1y) / (q3y - q1y) * (q3x - q1x);
    for (int i = 0; i <= n-1; ++i)
    {
      long long int r1x = llround(q2x + i / n * (q1x - q2x));
      long long int r1y = q2y + i;
      long long int r2x = llround(x0 + i / n * (q3x - x0));
      long long int r2y = q2y + i;
      SDL_RenderDrawLine(rnd, r1x, r1y, r2x, r2y);
    }
    n = q2y - q3y;
    for (int i = 1; i <= n-1; ++i)
    {
      long long int r1x = llround(q2x + i / n * (q1x - q2x));
      long long int r1y = q2y - i;
      long long int r2x = llround(x0 + i / n * (q3x - x0));
      long long int r2y = q2y - i;
      SDL_RenderDrawLine(rnd, r1x, r1y, r2x, r2y);
    }
  }
}

void drawSprite(const char * img, int a, int rx, int ry, int rw, int rh, int cx, int cy, int ci, int cj, int px, int py, int sx, int sy, int rotz)
{
  SDL_Surface * srf = IMG_Load(img);
  if (srf == NULL)
  {
    std::cerr << "Error loading " << std::string(img) << std::endl << getSDLError() << std::endl;
  }
  int w = srf->x;
  int h = srf->h;
  SDL_Texture * txt = SDL_CreateTextureFromSurface(rnd, srf);

  if (a < 255)
  {
    SDL_SetTextureBlendMode(txt, SDL_BLENDMODE_BLEND);
    SDL_SetTextureAlphaMod(txt, a);
  }

  int srctlx = 0;
  int srctly = 0;
  int srcw = w;
  int srch = h;

  if (rx != 0 || ry != 0 || rw != 0 || rh != 0)
  {
    srctlx = rx;
    srctly = ry;
    srcw = rw;
    srch = rh;
  }
  else if (cx != 0 || cy != 0)
  {
    srctlx = cj * cx;
    srctly = ci * cy;
    srcw = cx;
    srch = cy;
  }

  int dstw = w;
  int dsth = h;

  if (rx != 0 || ry != 0 || rw != 0 || rh != 0)
  {
    dstw = rw;
    dsth = rh;
  }
  else if (cx != 0 || cy != 0)
  {
    dstw = cx;
    dsth = cy;
  }

  dstw = floor(dstw * sx);
  dsth = floor(dsth * sy);

  SDL_Rect src = {srctlx, srctly, srcw, srch};
  SDL_Rect dst = {px - llround(dstw / 2), py - llround(dsth / 2), dstw, dsth};
  
  SDL_RenderCopyEx(
    rnd,
    txt,
    &src,
    &dst,
    rotz,
    NULL,
    SDL_FLIP_NONE
  );
  
  SDL_DestroyTexture(txt);
  SDL_FreeSurface(srf);
}

void drawText(const char * fname, int fsize, const char * txt, int r, int g, int b, int a, int px, int py, int sx, int sy, int rotz)
{
  TTF_Font * font = TTF_OpenFont(fname, fsize);
  SDL_Color c = {r, g, b, a};
  SDL_Surface * srf = TTF_RenderText_Blended(font, txt, c);
  SDL_Texture * txt = SDL_CreateTextureFromSurface(rnd, srf);

  if (a < 255)
  {
    SDL_SetTextureBlendMode(txt, SDL_BLENDMODE_BLEND);
    SDL_SetTextureAlphaMod(txt, a);
  }

  int w = llround(srf->w * sx);
  int h = llround(srf->h * sy);
  SDL_Rect dst = {px - llround(w / 2), py - llround(h / 2), w, h};
  
  SDL_RenderCopyEx(
    rnd,
    txt,
    NULL,
    &dst,
    rotz,
    NULL,
    SDL_FLIP_NONE
  );

  SDL_DestroyTexture(txt);
  SDL_FreeSurface(srf);
  TTF_CloseFont(font);
}

JLCXX_MODULE define_julia_module(jlcxx::Module& mod)
{
  mod.method("TS_GetSDLError", &getSDLError);
  mod.method("TS_Fill", &fill);
  mod.method("TS_Init", &init);
  mod.method("TS_Quit", &quit);
  mod.method("TS_Present", &present);
  mod.method("TS_PlaySound", &play_sound);
  mod.method("TS_DrawLine", &drawLine);
  mod.method("TS_DrawRect", &drawRect);
  mod.method("TS_DrawCircle", &drawCircle);
  mod.method("TS_DrawTriangle", &drawTriangle);
  mod.method("TS_DrawSprite", &drawSprite);
  mod.method("TS_DrawText", &drawText);
}