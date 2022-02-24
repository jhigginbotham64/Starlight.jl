#include <vulkan/vulkan.hpp>
#include <jlcxx/jlcxx.hpp>

#include <SDL2/SDL.h>
#include <SDL2/SDL_mixer.h>
#include <SDL2/SDL_image.h>
#include <SDL2/SDL_ttf.h>

#include <iostream>
#include <algorithm>
#include <string>
#include <cmath>

SDL_Window *win = NULL;
SDL_Renderer *rnd = NULL;

std::string TS_GetSDLError()
{
  return std::string(SDL_GetError());
}

void TS_Fill(Uint8 r, Uint8 g, Uint8 b, Uint8 a)
{
  if(SDL_SetRenderDrawColor(rnd, r, g, b, a) != 0)
  {
    std::cerr << "Failed to set renderer draw color: " << TS_GetSDLError() << std::endl;
  }
  if(SDL_RenderClear(rnd) != 0)
  {
    std::cerr << "Failed to clear renderer: " << TS_GetSDLError() << std::endl;
  }
}

void TS_Init(const char * ttl = "Hello SDL", int wdth = 800, int hght = 400)
{
  SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 4);
  SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 4);
  
  if (SDL_Init(SDL_INIT_EVERYTHING) != 0)
  {
    std::cerr << "Unable to initialize SDL: " << TS_GetSDLError() << std::endl;
  }

  TTF_Init();

  int mix_init_flags = MIX_INIT_FLAC | MIX_INIT_MP3 | MIX_INIT_OGG;
  if (Mix_Init(mix_init_flags) & mix_init_flags != mix_init_flags)
  {
    std::cerr << "Failed to initialise audio mixer properly. All sounds may not play correctly." << std::endl << TS_GetSDLError() << std::endl; 
  }

  if (Mix_OpenAudio(22050, MIX_DEFAULT_FORMAT, 2, 1024) != 0)
  {
    std::cerr << "No audio device available, sounds and music will not play." << std::endl << TS_GetSDLError() << std::endl;
    Mix_CloseAudio();
  }

  win = SDL_CreateWindow(ttl, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, wdth, hght, SDL_WINDOW_ALLOW_HIGHDPI|SDL_WINDOW_SHOWN);
  if (win == NULL)
  {
    std::cerr << "Failed to create window: " << TS_GetSDLError() << std::endl;
  }
  else
  {
    SDL_SetWindowMinimumSize(win, wdth, hght);
  }
  
  rnd = SDL_CreateRenderer(win, -1, SDL_RENDERER_ACCELERATED|SDL_RENDERER_PRESENTVSYNC);
  if (rnd == NULL)
  {
    std::cerr << "Failed to create renderer: " << TS_GetSDLError() << std::endl;
  }
  else
  {
    SDL_SetRenderDrawBlendMode(rnd, SDL_BLENDMODE_BLEND);
  }
}

void TS_Quit()
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

void TS_Present()
{
  SDL_RenderPresent(rnd);
}

void TS_PlaySound(const char* sound_file, int loops=0, int ticks=-1)
{
  Mix_Chunk *sample = Mix_LoadWAV_RW(SDL_RWFromFile(sound_file, "rb"), 1);
  if (sample == NULL)
  {
    std::cerr << "Could not load sound file: " << std::string(sound_file) << std::endl << TS_GetSDLError() << std::endl;
    return;
  }
  if (Mix_PlayChannelTimed(-1, sample, loops, ticks) == -1)
  {
    std::cerr << "Unable to play sound " << sound_file << std::endl << TS_GetSDLError() << std::endl;
  }
}

void TS_DrawPoint(Uint8 r, Uint8 g, Uint8 b, Uint8 a, int x, int y)
{
  SDL_SetRenderDrawColor(rnd, r, g, b, a);
  SDL_RenderDrawPoint(rnd, x, y);
}

void TS_DrawLine(Uint8 r, Uint8 g, Uint8 b, Uint8 a, int x1, int y1, int x2, int y2)
{
  SDL_SetRenderDrawColor(rnd, r, g, b, a);
  SDL_RenderDrawLine(rnd, x1, y1, x2, y2);
}

void TS_DrawRect(Uint8 r, Uint8 g, Uint8 b, Uint8 a, bool fill, int x, int y, int w, int h)
{
  SDL_SetRenderDrawColor(rnd, r, g, b, a);
  // SDL expects top-left but Starlight passes center
  SDL_Rect rect = {x-lround(w/2), y-lround(h/2), w, h};
  if (!fill)
  {
    SDL_RenderDrawRect(rnd, &rect);
  }
  else
  {
    SDL_RenderFillRect(rnd, &rect);
  }
}

void TS_DrawSprite(const char * img, Uint8 a, int rx, int ry, int rw, int rh, int cx, int cy, int ci, int cj, int px, int py, int sx, int sy, int rotz)
{
  SDL_Surface * srf = IMG_Load(img);
  if (srf == NULL)
  {
    std::cerr << "Error loading " << std::string(img) << std::endl << TS_GetSDLError() << std::endl;
  }
  int w = srf->w;
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
  SDL_Rect dst = {px - lround(dstw / 2), py - lround(dsth / 2), dstw, dsth};
  
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

void TS_DrawText(const char * fname, int fsize, const char * text, Uint8 r, Uint8 g, Uint8 b, Uint8 a, int px, int py, int sx, int sy, int rotz)
{
  TTF_Font * font = TTF_OpenFont(fname, fsize);
  SDL_Color c = {r, g, b, a};
  SDL_Surface * srf = TTF_RenderText_Blended(font, text, c);
  SDL_Texture * txt = SDL_CreateTextureFromSurface(rnd, srf);

  if (a < 255)
  {
    SDL_SetTextureBlendMode(txt, SDL_BLENDMODE_BLEND);
    SDL_SetTextureAlphaMod(txt, a);
  }

  int w = lround(srf->w * sx);
  int h = lround(srf->h * sy);
  SDL_Rect dst = {px - lround(w / 2), py - lround(h / 2), w, h};
  
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
  mod.method("TS_GetSDLError", &TS_GetSDLError);
  mod.method("TS_Fill", &TS_Fill);
  mod.method("TS_Init", &TS_Init);
  mod.method("TS_Quit", &TS_Quit);
  mod.method("TS_Present", &TS_Present);
  mod.method("TS_PlaySound", &TS_PlaySound);
  mod.method("TS_DrawPoint", &TS_DrawPoint);
  mod.method("TS_DrawLine", &TS_DrawLine);
  mod.method("TS_DrawRect", &TS_DrawRect);
  mod.method("TS_DrawSprite", &TS_DrawSprite);
  mod.method("TS_DrawText", &TS_DrawText);
}