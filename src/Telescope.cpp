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
uint32_t graphicsQueueFamilyIndex = -1;
uint32_t presentQueueFamilyIndex = -1;
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
uint32_t frameIndex;
vk::CommandBuffer cmdbuf;
vk::Image img;

void TS_VkAcquireNextImage()
{
  frameIndex = dev.acquireNextImageKHR(swapchain, UINT64_MAX, imageAvailableSemaphore).value;
  dev.waitForFences(1, &fences[frameIndex], VK_FALSE, UINT64_MAX);
  dev.resetFences(1, &fences[frameIndex]);
  cmdbuf = cmdbufs[frameIndex];
  img = swapchainImages[frameIndex];
}

void TS_VkResetCommandBuffer()
{
  cmdbuf.reset();
}

void TS_VkBeginCommandBuffer()
{
  cmdbuf.begin({vk::CommandBufferUsageFlagBits::eSimultaneousUse});
}

void TS_VkBeginRenderPass(uint32_t r, uint32_t g, uint32_t b, uint32_t a)
{
  vk::RenderPassBeginInfo rpi {
    rp, swapchainFramebuffers[frameIndex]
  };
  rpi.renderArea.offset = vk::Offset2D();
  rpi.renderArea.extent = swapchainSize;

  std::vector<vk::ClearValue> clearValues(2);
  clearValues[0] = vk::ClearColorValue(std::array<uint32_t, 4>({r, g, b, a}));
  clearValues[1] = vk::ClearDepthStencilValue(VkClearDepthStencilValue({1.0f, 0}));

  rpi.clearValueCount = static_cast<uint32_t>(clearValues.size());
  rpi.pClearValues = clearValues.data();

  cmdbuf.beginRenderPass(rpi, vk::SubpassContents::eInline);
}

void TS_VkEndRenderPass()
{
  cmdbuf.endRenderPass();
}

void TS_VkEndCommandBuffer()
{
  cmdbuf.end();
}

void TS_VkQueueSubmit()
{
  vk::PipelineStageFlags waitDestStageMask = vk::PipelineStageFlags(vk::PipelineStageFlagBits::eTransfer);
  vk::SubmitInfo submitInfo(1, &imageAvailableSemaphore, &waitDestStageMask, 1, &cmdbuf, 1, &renderingFinishedSemaphore);
  gq.submit(1, &submitInfo, fences[frameIndex]);
}

void TS_VkQueuePresent()
{
  vk::PresentInfoKHR pInfo(1, &renderingFinishedSemaphore, 1, &swapchain, &frameIndex);
  pq.presentKHR(pInfo);
  pq.waitIdle();
}

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
    static_cast<uint32_t>(extensionNames.size()), extensionNames.data()
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
    static_cast<uint32_t>(queueCreateInfos.size()), queueCreateInfos.data(),
    0, nullptr,
    static_cast<uint32_t>(deviceExtensions.size()), deviceExtensions.data(),
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
  swapchainImageCount = static_cast<uint32_t>(swapchainImages.size());
}

vk::ImageView TS_VkCreateImageView(vk::Image img, vk::Format fmt, vk::ImageAspectFlagBits flags)
{
  vk::ImageViewCreateInfo viewInfo;
  viewInfo.viewType = vk::ImageViewType::e2D;
  viewInfo.image = img;
  viewInfo.format = fmt;
  viewInfo.subresourceRange.aspectMask = flags;
  viewInfo.subresourceRange.baseMipLevel = 0;
  viewInfo.subresourceRange.levelCount = 1;
  viewInfo.subresourceRange.baseArrayLayer = 0;
  viewInfo.subresourceRange.layerCount = 1;

  return dev.createImageView(viewInfo);
}

void TS_VkCreateImageViews()
{
  for (int i = 0; i < swapchainImages.size(); ++i)
  {
    swapchainImageViews.push_back(TS_VkCreateImageView(swapchainImages[i], surfaceFormat.format, vk::ImageAspectFlagBits::eColor));
  }
}

vk::Bool32 TS_VkGetSupportedDepthFormat()
{
  std::vector<vk::Format> depthFormats = {
    vk::Format::eD32SfloatS8Uint,
    vk::Format::eD32Sfloat,
    vk::Format::eD24UnormS8Uint,
    vk::Format::eD16UnormS8Uint,
    vk::Format::eD16Unorm
  };

  for (auto& format : depthFormats)
  {
    vk::FormatProperties formatProps = pdev.getFormatProperties(format);
    if (formatProps.optimalTilingFeatures & vk::FormatFeatureFlagBits::eDepthStencilAttachment)
    {
      depthFormat = format;
      return true;
    }
  }

  return false;
}

uint32_t TS_VkFindMemoryType(uint32_t typeFilter, vk::MemoryPropertyFlagBits properties)
{
  vk::PhysicalDeviceMemoryProperties memProperties = pdev.getMemoryProperties();

  for (uint32_t i = 0; i < memProperties.memoryTypeCount; ++i)
  {
    if ((typeFilter & (1 << i)) && (memProperties.memoryTypes[i].propertyFlags & properties) == properties)
    {
      return i;
    }
  }

  throw std::runtime_error("failed to find suitable memory type!");
}

void TS_VkCreateImage(uint32_t width, uint32_t height, vk::Format fmt, vk::ImageTiling tiling,
                      vk::ImageUsageFlagBits usage, vk::MemoryPropertyFlagBits properties,
                      vk::Image& img, vk::DeviceMemory& imageMemory)
{
  vk::ImageCreateInfo imageInfo;
  imageInfo.imageType = vk::ImageType::e2D;
  imageInfo.extent.width = width;
  imageInfo.extent.height = height;
  imageInfo.extent.depth = 1;
  imageInfo.mipLevels = 1;
  imageInfo.arrayLayers = 1;
  imageInfo.format = fmt;
  imageInfo.tiling = tiling;
  imageInfo.initialLayout = vk::ImageLayout::eUndefined;
  imageInfo.usage = usage;
  imageInfo.samples = vk::SampleCountFlagBits::e1;
  imageInfo.sharingMode = vk::SharingMode::eExclusive;

  img = dev.createImage(imageInfo);

  vk::MemoryRequirements memRequirements = dev.getImageMemoryRequirements(img);

  vk::MemoryAllocateInfo allocInfo;
  allocInfo.allocationSize = memRequirements.size;
  allocInfo.memoryTypeIndex = TS_VkFindMemoryType(memRequirements.memoryTypeBits, properties);

  imageMemory = dev.allocateMemory(allocInfo);
  dev.bindImageMemory(img, imageMemory, 0);
}

void TS_VkSetupDepthStencil()
{
  TS_VkGetSupportedDepthFormat();
  TS_VkCreateImage(swapchainSize.width, swapchainSize.height,
                  vk::Format::eD32SfloatS8Uint, vk::ImageTiling::eOptimal,
                  vk::ImageUsageFlagBits::eDepthStencilAttachment, vk::MemoryPropertyFlagBits::eDeviceLocal,
                  depthImage, depthImageMemory);
  depthImageView = TS_VkCreateImageView(depthImage, vk::Format::eD32SfloatS8Uint, vk::ImageAspectFlagBits::eDepth);
}

void TS_VkCreateRenderPass()
{
  std::vector<vk::AttachmentDescription> attachments(2);

  attachments[0].format = surfaceFormat.format;
	attachments[0].samples = vk::SampleCountFlagBits::e1;
	attachments[0].loadOp = vk::AttachmentLoadOp::eClear;
	attachments[0].storeOp = vk::AttachmentStoreOp::eStore;
	attachments[0].stencilLoadOp = vk::AttachmentLoadOp::eDontCare;
	attachments[0].stencilStoreOp = vk::AttachmentStoreOp::eDontCare;
	attachments[0].initialLayout = vk::ImageLayout::eUndefined;
	attachments[0].finalLayout = vk::ImageLayout::ePresentSrcKHR;

	attachments[1].format = depthFormat;
	attachments[1].samples = vk::SampleCountFlagBits::e1;
	attachments[1].loadOp = vk::AttachmentLoadOp::eClear;
	attachments[1].storeOp = vk::AttachmentStoreOp::eStore;
	attachments[1].stencilLoadOp = vk::AttachmentLoadOp::eClear;
	attachments[1].stencilStoreOp = vk::AttachmentStoreOp::eDontCare;
	attachments[1].initialLayout = vk::ImageLayout::eUndefined;
	attachments[1].finalLayout = vk::ImageLayout::eDepthStencilAttachmentOptimal;

	vk::AttachmentReference colorReference {
    0, vk::ImageLayout::eColorAttachmentOptimal
  };

	vk::AttachmentReference depthReference {
    1, vk::ImageLayout::eDepthStencilAttachmentOptimal
  };

	vk::SubpassDescription subpassDescription;
	subpassDescription.pipelineBindPoint = vk::PipelineBindPoint::eGraphics;
	subpassDescription.colorAttachmentCount = 1;
	subpassDescription.pColorAttachments = &colorReference;
	subpassDescription.pDepthStencilAttachment = &depthReference;
	subpassDescription.inputAttachmentCount = 0;
	subpassDescription.pInputAttachments = nullptr;
	subpassDescription.preserveAttachmentCount = 0;
	subpassDescription.pPreserveAttachments = nullptr;
	subpassDescription.pResolveAttachments = nullptr;

	std::vector<vk::SubpassDependency> dependencies(1);

	dependencies[0].srcSubpass = VK_SUBPASS_EXTERNAL;
	dependencies[0].dstSubpass = 0;
	dependencies[0].srcStageMask = vk::PipelineStageFlagBits::eBottomOfPipe;
	dependencies[0].dstStageMask = vk::PipelineStageFlagBits::eColorAttachmentOutput;
	dependencies[0].srcAccessMask = vk::AccessFlagBits::eMemoryRead;
	dependencies[0].dstAccessMask = vk::AccessFlagBits::eColorAttachmentRead | vk::AccessFlagBits::eColorAttachmentRead;
	dependencies[0].dependencyFlags = vk::DependencyFlagBits::eByRegion;

	vk::RenderPassCreateInfo renderPassInfo;
	renderPassInfo.attachmentCount = static_cast<uint32_t>(attachments.size());
	renderPassInfo.pAttachments = attachments.data();
	renderPassInfo.subpassCount = 1;
	renderPassInfo.pSubpasses = &subpassDescription;
	renderPassInfo.dependencyCount = static_cast<uint32_t>(dependencies.size());
	renderPassInfo.pDependencies = dependencies.data();

  rp = dev.createRenderPass(renderPassInfo);
}

void TS_VkCreateFramebuffers()
{
  for (size_t i = 0; i < swapchainImageViews.size(); ++i)
  {
    std::vector<vk::ImageView> attachments {
      swapchainImageViews[i],
      depthImageView
    };
    
    vk::FramebufferCreateInfo framebufferInfo {
      vk::FramebufferCreateFlags(),
      rp, attachments, swapchainSize.width, swapchainSize.height, 1
    };
    
    swapchainFramebuffers.push_back(dev.createFramebuffer(framebufferInfo));
  }
}

void TS_VkCreateCommandPool()
{
  cp = dev.createCommandPool({
    vk::CommandPoolCreateFlagBits::eResetCommandBuffer | vk::CommandPoolCreateFlagBits::eTransient,
    graphicsQueueFamilyIndex
  });
}

void TS_VkAllocateCommandBuffers()
{
  cmdbufs = dev.allocateCommandBuffers({cp, vk::CommandBufferLevel::ePrimary, swapchainImageCount});
}

void TS_VkCreateSemaphores()
{
  imageAvailableSemaphore = dev.createSemaphore({});
  renderingFinishedSemaphore = dev.createSemaphore({});
}

void TS_VkCreateFences()
{
  for (uint32_t i = 0; i < swapchainImageCount; ++i)
  {
    fences.push_back(dev.createFence({vk::FenceCreateFlagBits::eSignaled}));
  }
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
  TS_VkAllocateCommandBuffers();
  TS_VkCreateSemaphores();
  TS_VkCreateFences();
}

void TS_VkDestroyFences()
{
  for (int i = 0; i < swapchainImageCount; ++i)
  {
    dev.destroyFence(fences[i]);
  }
  fences.clear();
}

void TS_VkDestroySemaphores()
{
  dev.destroySemaphore(imageAvailableSemaphore);
  dev.destroySemaphore(renderingFinishedSemaphore);
}

void TS_VkFreeCommandBuffers()
{
  dev.freeCommandBuffers(cp, cmdbufs);
  cmdbufs.clear();
}

void TS_VkDestroyCommandPool()
{
  dev.destroyCommandPool(cp);
}

void TS_VkDestroyFramebuffers()
{
  for (int i = 0; i < swapchainFramebuffers.size(); ++i)
  {
    dev.destroyFramebuffer(swapchainFramebuffers[i]);
  }
  swapchainFramebuffers.clear();
}

void TS_VkDestroyRenderPass()
{
  dev.destroyRenderPass(rp);
}

void TS_VkTeardownDepthStencil()
{
  dev.destroyImageView(depthImageView);
  dev.freeMemory(depthImageMemory);
  dev.destroyImage(depthImage);
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

void TS_VkDestroySurface()
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
  TS_VkDestroyFramebuffers();
  TS_VkDestroyRenderPass();
  TS_VkTeardownDepthStencil();
  TS_VkDestroyImageViews();
  TS_VkDestroySwapchain();
  TS_VkDestroyDevice();
  TS_VkDestroySurface();
  TS_VkDestroyInstance();
}

std::string TS_GetSDLError()
{
  return std::string(SDL_GetError());
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
  mod.method("TS_VkAcquireNextImage", &TS_VkAcquireNextImage);
  mod.method("TS_VkResetCommandBuffer", &TS_VkResetCommandBuffer);
  mod.method("TS_VkBeginCommandBuffer", &TS_VkBeginCommandBuffer);
  mod.method("TS_VkBeginRenderPass", &TS_VkBeginRenderPass);
  mod.method("TS_VkEndRenderPass", &TS_VkEndRenderPass);
  mod.method("TS_VkEndCommandBuffer", &TS_VkEndCommandBuffer);
  mod.method("TS_VkQueueSubmit", &TS_VkQueueSubmit);
  mod.method("TS_VkQueuePresent", &TS_VkQueuePresent);
  mod.method("TS_VkCreateInstance", &TS_VkCreateInstance);
  mod.method("TS_VkCreateSurface", &TS_VkCreateSurface);
  mod.method("TS_VkSelectPhysicalDevice", &TS_VkSelectPhysicalDevice);
  mod.method("TS_VkSelectQueueFamily", &TS_VkSelectQueueFamily);
  mod.method("TS_VkCreateDevice", &TS_VkCreateDevice);
  mod.method("TS_VkCreateSwapchain", &TS_VkCreateSwapchain);
  mod.method("TS_VkCreateImageViews", &TS_VkCreateImageViews);
  mod.method("TS_VkGetSupportedDepthFormat", &TS_VkGetSupportedDepthFormat);
  mod.method("TS_VkSetupDepthStencil", &TS_VkSetupDepthStencil);
  mod.method("TS_VkCreateRenderPass", &TS_VkCreateRenderPass);
  mod.method("TS_VkCreateFramebuffers", &TS_VkCreateFramebuffers);
  mod.method("TS_VkCreateCommandPool", &TS_VkCreateCommandPool);
  mod.method("TS_VkAllocateCommandBuffers", &TS_VkAllocateCommandBuffers);
  mod.method("TS_VkCreateSemaphores", &TS_VkCreateSemaphores);
  mod.method("TS_VkCreateFences", &TS_VkCreateFences);
  mod.method("TS_VkInit", &TS_VkInit);
  mod.method("TS_VkDestroyFences", &TS_VkDestroyFences);
  mod.method("TS_VkDestroySemaphores", &TS_VkDestroySemaphores);
  mod.method("TS_VkFreeCommandBuffers", &TS_VkFreeCommandBuffers);
  mod.method("TS_VkDestroyCommandPool", &TS_VkDestroyCommandPool);
  mod.method("TS_VkDestroyFramebuffers", &TS_VkDestroyFramebuffers);
  mod.method("TS_VkDestroyRenderPass", &TS_VkDestroyRenderPass);
  mod.method("TS_VkTeardownDepthStencil", &TS_VkTeardownDepthStencil);
  mod.method("TS_VkDestroyImageViews", &TS_VkDestroyImageViews);
  mod.method("TS_VkDestroySwapchain", &TS_VkDestroySwapchain);
  mod.method("TS_VkDestroyDevice", &TS_VkDestroyDevice);
  mod.method("TS_VkDestroySurface", &TS_VkDestroySurface);
  mod.method("TS_VkDestroyInstance", &TS_VkDestroyInstance);
  mod.method("TS_VkQuit", &TS_VkQuit);
  mod.method("TS_GetSDLError", &TS_GetSDLError);
  mod.method("TS_Init", &TS_Init);
  mod.method("TS_Quit", &TS_Quit);
  mod.method("TS_PlaySound", &TS_PlaySound);
  mod.method("TS_DrawPoint", &TS_DrawPoint);
  mod.method("TS_DrawLine", &TS_DrawLine);
  mod.method("TS_DrawRect", &TS_DrawRect);
  mod.method("TS_DrawSprite", &TS_DrawSprite);
  mod.method("TS_DrawText", &TS_DrawText);
}