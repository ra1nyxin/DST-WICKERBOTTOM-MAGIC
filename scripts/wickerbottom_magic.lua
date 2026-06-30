local _G = GLOBAL

local PLAYER_REGEN_INTERVAL = 60
local PLAYER_REGEN_AMOUNT = 15
local MAX_HEALING_NORMAL = _G.TUNING.MAX_HEALING_NORMAL
local SLINGSHOT_PREFABS = {
    slingshot = true,
    slingshot2 = true,
    slingshotex = true,
    slingshot999ex = true,
    slingshot2ex = true,
}

local function IsWickerbottomPlayer(player)
    return player ~= nil
        and player:IsValid()
        and player:HasTag("player")
        and player.prefab == "wickerbottom"
end

local function IsWalterPlayer(player)
    return player ~= nil
        and player:IsValid()
        and player:HasTag("player")
        and player.prefab == "walter"
end

local function WalterHasMagicBook(player)
    return IsWalterPlayer(player)
        and player.components.inventory ~= nil
        and player.components.inventory:HasItemWithTag("book", 1)
end

local function IsMagicBoostedPlayer(player)
    return IsWickerbottomPlayer(player) or WalterHasMagicBook(player)
end

local function GetMagicBoostedOwner(inst)
    if inst == nil or inst.components.inventoryitem == nil then
        return nil
    end

    local owner = inst.components.inventoryitem:GetGrandOwner()
    return IsMagicBoostedPlayer(owner) and owner or nil
end

local function ShouldPreserveDurability(inst)
    local owner = GetMagicBoostedOwner(inst)
    return owner ~= nil and not owner:IsInLimbo()
end

local function ShouldPreserveWalterBookUses(inst)
    return inst ~= nil
        and inst:HasTag("book")
        and IsWalterPlayer(inst._dwm_active_reader)
end

local function RestoreMagicReaderStats(inst)
    if not IsMagicBoostedPlayer(inst)
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

    if MAX_HEALING_NORMAL ~= nil then
        inst.components.health:DeltaPenalty(MAX_HEALING_NORMAL)
    end
end

AddPrefabPostInit("wickerbottom", function(inst)
    if not _G.TheWorld.ismastersim then
        return
    end

    inst._dwm_regen_task = inst:DoPeriodicTask(PLAYER_REGEN_INTERVAL, RestoreMagicReaderStats, PLAYER_REGEN_INTERVAL)
end)

AddPrefabPostInit("walter", function(inst)
    inst:AddTag("reader")

    if not _G.TheWorld.ismastersim then
        return
    end

    if inst.components.reader == nil then
        inst:AddComponent("reader")
    end

    inst._dwm_regen_task = inst:DoPeriodicTask(PLAYER_REGEN_INTERVAL, RestoreMagicReaderStats, PLAYER_REGEN_INTERVAL)
end)

AddComponentPostInit("finiteuses", function(self)
    if self._dwm_use_wrapped == true then
        return
    end

    self._dwm_use_wrapped = true
    local original_use = self.Use

    self.Use = function(component, num)
        if ShouldPreserveDurability(component.inst) or ShouldPreserveWalterBookUses(component.inst) then
            return
        end

        return original_use(component, num)
    end
end)

AddComponentPostInit("reader", function(self)
    if self._dwm_read_wrapped == true then
        return
    end

    self._dwm_read_wrapped = true
    local original_read = self.Read

    self.Read = function(component, book)
        if book ~= nil and book:IsValid() then
            book._dwm_active_reader = component.inst
        end

        local success, reason = original_read(component, book)

        if book ~= nil and book:IsValid() then
            book._dwm_active_reader = nil
        end

        return success, reason
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

local function WrapSlingshotAmmoUse(inst)
    if not _G.TheWorld.ismastersim
        or inst == nil
        or not inst:IsValid()
        or inst._dwm_ammo_wrapped == true
        or inst.components.weapon == nil
        or inst.components.container == nil
        or SLINGSHOT_PREFABS[inst.prefab] ~= true
    then
        return
    end

    local original_onprojectilelaunched = inst.components.weapon.onprojectilelaunched
    if original_onprojectilelaunched == nil then
        return
    end

    inst._dwm_ammo_wrapped = true
    inst.components.weapon:SetOnProjectileLaunched(function(slingshot, attacker, target, proj)
        if not WalterHasMagicBook(attacker) then
            return original_onprojectilelaunched(slingshot, attacker, target, proj)
        end

        local container = slingshot.components.container
        local original_remove_item = container.RemoveItem
        local original_remove_item_by_slot = container.RemoveItemBySlot

        container.RemoveItem = function(component, item, wholestack, checkallcontainers, keepoverstacked)
            if item ~= nil and item:HasTag("slingshotammo") then
                return nil
            end

            return original_remove_item(component, item, wholestack, checkallcontainers, keepoverstacked)
        end

        container.RemoveItemBySlot = function(component, slot, keepoverstacked)
            local slotitem = component:GetItemInSlot(slot)
            if slotitem ~= nil and slotitem:HasTag("slingshotammo") then
                return nil
            end

            return original_remove_item_by_slot(component, slot, keepoverstacked)
        end

        original_onprojectilelaunched(slingshot, attacker, target, proj)

        container.RemoveItem = original_remove_item
        container.RemoveItemBySlot = original_remove_item_by_slot
    end)
end

for prefab in pairs(SLINGSHOT_PREFABS) do
    AddPrefabPostInit(prefab, WrapSlingshotAmmoUse)
end
