#define VULKAN_HPP_DISPATCH_LOADER_DYNAMIC 1
#define VULKAN_HPP_STORAGE_SHARED 1
#define VULKAN_HPP_STORAGE_SHARED_EXPORT 1

#include <vulkan/vulkan.hpp>
#include <jlcxx/jlcxx.hpp>

#include <SDL2/SDL.h>
#include <SDL2/SDL_mixer.h>
#include <SDL2/SDL_image.h>
#include <SDL2/SDL_ttf.h>
#include <SDL2/SDL_vulkan.h>

#include <iostream>
#include <algorithm>
#include <string>
#include <vector>
#include <set>
#include <cmath>

VULKAN_HPP_DEFAULT_DISPATCH_LOADER_DYNAMIC_STORAGE

const char *window_name = NULL;
SDL_Window *win = NULL;
vk::Instance inst;
VkSurfaceKHR srf;
vk::PhysicalDevice pdev;
vk::Device dev;
int graphicsQueueFamilyIndex = -1;
int presentQueueFamilyIndex = -1;
vk::Queue gq;
vk::Queue pq;
vk::SwapchainKHR swapchain;
vk::SurfaceCapabilitiesKHR surfaceCapabilities;
vk::SurfaceFormatKHR surfaceFormat;
vk::Extent2D swapchainSize;
std::vector<vk::Image> swapchainImages;
uint32_t swapchainImageCount;
std::vector<vk::ImageView> swapchainImageViews;
vk::Format depthFormat;
vk::Image depthImage;
vk::DeviceMemory depthImageMemory;
vk::ImageView depthImageView;
vk::RenderPass rp;
std::vector<vk::Framebuffer> swapchainFramebuffers;
vk::CommandPool cp;
std::vector<vk::CommandBuffer> cmdbufs;
vk::Semaphore imageAvailableSemaphore;
vk::Semaphore renderingFinishedSemaphore;
std::vector<vk::Fence> fences;

void TS_VkCreateInstance()
{
  VULKAN_HPP_DEFAULT_DISPATCHER.init((PFN_vkGetInstanceProcAddr)SDL_Vulkan_GetVkGetInstanceProcAddr());

  unsigned int extensionCount = 0;
  SDL_Vulkan_GetInstanceExtensions(win, &extensionCount, nullptr);
  std::vector<const char *> extensionNames(extensionCount);
  SDL_Vulkan_GetInstanceExtensions(win, &extensionCount, extensionNames.data());
  
  vk::ApplicationInfo appInfo {
    window_name, 
    VK_MAKE_VERSION(0, 1, 0), 
    "Telescope", 
    VK_MAKE_VERSION(0, 1, 0),
    VK_API_VERSION_1_0
  };

  vk::InstanceCreateInfo ici {
    vk::InstanceCreateFlags(),
    &appInfo,
    0, NULL, // no validation or other layers yet
    extensionNames.size(), extensionNames.data()
  };

  inst = vk::createInstance(ici);

  VULKAN_HPP_DEFAULT_DISPATCHER.init(inst);
}

void TS_VkCreateSurface()
{
  SDL_Vulkan_CreateSurface(win, inst, &srf);
}

void TS_VkSelectPhysicalDevice()
{
  pdev = inst.enumeratePhysicalDevices()[0]; // TODO improve selection
}

void TS_VkSelectQueueFamily()
{
  int graphicIndex = -1;
  int presentIndex = -1;
  int i = 0;
  for (const auto& qf : pdev.getQueueFamilyProperties())
  {
    if (qf.queueCount > 0 && qf.queueFlags & vk::QueueFlagBits::eGraphics) graphicIndex = i;
    vk::Bool32 presentSupport = false;
    vkGetPhysicalDeviceSurfaceSupportKHR(pdev, i, srf, &presentSupport);
    if (qf.queueCount > 0 && presentSupport) presentIndex = i;
    if (graphicIndex != -1 && presentIndex != -1) break;
    ++i;
  }
  graphicsQueueFamilyIndex = graphicIndex;
  presentQueueFamilyIndex = presentIndex;
}

void TS_VkCreateDevice()
{
  const std::vector<const char*> deviceExtensions = {VK_KHR_SWAPCHAIN_EXTENSION_NAME};
  const float queue_priority[] = { 1.0f };
  float queuePriority = queue_priority[0];
  
  std::vector<vk::DeviceQueueCreateInfo> queueCreateInfos;
  
  vk::DeviceQueueCreateInfo gr {
    vk::DeviceQueueCreateFlags(),
    graphicsQueueFamilyIndex, 
    1, 
    &queuePriority
  };

  vk::DeviceQueueCreateInfo pr {
    vk::DeviceQueueCreateFlags(),
    presentQueueFamilyIndex, 
    1, 
    &queuePriority
  };

  queueCreateInfos.push_back(gr);
  queueCreateInfos.push_back(pr);

  vk::PhysicalDeviceFeatures deviceFeatures = {};
  deviceFeatures.samplerAnisotropy = VK_TRUE;
  vk::DeviceCreateInfo deviceCreateInfo {
    vk::DeviceCreateFlags(),
    queueCreateInfos.size(), queueCreateInfos.data(),
    0, nullptr,
    deviceExtensions.size(), deviceExtensions.data(),
    &deviceFeatures
  };

  dev = pdev.createDevice(deviceCreateInfo);
  VULKAN_HPP_DEFAULT_DISPATCHER.init(dev);
  gq = dev.getQueue(graphicsQueueFamilyIndex, 0);
  pq = dev.getQueue(presentQueueFamilyIndex, 0);
}

#define CLAMP(x, lo, hi)    ((x) < (lo) ? (lo) : (x) > (hi) ? (hi) : (x))
void TS_VkCreateSwapchain()
{
  surfaceCapabilities = pdev.getSurfaceCapabilitiesKHR(srf);
  std::vector<vk::SurfaceFormatKHR> surfaceFormats = pdev.getSurfaceFormatsKHR(srf);
  surfaceFormat = surfaceFormats[0];
  int width,height = 0;
  SDL_Vulkan_GetDrawableSize(win, &width, &height);
  width = CLAMP(width, surfaceCapabilities.minImageExtent.width, surfaceCapabilities.maxImageExtent.width);
  height = CLAMP(height, surfaceCapabilities.minImageExtent.height, surfaceCapabilities.maxImageExtent.height);
  swapchainSize.width = width;
  swapchainSize.height = height;
  uint32_t imageCount = surfaceCapabilities.minImageCount + 1;
  if (surfaceCapabilities.maxImageCount > 0 && imageCount > surfaceCapabilities.maxImageCount)
  {
    imageCount = surfaceCapabilities.maxImageCount;
  }
  
  vk::SwapchainCreateInfoKHR createInfo;
  createInfo.surface = srf;
  createInfo.minImageCount = surfaceCapabilities.minImageCount;
  createInfo.imageFormat = surfaceFormat.format;
  createInfo.imageColorSpace = surfaceFormat.colorSpace;
  createInfo.imageExtent = swapchainSize;
  createInfo.imageArrayLayers = 1;
  createInfo.imageUsage = vk::ImageUsageFlagBits::eColorAttachment;
  uint32_t queueFamilyIndices[] = {graphicsQueueFamilyIndex, presentQueueFamilyIndex};
  if (graphicsQueueFamilyIndex != presentQueueFamilyIndex)
  {
    createInfo.imageSharingMode = vk::SharingMode::eConcurrent;
    createInfo.queueFamilyIndexCount = 2;
    createInfo.pQueueFamilyIndices = queueFamilyIndices;
  }
  else
  {
    createInfo.imageSharingMode = vk::SharingMode::eExclusive;
  }
  createInfo.preTransform = surfaceCapabilities.currentTransform;
  createInfo.compositeAlpha = vk::CompositeAlphaFlagBitsKHR::eOpaque;
  createInfo.presentMode = vk::PresentModeKHR::eFifo;
  createInfo.clipped = VK_TRUE;
  swapchain = dev.createSwapchainKHR(createInfo);
  swapchainImages = dev.getSwapchainImagesKHR(swapchain);
}

void TS_VkCreateImageViews()
{
  for (int i = 0; i < swapchainImages.size(); ++i)
  {
    vk::ImageViewCreateInfo viewInfo;
    viewInfo.viewType = vk::ImageViewType::e2D;
    viewInfo.image = swapchainImages[i];
    viewInfo.format = surfaceFormat.format;
    viewInfo.subresourceRange.aspectMask = vk::ImageAspectFlagBits::eColor;
    viewInfo.subresourceRange.baseMipLevel = 0;
    viewInfo.subresourceRange.levelCount = 1;
    viewInfo.subresourceRange.baseArrayLayer = 0;
    viewInfo.subresourceRange.layerCount = 1;

    swapchainImageViews.push_back(dev.createImageView(viewInfo));
  }
}

void TS_VkSetupDepthStencil()
{

}

void TS_VkCreateRenderPass()
{

}

void TS_VkCreateFramebuffers()
{

}

void TS_VkCreateCommandPool()
{

}

void TS_VkCreateCommandBuffers()
{

}

void TS_VkCreateSemaphores()
{
  imageAvailableSemaphore = dev.createSemaphore({});
  renderingFinishedSemaphore = dev.createSemaphore({});
}

void TS_VkCreateFences()
{

}

void TS_VkInit()
{
  TS_VkCreateInstance();
  TS_VkCreateSurface();
  TS_VkSelectPhysicalDevice();
  TS_VkSelectQueueFamily();
  TS_VkCreateDevice();
  TS_VkCreateSwapchain();
  TS_VkCreateImageViews();
  TS_VkSetupDepthStencil();
  TS_VkCreateRenderPass();
  TS_VkCreateFramebuffers();
  TS_VkCreateCommandPool();
  TS_VkCreateCommandBuffers();
  TS_VkCreateSemaphores();
  TS_VkCreateFences();
}

void TS_VkDestroyFences()
{

}

void TS_VkDestroySemaphores()
{
  dev.destroySemaphore(imageAvailableSemaphore);
  dev.destroySemaphore(renderingFinishedSemaphore);
}

void TS_VkFreeCommandBuffers()
{

}

void TS_VkDestroyCommandPool()
{

}

void TS_VkFreeFramebuffers()
{

}

void TS_VkDestroyRenderPass()
{

}

void TS_VkTeardownDepthStencil()
{

}

void TS_VkDestroyImageViews()
{
  for (vk::ImageView iv : swapchainImageViews)
  {
    dev.destroyImageView(iv);
  }
  swapchainImageViews.clear();
}

void TS_VkDestroySwapchain()
{
  dev.destroySwapchainKHR(swapchain);
}

void TS_VkDestroyDevice()
{
  graphicsQueueFamilyIndex = -1;
  presentQueueFamilyIndex = -1;
  dev.destroy();
}

void TS_VkFreeSurface()
{
  vkDestroySurfaceKHR(inst, srf, nullptr);
}

void TS_VkDestroyInstance()
{
  inst.destroy();
}

void TS_VkQuit()
{
  TS_VkDestroyFences();
  TS_VkDestroySemaphores();
  TS_VkFreeCommandBuffers();
  TS_VkDestroyCommandPool();
  TS_VkFreeFramebuffers();
  TS_VkDestroyRenderPass();
  TS_VkTeardownDepthStencil();
  TS_VkDestroyImageViews();
  TS_VkDestroySwapchain();
  TS_VkDestroyDevice();
  TS_VkFreeSurface();
  TS_VkDestroyInstance();
}

std::string TS_GetSDLError()
{
  return std::string(SDL_GetError());
}

void TS_Fill(Uint8 r, Uint8 g, Uint8 b, Uint8 a)
{
  
}

void TS_Init(const char * ttl, int wdth, int hght)
{ 
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

  window_name = ttl;
  win = SDL_CreateWindow(ttl, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, wdth, hght, SDL_WINDOW_VULKAN|SDL_WINDOW_ALLOW_HIGHDPI|SDL_WINDOW_SHOWN);
  if (win == NULL)
  {
    std::cerr << "Failed to create window: " << TS_GetSDLError() << std::endl;
  }
  else
  {
    SDL_SetWindowMinimumSize(win, wdth, hght);
  }
  
  TS_VkInit();
}

void TS_Quit()
{
  TS_VkQuit();
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
  
}

void TS_DrawLine(Uint8 r, Uint8 g, Uint8 b, Uint8 a, int x1, int y1, int x2, int y2)
{
  
}

void TS_DrawRect(Uint8 r, Uint8 g, Uint8 b, Uint8 a, bool fill, int x, int y, int w, int h)
{
  
}

void TS_DrawSprite(const char * img, Uint8 a, int rx, int ry, int rw, int rh, int cx, int cy, int ci, int cj, int px, int py, int sx, int sy, int rotz)
{
  
}

void TS_DrawText(const char * fname, int fsize, const char * text, Uint8 r, Uint8 g, Uint8 b, Uint8 a, int px, int py, int sx, int sy, int rotz)
{
  
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