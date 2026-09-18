-- zh_CN_keyboard.lua — 手机式拼音键盘布局（从零重写，用 phone_ime）
-- QWERTY 26键 + 拼音候选，数字键 1-9 直接选字

local PhoneIME = require("ui/data/keyboardlayouts/phone_ime")
local util = require("util")

-- 复用英文键盘的 QWERTY 键位
local py_keyboard = dofile("frontend/ui/data/keyboardlayouts/en_keyboard.lua")

-- 加载拼音码表
local code_map = dofile("frontend/ui/data/keyboardlayouts/zh_pinyin_data.lua")

-- 输入法实例（单例，wrapInputBox 时创建）
local ime = PhoneIME:new{ code_map = code_map }

-- 包装输入框：拦截按键，交给输入法处理
local function wrapInputBox(inputbox)
    local orig_addChars = inputbox.addChars
    local orig_delChar = inputbox.delChar

    -- 每次打开键盘都重置输入法状态
    ime:clear()

    -- 把输入法实例挂到输入框上，供候选栏读取
    inputbox._phone_ime = ime

    inputbox.addChars = function(self, char)
        local c = char and char:sub(1, 1) or ""
        if c:match("[a-z]") then
            -- 拼音字母：累积到输入法
            ime:addLetter(c)
            ime:notifyUpdate()
        elseif c:match("[1-9]") and ime:hasCandidates() then
            -- 数字键：直接选第 N 个候选并提交
            local sel = ime:selectCandidate(tonumber(c))
            if sel then
                orig_addChars(self, sel)
                ime:clear()
                ime:notifyUpdate()
            end
        elseif c == "0" and ime:hasCandidates() then
            -- 0 键：翻到下一页候选
            ime:nextPage()
            ime:notifyUpdate()
        elseif c == " " then
            -- 空格：提交当前候选（无候选则输入空格）
            local cur = ime:getCurrentChar()
            if cur ~= "" then
                orig_addChars(self, cur)
            else
                orig_addChars(self, " ")
            end
            ime:clear()
            ime:notifyUpdate()
        else
            -- 其他字符（数字、标点等）直接通过
            orig_addChars(self, char)
            ime:clear()
            ime:notifyUpdate()
        end
    end

    inputbox.delChar = function(self)
        if ime:getCode() ~= "" then
            -- 还在拼音态：先删拼音字母
            ime:delLetter()
            ime:notifyUpdate()
        else
            -- 已提交：删真实字符
            orig_delChar(self)
        end
    end

    -- 返回解除包装的函数
    return function()
        inputbox.addChars = orig_addChars
        inputbox.delChar = orig_delChar
        inputbox._phone_ime = nil
    end
end

py_keyboard.wrapInputBox = wrapInputBox
py_keyboard.keys[5][4].label = "空格"

return py_keyboard
