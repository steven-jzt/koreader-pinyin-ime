-- phone_ime.lua — 手机式拼音输入法引擎（纯逻辑，无 UI）
-- 从零重写，不依赖 KOReader 自带的 generic_ime
-- 复用 zh_pinyin_data.lua 的拼音→候选字码表（纯数据，非逻辑）

local PhoneIME = {
    -- 必填：拼音码表，形如 { ba = {"吧","把","八",...}, bai = {...}, ... }
    code_map = nil,
    -- 数字键（用于直接选候选）
    number_keys = "123456789",
    -- 每页显示的候选数（上限，实际有几个显示几个）
    page_size = 9,
    -- 模糊音（z/zh、c/ch、s/sh 自动容错）
    fuzzy = true,
}

function PhoneIME:new(o)
    local obj = o or {}
    setmetatable(obj, self)
    self.__index = self
    obj:init()
    return obj
end

function PhoneIME:init()
    self:clear()
    -- 预排序所有拼音码，供前缀二分查找
    self.sorted_codes = {}
    for k in pairs(self.code_map) do
        table.insert(self.sorted_codes, k)
    end
    table.sort(self.sorted_codes)
end

function PhoneIME:clear()
    self.code = ""          -- 当前累积的拼音字母
    self.candidates = {}    -- 当前候选字列表
    self.index = 1          -- 当前选中的候选序号
    self.page = 1           -- 当前候选页
end

-- 二分查找第一个以 prefix 开头的拼音码，返回下标（无则 nil）
local function prefix_lower_bound(sorted, prefix)
    local lo, hi = 1, #sorted
    while lo <= hi do
        local mid = math.floor((lo + hi) / 2)
        if sorted[mid]:sub(1, #prefix) < prefix then
            lo = mid + 1
        else
            hi = mid - 1
        end
    end
    if lo <= #sorted and sorted[lo]:sub(1, #prefix) == prefix then
        return lo
    end
    return nil
end

-- 模糊音规则（平舌/翘舌）
local fuzzy_pairs = {
    { short = "z", long = "zh" },
    { short = "c", long = "ch" },
    { short = "s", long = "sh" },
}

-- 生成一个码的模糊音变体
function PhoneIME:fuzzyVariants(code)
    local variants = {}
    for _, p in ipairs(fuzzy_pairs) do
        -- 翘舌 → 平舌（zh → z）
        local v1 = code:gsub(p.long, p.short)
        if v1 ~= code then
            table.insert(variants, v1)
        end
        -- 平舌 → 翘舌（z → zh，只对「z 后不跟 h」的位置）
        local v2 = code:gsub(p.short .. "([^h])", p.long .. "%1")
        if code:sub(-1) == p.short then
            v2 = v2:sub(1, -2) .. p.long
        end
        if v2 ~= code then
            table.insert(variants, v2)
        end
    end
    return variants
end

-- 查候选：先精确匹配，匹配不到再前缀匹配（支持部分拼音）
-- 注意：码表里单字拼音是「字符串」值（如 fiao="覅"），要包成表
function PhoneIME:lookup(code)
    if code == "" then
        return nil -- 空码：无候选
    end
    local result = {}
    local seen = {}
    local function add(candi)
        if type(candi) == "string" then
            candi = { candi }
        end
        for _, c in ipairs(candi or {}) do
            if not seen[c] then
                seen[c] = true
                table.insert(result, c)
            end
        end
    end
    -- 精确匹配
    add(self.code_map[code])
    -- 模糊音变体
    if self.fuzzy then
        for _, v in ipairs(self:fuzzyVariants(code)) do
            add(self.code_map[v])
        end
    end
    -- 前缀匹配（无精确/模糊结果时才用，支持部分拼音）
    if #result == 0 then
        local idx = prefix_lower_bound(self.sorted_codes, code)
        if idx then
            add(self.code_map[self.sorted_codes[idx]])
        end
    end
    return #result > 0 and result or nil
end

-- 输入一个拼音字母，返回更新后的候选列表
function PhoneIME:addLetter(char)
    self.code = self.code .. char
    self.candidates = self:lookup(self.code) or {}
    self.index = 1
    self.page = 1
    return self.candidates
end

-- 删除最后一个拼音字母，返回更新后的候选列表
function PhoneIME:delLetter()
    if #self.code > 0 then
        self.code = self.code:sub(1, -2)
        self.candidates = self:lookup(self.code) or {}
        self.index = 1
        self.page = 1
    end
    return self.candidates
end

-- 当前页第一个候选字（空格提交用）
function PhoneIME:getCurrentChar()
    local first = (self.page - 1) * self.page_size + 1
    return self.candidates[first] or ""
end

-- 选中当前页的第 n 个候选（n 为 1..page_size），返回该字
function PhoneIME:selectCandidate(n)
    local abs = (self.page - 1) * self.page_size + n
    if self.candidates[abs] then
        self.index = abs
        return self.candidates[abs]
    end
    return nil
end

-- 当前页的可见候选列表
function PhoneIME:getVisibleCandidates()
    local start = (self.page - 1) * self.page_size + 1
    local visible = {}
    for i = start, math.min(start + self.page_size - 1, #self.candidates) do
        table.insert(visible, self.candidates[i])
    end
    return visible
end

-- 翻页
function PhoneIME:hasNextPage()
    return (self.page - 1) * self.page_size + self.page_size < #self.candidates
end

function PhoneIME:nextPage()
    if self:hasNextPage() then
        self.page = self.page + 1
    end
end

function PhoneIME:hasPrevPage()
    return self.page > 1
end

function PhoneIME:prevPage()
    if self:hasPrevPage() then
        self.page = self.page - 1
    end
end

-- 是否有候选
function PhoneIME:hasCandidates()
    return #self.candidates > 0
end

-- 当前拼音码（供调试/显示）
function PhoneIME:getCode()
    return self.code
end

-- 候选变化时触发（键盘的候选栏靠它刷新）
function PhoneIME:setUpdateCallback(cb)
    self.on_update = cb
end

function PhoneIME:notifyUpdate()
    if self.on_update then
        self.on_update(self:getVisibleCandidates(), self.index, self.code)
    end
end

return PhoneIME
