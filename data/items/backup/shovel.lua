local item = ...

function item:on_created()
  self:set_savegame_variable("i1838")
  self:set_assignable(true)
end

function item:on_using()
print("Work in Progress")
self:set_finished()
end