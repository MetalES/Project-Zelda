return function(submenu)

  submenu.sage_sprite = {}
  for i = 1, 8 do
	submenu.sage_sprite[i] = sol.sprite.create("npc/sage/" .. i + 3)
  end
end