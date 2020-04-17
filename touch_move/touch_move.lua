touchMoveWindow = nil
touchMoveButton = nil
addTouchMoveWindow = nil
windowType = nil

function init()

  windowType = g_settings.getBoolean('touchMove_isAdvanced')
  if windowType == nil then
    windowType = false
  end

  touchMoveButton = modules.client_topmenu.addRightGameToggleButton('touchMoveButton', tr('Touch Move'), '/touch_move/img_touch_move/moving_keys_icon', toggle)
  touchMoveButton:setOn(true)

  if windowType == false then
    touchMoveWindow = g_ui.loadUI('touch_move', modules.game_interface.getRightPanel())
    touchMoveWindow:setup()
    touchMoveWindow:setContentMinimumHeight(130)
    touchMoveWindow:setContentMaximumHeight(130)
    touchMoveWindow:setHeight(154)
    windowType = true
  else
    touchMoveWindow = g_ui.loadUI('touch_move_advanced', modules.game_interface.getRightPanel())
    touchMoveWindow:setup()
    touchMoveWindow:setContentMinimumHeight(190)
    touchMoveWindow:setContentMaximumHeight(190)
    touchMoveWindow:setHeight(215)
    windowType = false
  end
end

function changeNormalToAdvanced()
  if windowType then
    clear()
    touchMoveWindow:destroy()
    touchMoveWindow = g_ui.loadUI('touch_move_advanced', modules.game_interface.getRightPanel())
    touchMoveWindow:setup()
    windowType = false
    touchMoveWindow:setContentMinimumHeight(190)
    touchMoveWindow:setContentMaximumHeight(190)
    touchMoveWindow:setHeight(215)
    g_settings.set('touchMove_isAdvanced', true)
  else
    clear()
    touchMoveWindow:destroy()
    touchMoveWindow = g_ui.loadUI('touch_move', modules.game_interface.getRightPanel())
    touchMoveWindow:setup()
    windowType = true
    touchMoveWindow:setContentMinimumHeight(130)
    touchMoveWindow:setContentMaximumHeight(130)
    touchMoveWindow:setHeight(154)
    g_settings.set('touchMove_isAdvanced', false)
  end
end

function terminate()
  disconnect(g_game, { onGameEnd = clear })

  touchMoveWindow:destroy()
  touchMoveButton:destroy()

end

function clear()
  local touchMoveList = touchMoveWindow:getChildById('contentsPanel')
  touchMoveList:destroyChildren()
end

function toggle()
  if touchMoveButton:isOn() then
    touchMoveWindow:close()
    touchMoveButton:setOn(false)
  else
    touchMoveWindow:open()
    touchMoveButton:setOn(true)
  end
end

function onMiniWindowClose()
  touchMoveButton:setOn(false)
end

--Moving--

local eventDis = {}

function touchMove(dir)
  if dir == 'N' then
    g_game.walk(North)
  elseif dir == 'S' then
    g_game.walk(South)
  elseif dir == 'W' then
    g_game.walk(West)
  elseif dir == 'E' then
    g_game.walk(East)
  elseif dir == 'NW' then
    g_game.walk(NorthWest)
  elseif dir == 'NE' then
    g_game.walk(NorthEast)
  elseif dir == 'SW' then
    g_game.walk(SouthWest)
  elseif dir == 'SE' then
    g_game.walk(SouthEast)
  end
end

function AutoTouchMove(dir)
  eventDis[true] = cycleEvent(function()
    touchMove(dir)
  end, 50)
end

function AutoTouchMoveEnd()
  removeEvent(eventDis[true])
end

-------------------------------------------------
--Attack Scripts---------------------------------
-------------------------------------------------

function getSortedBattleList()
  local unsortedList = table.copy(modules.game_battle.battleButtonsByCreaturesList)

  local tableCount = table.size(unsortedList)

  local sortedTable = {}

  for i=1,tableCount do
    local helpValue = nil
    
    for a,b in pairs(unsortedList) do
      if helpValue == nil then
        helpValue = {creatureId = a, creatureData = b}
      else
        if b:getY() < helpValue.creatureData:getY() then
          helpValue = {creatureId = a, creatureData = b}
        end
      end
    end

    sortedTable[i] = helpValue
    unsortedList[helpValue.creatureId] = nil
  end

  return sortedTable
end

local battleListCounter = 1
local lastAttackedMonster = 0

function ChooseAimFromBattleList()
  local battleListTable = getSortedBattleList()
  local tableCount = table.size(battleListTable)

  if battleListCounter > tableCount then
    battleListCounter = 1
  end

  for i=1,tableCount do
    if battleListCounter > 1 and g_game.isAttacking() == false and lastAttackedMonster ~= battleListTable[battleListCounter - 1].creatureId then
      battleListCounter = battleListCounter - 1
    end

    if isNpcOrSafeFight(battleListTable[battleListCounter].creatureId) then
      g_game.attack(g_map.getCreatureById(battleListTable[battleListCounter].creatureId))
      lastAttackedMonster = battleListTable[battleListCounter].creatureId
      battleListCounter = battleListCounter + 1
      return
    end
    battleListCounter = battleListCounter + 1

    if battleListCounter > tableCount then
      battleListCounter = 1
    end
  end
end

function isNpcOrSafeFight(creatureId)
  local creatureData = g_map.getCreatureById(creatureId)

  if creatureData:isMonster() then
    return true
  elseif creatureData:isPlayer() then
    if g_game.isSafeFight() then
      return false
    else
      return true
    end
  elseif creatureData:isNpc() then
    return false
  else
    return false
  end
end
