local _N = setmetatable({},{
  __index = function(self,hash)
    hash = tostring(hash)

    if hash:sub(0,2) == 'N_' then
      hash = hash:sub(3)
    end

    return function(...)
      return Citizen.InvokeNative(hash,...)
    end
  end
})

local interiorEntitySets = {
  "val_genstore_night_light",
  "_p_apple01x_dressing",
  "_p_apple01x_group",
  "_p_bread06x_dressing",
  "_p_bread06x_group",
  "_p_carrots_01x_dressing",
  "_p_carrots_01x_group",
  "_p_cigar02x_dressing",
  "_p_cigar02x_group",
  "_p_cigarettebox01x_dressing",
  "_p_cigarettebox01x_group",
  "_p_corn02x_dressing",
  "_p_corn02x_group",
  "_p_int_fishing01_dressing",
  "_p_package01x_dressing",
  "_p_package01x_group",
  "_p_pear_02x_dressing",
  "_p_pear_02x_group",
  "_p_tin_pomade01x_dressing",
  "_p_tin_pomade01x_group",
  "_p_tin_soap01x_dressing",
  "_p_tin_soap01x_group",
  "_s_biscuits01x_dressing",
  "_s_biscuits01x_group",
  "_s_canBeans01x_group",
  "_s_canBeans01_dressing",
  "_s_canCorn01x_dressing",
  "_s_canCorn01x_group",
  "_s_candyBag01x_red_group",
  "_s_canPeaches01x_dressing",
  "_s_canPeaches01x_group",
  "_s_cheeseWedge1x_group",
  "_s_chocolateBar02x_dressing",
  "_s_chocolateBar02x_group",
  "_s_coffeeTin01x_dressing",
  "_s_coffeeTin01x_group",
  "_s_crackers01x_dressing",
  "_s_crackers01x_group",
  "_s_cricketTin01x_dressing",
  "_s_cricketTin01x_group",
  "_s_gunOil01x_dressing",
  "_s_gunOil01x_group",
  "_s_inv_baitHerb01x_dressing",
  "_s_inv_baitherb01x_group",
  "_s_inv_baitMeat01x_dressing",
  "_s_inv_baitmeat01x_group",
  "_s_inv_gin01x_dressing",
  "_s_inv_gin01x_group",
  "_s_inv_horsePills01x_dressing",
  "_s_inv_horsePills01x_group",
  "_s_inv_pocketwatch04x_dressing",
  "_s_inv_pocketWatch04x_group",
  "_s_inv_rum01x_dressing",
  "_s_inv_rum01x_group",
  "_s_inv_tabacco01x_dressing",
  "_s_inv_tabacco01x_group",
  "_s_inv_whiskey01x_dressing",
  "_s_inv_whiskey01x_group",
  "_s_oatcakes01x_dressing",
  "_s_oatcakes01x_group",
  "_s_offal01x_dressing",
  "_s_offal01x_group",
  "_s_saltedbeef01x_group",
  "_s_saltedbeef02x_group",
  "_s_wormCan01x_dressing",
  "_s_wormcan01x_group",
}

local function unloadInterior(intId)
  for _,entitySet in ipairs(interiorEntitySets) do
    if IsInteriorEntitySetActive(intId,entitySet) then
      DeactivateInteriorEntitySet(intId,entitySet)
    end
  end
end

local function loadInterior(intId)
  for _,entitySet in ipairs(interiorEntitySets) do
    if not IsInteriorEntitySetActive(intId,entitySet) then
      ActivateInteriorEntitySet(intId,entitySet)
    end
  end
end

local function createPrompt(entId,itemId)
  local view = DataView(12 * 8) 

  view:SetInt32(8*0,entId)
  view:SetInt32(8*1,itemId)
  view:SetInt32(8*2,itemId)
  view:SetInt32(8*4,0)
  view:SetInt32(8*5,0)
  view:SetInt32(8*6,0)
  
  _N['0xFD41D1D4350F6413'](view:Buffer())

  return view
end

local function enablePrompt(target)
  target.view:SetInt32(8*6,  1 | 2 | 16)
  _N['0xFD41D1D4350F6413'](target.view:Buffer())
end

local function disablePrompt(target)
  target.view:SetInt32(8*6,  0)
  _N['0xFD41D1D4350F6413'](target.view:Buffer())
end

local shops = {
  {
    name = 'Valentine General',
    interiorId = 45826,
    pos = vec(-321.16,799.47,117.93)
  },
}

local function isEntityValid(ent)
  return (ent and ent ~= 0 and ent ~= -1)
end

local function checkInfoRequest(infoReq,infoTargets)
  if not infoReq then
    return
  end

  local entId   = infoReq[0]
  local itemId  = infoReq[1]

  if not isEntityValid(entId) then
    return
  end

  if infoTargets[entId] then
    return
  end

  local view = createPrompt(entId,itemId)

  infoTargets[entId] = {
    entId   = entId,
    itemId  = itemId,     
    view    = view,      
  }
end

local function checkInteriors(plyPos)
  for _,shop in ipairs(shops) do
    local dist = #(shop.pos - plyPos)

    if dist <= 50.0 and not shop.loaded then
      loadInterior(shop.interiorId)
      shop.loaded = true
    elseif dist >= 100.0 and shop.loaded then
      unloadInterior(shop.interiorId)
      shop.loaded = false
    end
  end
end

local function sortTargetsByDistance(targetPos,infoTargets)
  local arr = {}

  for entId,target in pairs(infoTargets) do
    local pos = GetEntityCoords(entId)

    table.insert(arr,{
      dist  = #(pos - targetPos),
      pos   = pos,
      entId = entId
    })
  end

  table.sort(arr,function(a,b)
    return a.dist < b.dist
  end)

  return arr[1]
end

local function checkRaycast(plyPos,infoTargets,lastTarget)
  local hit,endCoords,entHit = s2w.getAsync(4294967295)

  if endCoords == vec3(0,0,0) then
    return nil
  end

  local targetPos = endCoords
  local target = sortTargetsByDistance(endCoords,infoTargets)  

  if lastTarget and (not target or lastTarget ~= target) then
    disablePrompt(lastTarget)
  end

  if not target then
    return nil
  end

  local plyDist = #(target.pos - plyPos)

  if plyDist     > 5.0
  or target.dist > 1.0
  then
    return nil
  end

  local infoTarget = infoTargets[target.entId]
  
  enablePrompt(infoTarget)

  return infoTarget
end

local now
local eventData
local plyPed,plyPos
local lastInteriorCheck
local targetObjects = {}
local infoTargets = {}
local lastTarget

Citizen.CreateThread(function()
  while true do
    now       = GetGameTimer()
    plyPed    = PlayerPedId()
    plyPos    = GetEntityCoords(plyPed)
    eventData = events.getEventData("EVENT_ITEM_PROMPT_INFO_REQUEST")

    if not lastInteriorCheck or now - lastInteriorCheck >= 500 then
      checkInteriors(plyPos)
      lastInteriorCheck = now
    end     

    checkInfoRequest(eventData,infoTargets)
    lastTarget = checkRaycast(plyPos,infoTargets,lastTarget)

    Wait(0)
  end
end)