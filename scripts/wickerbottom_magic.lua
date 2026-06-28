local _G = GLOBAL

local PLAYER_REGEN_INTERVAL = 60
local PLAYER_REGEN_AMOUNT = 15

local function IsWickerbottomPlayer(player)
    return player ~= nil
        and player:IsValid()
        and player:HasTag("player")
        and player.prefab == "wickerbottom"
end

local function GetWickerbottomOwner(inst)
    if inst == nil or inst.components.inventoryitem == nil then
        return nil
    end

    local owner = inst.components.inventoryitem:GetGrandOwner()
    return IsWickerbottomPlayer(owner) and owner or nil
end

local function ShouldPreserveDurability(inst)
    local owner = GetWickerbottomOwner(inst)
    return owner ~= nil and not owner:IsInLimbo()
end

local function RestoreWickerbottomStats(inst)
    if not IsWickerbottomPlayer(inst)
        or inst:IsInLimbo()
        or inst.components.health == nil
        or inst.components.health:IsDead()
    then
        return
    end

    inst.components.health:DoDelta(PLAYER_REGEN_AMOUNT, false, "wickerbottom_magic")

    if inst.components.hunger ~= nil then
        inst.components.hunger:DoDelta(PLAYER_REGEN_AMOUNT)
    end

    if inst.components.sanity ~= nil then
        inst.components.sanity:DoDelta(PLAYER_REGEN_AMOUNT)
    end
end

AddPrefabPostInit("wickerbottom", function(inst)
    if not _G.TheWorld.ismastersim then
        return
    end

    inst._dwm_regen_task = inst:DoPeriodicTask(PLAYER_REGEN_INTERVAL, RestoreWickerbottomStats, PLAYER_REGEN_INTERVAL)
end)

AddComponentPostInit("finiteuses", function(self)
    if self._dwm_use_wrapped == true then
        return
    end

    self._dwm_use_wrapped = true
    local original_use = self.Use

    self.Use = function(component, num)
        if ShouldPreserveDurability(component.inst) then
            return
        end

        return original_use(component, num)
    end
end)

AddComponentPostInit("fueled", function(self)
    if self._dwm_delta_wrapped == true then
        return
    end

    self._dwm_delta_wrapped = true
    local original_do_delta = self.DoDelta

    self.DoDelta = function(component, amount, doer)
        if amount ~= nil and amount < 0 and ShouldPreserveDurability(component.inst) then
            return
        end

        return original_do_delta(component, amount, doer)
    end
end)

AddComponentPostInit("armor", function(self)
    if self._dwm_take_damage_wrapped == true then
        return
    end

    self._dwm_take_damage_wrapped = true
    local original_take_damage = self.TakeDamage

    self.TakeDamage = function(component, damage_amount)
        if damage_amount ~= nil and damage_amount > 0 and ShouldPreserveDurability(component.inst) then
            return
        end

        return original_take_damage(component, damage_amount)
    end
end)
