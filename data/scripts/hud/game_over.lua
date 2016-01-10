local game = ...

local game_over_menu = {}  -- The game-over menu.

local music
local hero_was_visible
local hero_dead_spr
local hero_dead_x, hero_dead_y
local fade_sprite
local state

function game:on_game_over_started()
  sol.menu.start(game:get_map(), game_over_menu)
end

function game_over_menu:on_started()
local slot1 = game:get_value("_item_slot_1")
local slot2 = game:get_value("_item_slot_2")
local hero = game:get_hero()
local tunic = game:get_ability("tunic")

game:start_cutscene()

if not show_bars then game:show_bars() end
  
  game:get_item(slot1):on_map_changed()
  game:get_item(slot2):on_map_changed()
  
  if hero:get_state() == "free" then hero:set_walking_speed(88) end

  game:set_hud_enabled(false)
  hero_was_visible = hero:is_visible()
  hero:set_visible(false)
  music = sol.audio.get_music()
  
  hero_dead_spr = sol.sprite.create("hero/tunic"..tunic)
  hero_dead_spr:set_animation("hurt")
  hero_dead_spr:set_direction(hero:get_direction())
  hero_dead_spr:set_paused(true)
  fade_sprite = sol.sprite.create("hud/gameover_fade")
  state = "waiting_start"

  local map = game:get_map()
  local camera_x, camera_y = map:get_camera_position()
  local hero_x, hero_y = hero:get_position()
  hero_dead_x = hero_x - camera_x
  hero_dead_y = hero_y - camera_y

  sol.timer.start(self, 700, function()
    state = "closing_game"
    sol.audio.stop_music()
    fade_sprite:set_animation("close")
    fade_sprite.on_animation_finished = function()
      if state == "closing_game" then
        state = "red_screen"
        sol.audio.play_sound("hero_dying")
        hero_dead_spr:set_paused(false)
        hero_dead_spr:set_direction(0)
        hero_dead_spr:set_animation("dying")
        sol.timer.start(self, 2000, function()
          state = "opening_menu"
          fade_sprite:set_animation("open")
        end)
      elseif state == "opening_menu" then
        local bottle_with_fairy = game:get_first_bottle_with(7)
        if bottle_with_fairy ~= nil then
          -- Has a fairy.
          game:set_hud_enabled(true)
          state = "saved_by_fairy"
          -- Make the bottle empty.
          bottle_with_fairy:set_variant(1)

sol.audio.play_sound("objects/fairy/interact")
local x, y, layer = sol.main.game:get_hero():get_position()
local fairy_c_sprite = sol.main.game:get_map():create_custom_entity({
x = x,
y = y,
layer = layer + 1,
direction = 0,
sprite = "entities/items",
})
fairy_c_sprite:get_sprite():fade_in(30)

    fairy_c_sprite:set_can_traverse("crystal", true)
    fairy_c_sprite:set_can_traverse("crystal_block", true)
    fairy_c_sprite:set_can_traverse("hero", true)
    fairy_c_sprite:set_can_traverse("jumper", true)
    fairy_c_sprite:set_can_traverse("stairs", true)
    fairy_c_sprite:set_can_traverse("stream", true)
    fairy_c_sprite:set_can_traverse("switch", true)
    fairy_c_sprite:set_can_traverse("wall", true)
    fairy_c_sprite:set_can_traverse("teletransporter", true)
    fairy_c_sprite:set_can_traverse_ground("deep_water", true)
    fairy_c_sprite:set_can_traverse_ground("wall", true)
    fairy_c_sprite:set_can_traverse_ground("shallow_water", true)
    fairy_c_sprite:set_can_traverse_ground("hole", true)
    fairy_c_sprite:set_can_traverse_ground("lava", true)
    fairy_c_sprite:set_can_traverse_ground("prickles", true)
    fairy_c_sprite:set_can_traverse_ground("low_wall", true) 
    fairy_c_sprite.apply_cliffs = true
	
fairy_c_sprite:get_sprite():set_animation("fairy")

local movement = sol.movement.create("circle")
movement:set_center(sol.main.game:get_hero())
movement:set_radius(16)
movement:set_angle_speed(500)
movement:set_max_rotations(7)
movement:start(fairy_c_sprite)

sol.timer.start(4250, function() fairy_c_sprite:get_sprite():fade_out(10, function() fairy_c_sprite:remove(); movement:stop() end) end)

         sol.timer.start(1700, function()
            state = "waiting_end"
            game:add_life(10 * 4)  -- Restore 10 hearts.
            sol.timer.start(self, 3000, function()
			  game:stop_cutscene()
			  game:set_pause_allowed(true)
			  if show_bars and not is_cutscene then game:hide_bars() end
              state = "resume_game"
              sol.audio.play_music(music)
              game:stop_game_over()
              sol.menu.stop(self)
            end)
          end)
        else
          -- No fairy: game over.
	sol.audio.play_music("/menu/game_over_starting", false)
	sol.timer.start(self, 6500, function()
	game:stop_cutscene()
    game:start()
	end)
        end

      end
    end
  end)
end

function game_over_menu:on_finished()

  local hero = game:get_hero()
  if hero ~= nil then
    hero:set_visible(hero_was_visible)
  end
  music = nil
  hero_dead_spr = nil
  fade_sprite = nil
  fairy_sprite = nil
  state = nil
  sol.timer.stop_all(self)
end

local black = {0, 0, 0}
local red = {224, 32, 32}

function game_over_menu:on_draw(dst_surface)

  -- if state ~= "waiting_start" and state ~= "closing_game" then
    --Hide the whole map.
    -- dst_surface:fill_color(black)
  -- end

  if state == "menu" or state == "finished" then
    background_img:draw(dst_surface)
    fairy_sprite:draw(dst_surface)
  elseif state ~= "resume_game" then
    hero_dead_spr:draw(dst_surface, hero_dead_x, hero_dead_y)
  end
end
