--[[--
Simple logger by Dark
--]]--
require "defines"

local _M = {}
local Logger = {prefix='log_', index = 0}
Logger.__index = Logger

function Logger:log(str)
  local run_time_s = math.floor(game.tick/60)
  local run_time_minutes = math.floor(run_time_s/60)
  local run_time_hours = math.floor(run_time_minutes/60)
  self.log_buffer[#self.log_buffer + 1] = string.format("%02d:%02d:%02d: %s\r\n", run_time_hours, run_time_minutes % 60, run_time_s % 60, str)
  self:dump("logs/temp.log", false)
  if #self.log_buffer > 500 then
      self:dump("logs/dump"..self.index.. ".log", true)
      self.index = self.index +1
  end
end

function Logger:dump(file_name, clear)
  if #self.log_buffer == 0 then return false end
  file_name = file_name or "logs/"..self.prefix..game.tick..".log"
  game.write_file(file_name, table.concat(self.log_buffer))
  if (clear == nil or clear) then self.log_buffer = {} end
  return true
end


function _M.new_logger()
  local temp = {log_buffer = {}}
  return setmetatable(temp, Logger)
end
return _M