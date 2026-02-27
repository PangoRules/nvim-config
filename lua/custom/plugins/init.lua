-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

local profile = vim.env.NVIM_PROFILE or ''
if profile == 'vue-dotnet' then
  return require 'custom.plugins.vue_dotnet'
elseif profile == 'react' then
  return require 'custom.plugins.react'
elseif profile == 'python' then
  return require 'custom.plugins.python'
elseif profile == 'node' then
  return require 'custom.plugins.node'
end
return {}
