这是一个在饥荒联机版服务器中增强Wickerbottom的小模组喵。

当前功能：
- Wickerbottom 使用自己物品栏或背包中的 `finiteuses` 物品时不会消耗次数。
- Wickerbottom 使用自己物品栏或背包中的 `fueled` 耐久物品时不会消耗耐久。
- Wickerbottom 使用自己身上的 `armor` 护甲时不会损失护甲耐久。
- Wickerbottom 每 60 秒回复 15 点饥饿、15 点理智、15 点生命。
- Wickerbottom 每 60 秒还会额外获得一次原版强心针那种恢复最大生命惩罚的效果。
- Walter 现在也可以使用 Wickerbottom 的所有魔法类书籍。
- Walter 读这些魔法书时只会掉读书的 san，不会消耗书的耐久或使用次数。
- 只要 Walter 背包里带着任意一本魔法类书籍，他的可靠的弹弓发射时就不会消耗已装填的弹药。
- 只要 Walter 身上带着任意一本魔法类书籍，他物品栏、装备栏、背包中的各种有耐久、次数、持续消耗限制的物品也都不会被消耗。
- 只要 Walter 身上带着任意一本魔法类书籍，他也会获得和 Wickerbottom 一样的每 60 秒回复 15 点饥饿、15 点理智、15 点生命，以及恢复最大生命惩罚的效果。

目前覆盖的耐久类型：
- `finiteuses`：如工具、武器、书籍、法杖等使用次数类物品。
- `fueled`：如提灯、矿灯、部分持续消耗型物品。
- `armor`：如草甲、木甲、矿甲等护甲耐久类物品。

说明：
- 这里做的是“不消耗”，不是循环把耐久刷回 100%。
- 如果一个物品原本是 70% 耐久，交给 Wickerbottom 使用很多次之后，它依然会保持 70%。
- 如果 Walter 身上带着魔法类书籍，那么 Walter 使用同一个 70% 耐久物品很多次之后，它也依然会保持 70%。
- 其他角色使用同一个物品时，耐久依然会正常消耗。
- 代码走的是组件级拦截，不改角色 brain 或状态图，冲突面相对更小一些。
- 强心针效果这里没有走打针动作前摇，而是直接套用原版 `DeltaPenalty(TUNING.MAX_HEALING_NORMAL)` 那条恢复最大生命惩罚的逻辑。
- Walter 这里只是增加了“能用书”、“挂书时全物品不掉消耗”、“挂书时自动恢复”、“挂书时弹弓不掉弹”的能力，没有改动 Walter 制作书籍的权限。

Current features:
- Wickerbottom does not consume `finiteuses` item durability while using owned inventory or backpack items.
- Wickerbottom does not consume `fueled` durability while using owned inventory or backpack items.
- Wickerbottom does not lose `armor` durability while using equipped armor.
- Wickerbottom restores 15 hunger, 15 sanity, and 15 health every 60 seconds.
- Wickerbottom also receives the base game's life injector max-health penalty recovery every 60 seconds.
- Walter can now use all of Wickerbottom's magic books.
- Walter only pays the sanity cost when reading those books, while the books themselves do not lose uses.
- As long as Walter is carrying any magic book, his Trusty Slingshot does not consume loaded ammo when firing.
- As long as Walter is carrying any magic book, his inventory items, equipped items, and backpack items also stop consuming uses, fueled durability, and armor durability.
- As long as Walter is carrying any magic book, he also gains the same 60-second 15 hunger, 15 sanity, 15 health recovery loop and max-health penalty recovery as Wickerbottom.

Currently covered durability types:
- `finiteuses`: tools, weapons, books, staves, and other use-count based items.
- `fueled`: lanterns, miner hats, and other continuous-consumption items.
- `armor`: condition-based armor items.

Notes:
- This is true no-consumption behavior, not a loop that keeps refilling items to 100%.
- If an item starts at 70% durability, Wickerbottom can keep using it and it will stay at 70%.
- If Walter is carrying a magic book, he can do the same and the item will stay at its original remaining durability.
- The same item will still lose durability normally when used by other characters.
- The implementation hooks durability-related components instead of replacing character brains or stategraphs.
- The life injector effect is applied through the same `DeltaPenalty(TUNING.MAX_HEALING_NORMAL)` path the base game uses for max-health penalty recovery.
- Walter only gains book usage access and book-linked bonuses here. This mod does not grant Walter the ability to craft Wickerbottom's books.
