local map = ... 
local game = map:get_game()
local env_timer

function map:on_started(destination)

if destination == from_out then
  self:start_transition_to_room()
end

-- Display the Fog

self:get_game():display_fog("fire_mist", 10, 3, 50)
self:get_entity("k_dodongo"):set_enabled(false)
self:get_entity("head"):set_enabled(false)

sol.audio.play_sound("environment/lava")
env_timer = sol.timer.start(10000, function()
sol.audio.play_sound("environment/lava")
return true
end)

env_timer:set_suspended_with_map(false)

heart_container:set_enabled(false)
k_dodongo_dead_body:set_enabled(false)
end

function a:on_activated()
map:get_entity("k_dodongo"):set_enabled(true)
--map:get_entity("head"):set_enabled(true)
end

local function start_vaati_cutscene()
  
end

function map:start_transition_to_room()
  game.display_cutscene_bars = true
  game:disable_all_input()
  game:set_hud_enabled(false)
  game:set_clock_enabled(false)
  local m = sol.movement.create("straight")
  m:set_ignore_obstacles(true)
  m:set_speed(50)
  m:set_angle(3 * math.pi / 2)
  m:set_max_distance(32)
  m:start(self:get_entity("boss_door_2"))
  self:get_entity("boss_door_2"):set_can_traverse("hero", true)
  self:get_entity("boss_door_2"):set_traversable_by("hero", true)
  sol.timer.start(500, function()
    hero:freeze()
    sol.audio.play_sound("/common/door/stone_open")
  end)

  sol.timer.start(1200, function()
  if self:get_game():get_ability("shield") > 0 then 
    hero:set_animation("walking_with_shield") 
  else
    hero:set_animation("walking")
  end

  local n = sol.movement.create("straight")
  n:set_speed(64)
  n:set_angle(hero:get_direction() * math.pi / 2)
  n:set_max_distance(64)
  n:start(hero, function()
   if self:get_game():get_ability("shield") > 0 then 
    hero:set_animation("stopped_with_shield") 
   else
    hero:set_animation("stopped")
   end

   sol.timer.start(800, function()
      local m = sol.movement.create("straight")
      m:set_ignore_obstacles(true)
      m:set_speed(50)
      m:set_angle(math.pi / 2)
      m:set_max_distance(32)
      m:start(self:get_entity("boss_door_2"), function()
      sol.audio.play_sound("/common/door/stone_slam")

      sol.timer.start(1000, function()
        game.dispose_cutscene_bars = true
        game:enable_all_input()
        hero:unfreeze()
        game:set_pause_allowed(true)
        game:set_hud_enabled(true)
        game:set_clock_enabled(true)
      end)
      end)
    self:get_entity("boss_door_2"):set_can_traverse("hero", false)
    self:get_entity("boss_door_2"):set_traversable_by("hero", false)
    sol.audio.play_sound("/common/door/stone_close")
    game.fighting_boss = true
   end)
  end)
 end)
end

