-- ============================================================
-- MỞ RỘNG: TỰ ĐỘNG LẤY THÔNG TIN PERM FRUIT TỪ UI GAME
-- ============================================================

-- ============================================================
-- 1. LẤY DANH SÁCH PERM FRUIT TỪ UI SHOP
-- ============================================================

local function getPermFruitsFromUI()
    local fruits = {}
    
    -- Tìm shop UI
    local shopGui = playerGui:FindFirstChild("Shop") or
                    playerGui:FindFirstChild("Store") or
                    playerGui:FindFirstChild("Dealer")
    
    if not shopGui then return fruits end
    
    -- Tìm tất cả các frame chứa thông tin fruit
    for _, frame in ipairs(shopGui:GetDescendants()) do
        if frame:IsA("Frame") or frame:IsA("ImageButton") then
            local name = ""
            local price = 0
            local image = ""
            local isPerm = false
            
            -- Duyệt con cháu để lấy thông tin
            for _, child in ipairs(frame:GetDescendants()) do
                -- Lấy tên
                if child:IsA("TextLabel") and child.Text and child.Text ~= "" then
                    local text = child.Text
                    -- Kiểm tra nếu là tên fruit (không chứa từ khóa shop)
                    if not text:lower():find("buy") and 
                       not text:lower():find("gift") and
                       not text:lower():find("robux") and
                       not text:lower():find("shop") and
                       not text:lower():find("back") and
                       not text:lower():find("permanent") then
                        name = text
                    end
                end
                
                -- Lấy giá
                if child:IsA("TextLabel") or child:IsA("TextButton") then
                    local text = child.Text or ""
                    local num = text:gsub("[^%d]", "")
                    if num and tonumber(num) and tonumber(num) > 0 then
                        price = tonumber(num)
                    end
                end
                
                -- Lấy ảnh (nếu có)
                if child:IsA("ImageLabel") and child.Image and child.Image ~= "" then
                    if not child.Image:find("robux") and not child.Image:find("icon") then
                        image = child.Image
                    end
                end
                
                -- Kiểm tra có phải Perm không
                if child:IsA("TextLabel") and child.Text and child.Text:lower():find("permanent") then
                    isPerm = true
                end
            end
            
            -- Nếu có đủ thông tin, thêm vào danh sách
            if name ~= "" and price > 0 then
                table.insert(fruits, {
                    name = name,
                    price = price,
                    image = image,
                    isPerm = isPerm or true  -- Mặc định là Perm
                })
            end
        end
    end
    
    return fruits
end

-- ============================================================
-- 2. LẤY THÔNG TIN FRUIT TỪ NÚT BẤM (BUTTON)
-- ============================================================

local function getFruitInfoFromButton(button)
    if not button then return nil end
    
    local name = ""
    local price = 0
    local image = ""
    
    -- Tìm trong parent và siblings
    local parent = button.Parent
    while parent do
        -- Duyệt tất cả con của parent
        for _, child in ipairs(parent:GetChildren()) do
            -- Lấy tên (TextLabel không phải nút)
            if child:IsA("TextLabel") and child.Text and child.Text ~= "" then
                local text = child.Text
                if not text:lower():find("buy") and 
                   not text:lower():find("gift") and
                   not text:lower():find("robux") and
                   not text:lower():find("shop") and
                   not text:lower():find("back") and
                   not text:lower():find("permanent") then
                    name = text
                end
            end
            
            -- Lấy giá
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                local text = child.Text or ""
                local num = text:gsub("[^%d]", "")
                if num and tonumber(num) and tonumber(num) > 0 then
                    price = tonumber(num)
                end
            end
            
            -- Lấy ảnh
            if child:IsA("ImageLabel") and child.Image and child.Image ~= "" then
                if not child.Image:find("robux") and not child.Image:find("icon") then
                    image = child.Image
                end
            end
        end
        
        -- Nếu đã có đủ thông tin thì dừng
        if name ~= "" and price > 0 then
            break
        end
        
        parent = parent.Parent
    end
    
    if name ~= "" and price > 0 then
        return {
            name = name,
            price = price,
            image = image,
            isPerm = true
        }
    end
    
    return nil
end

-- ============================================================
-- 3. LẤY THÔNG TIN TỪ PRODUCT STRING (NHƯ SCRIPT GỐC)
-- ============================================================

local function resolveProduct(productString)
    local original = tostring(productString)
    local out = { 
        name = "Item", 
        price = Config.Robux, 
        image = Config.DefaultImage, 
        isGift = false, 
        productString = original 
    }

    -- Kiểm tra nếu là quà tặng
    if original:find(":Gift", 1, true) or original:match("^Gift:") then 
        out.isGift = true 
    end

    -- Lấy thông tin thật từ game (nếu bật)
    local infoImg, infoPrice
    local info = realProductInfo(original)
    if info then
        if type(info.PriceInRobux) == "number" then 
            infoPrice = info.PriceInRobux 
        end
        if Config.UseRealProductInfo then 
            infoImg = infoImage(info) 
        end
    end

    -- Xóa hậu tố :Gift để lấy tên gốc
    local s = original:gsub(":Gift$", "")
    local baseName, qty, img, price

    -- Xử lý Perm Fruit từ Blox Fruits
    local permFruit = s:match("^Perm:(.+)$") or s:match("^Permanent:(.+)$")
    if permFruit then
        -- Tìm trong danh sách Perm Fruit từ UI
        local allFruits = getPermFruitsFromUI()
        for _, fruit in ipairs(allFruits) do
            if fruit.name:lower() == permFruit:lower() then
                baseName = fruit.name
                price = fruit.price
                img = fruit.image
                break
            end
        end
        
        -- Nếu không tìm thấy, dùng fallback
        if not baseName then
            baseName = permFruit
            price = realProductPrice(s) or Config.Robux
        end
    else
        -- Xử lý các loại sản phẩm khác (giữ nguyên từ script gốc)
        local gpGiftName = s:match("^Gift:(.+):1$")
        if gpGiftName then
            local key = gamepassByName[gpGiftName]
            if key then
                local gp = resolveGamepass(key)
                baseName, price, img = gp.name, gp.price, gp.image
            elseif gearByName[gpGiftName] then
                baseName = gpGiftName
                price = realProductPrice(("Gear:%s:1"):format(gpGiftName))
                img = gearByName[gpGiftName].IMG
            else
                baseName = gpGiftName
            end
        else
            -- Currency (Sheckles)
            local amount = s:match("^Currency:Sheckles:(%d+)")
            if amount then
                baseName = ("%s Sheckles"):format(formatCommas(tonumber(amount)))
                price = realProductPrice(("Currency:Sheckles:%s"):format(amount))
                if RobuxShopContent and RobuxShopContent.Sheckles then
                    for _, e in pairs(RobuxShopContent.Sheckles) do
                        if tostring(e.Amount) == amount and e.Image then 
                            img = e.Image 
                            break 
                        end
                    end
                end
            else
                -- Seed Pack
                local packCapture = s:match("^SeedPack:(.+)$")
                if packCapture then
                    local packName, packQty = splitQty(packCapture)
                    baseName, qty = packName, packQty
                    price = realProductPrice(s) or realProductPrice(("SeedPack:%s"):format(packName))
                    if SeedPackData and SeedPackData.GetData then
                        local d = SeedPackData.GetData(packName)
                        if d then
                            baseName = d.DisplayName or packName
                            if d.IMG and d.IMG ~= "" then
                                img = d.IMG
                            elseif d.Seeds and d.Seeds[1] then
                                img = seedImage(d.Seeds[1].SeedName)
                            end
                        end
                    end
                else
                    -- Seed
                    local seedName = s:match("^Seed:(.+)$")
                    if seedName then
                        local sb, sq = splitQty(seedName)
                        baseName = ("%s Seed"):format(sb)
                        qty = sq
                        price = realProductPrice(s)
                        img = seedImage(sb)
                    elseif s:match("StarterPack") then
                        baseName = "Starter Pack"
                        price = realProductPrice("Standalone:StarterPack:1")
                    else
                        -- Generic product
                        local prefix, rest = s:match("^([^:]+):(.+)$")
                        if prefix and rest then
                            local itemName, genQty = splitQty(rest)
                            baseName, qty = itemName, genQty
                            price = realProductPrice(s) or realProductPrice(("%s:%s:1"):format(prefix, itemName))
                            img = resolveImageByName(itemName)
                        else
                            local fbBase, fbQty = splitQty((s:gsub("^%w+:", "")))
                            baseName, qty = fbBase, fbQty
                            price = realProductPrice(s)
                            img = resolveImageByName(fbBase)
                        end
                    end
                end
            end
        end
    end

    -- Gán kết quả vào output
    out.name      = formatItemName(baseName, qty, out.isGift)
    out.cleanName = formatItemName(baseName, qty, false)
    if infoImg and infoImg ~= "" then 
        out.image = infoImg 
    elseif img and img ~= "" then 
        out.image = img 
    end
    out.price = infoPrice or price or out.price
    out.isPerm = true  -- Đánh dấu là Perm Fruit
    
    return out
end

-- ============================================================
-- 4. LẤY THÔNG TIN TỪ UI GIFT (NOTIFICATION)
-- ============================================================

local function getGiftInfoFromUI()
    local gifting = playerGui:FindFirstChild("Gifting")
    if not gifting then return nil end
    
    local notification = gifting:FindFirstChild("Notification")
    if not notification then return nil end
    
    local info = {
        name = "",
        price = 0,
        image = "",
        target = ""
    }
    
    -- Lấy tên từ TextLabel
    local tl = notification:FindFirstChild("TextLabel")
    if tl and tl.Text then
        -- Parse tên từ "@player gifted: ItemName"
        local match = tl.Text:match("gifted:%s*(.+)$")
        if match then
            info.name = match
        end
    end
    
    -- Lấy tên từ Reward
    local reward = notification:FindFirstChild("Reward")
    if reward then
        if reward:IsA("TextLabel") or reward:IsA("TextButton") then
            info.name = reward.Text or info.name
        end
        local rtl = reward:FindFirstChild("TextLabel")
        if rtl then
            info.name = rtl.Text or info.name
        end
    end
    
    -- Lấy ảnh từ Icon
    local icon = notification:FindFirstChild("Icon")
    if icon and icon:IsA("ImageLabel") then
        info.image = icon.Image
    end
    
    return info
end

-- ============================================================
-- 5. HÀM HIỂN THỊ POPUP VỚI THÔNG TIN TỰ ĐỘNG
-- ============================================================

local function showAutoGiftPopup(productString)
    -- Lấy thông tin sản phẩm tự động
    local productInfo = resolveProduct(productString)
    if not productInfo then
        print("❌ Không thể lấy thông tin sản phẩm")
        return
    end
    
    -- Hiển thị popup với thông tin đã lấy
    showPrompt({
        name = productInfo.name,
        cleanName = productInfo.cleanName,
        price = productInfo.price,
        image = productInfo.image,
        isGift = productInfo.isGift,
        title = productInfo.isPerm and "Perm Fruit" or "Item"
    })
end

-- ============================================================
-- 6. HOOK VÀO UI SHOP ĐỂ TỰ ĐỘNG LẤY THÔNG TIN
-- ============================================================

local function hookShopForAutoInfo()
    local shopGui = playerGui:FindFirstChild("Shop") or
                    playerGui:FindFirstChild("Store") or
                    playerGui:FindFirstChild("Dealer")
    
    if not shopGui then return end
    
    -- Tìm tất cả nút Gift
    for _, btn in ipairs(shopGui:GetDescendants()) do
        if btn:IsA("TextButton") or btn:IsA("ImageButton") then
            local text = btn.Text or ""
            local name = btn.Name or ""
            
            if text:lower():find("gift") or name:lower():find("gift") then
                -- Lấy thông tin fruit từ UI
                local fruitInfo = getFruitInfoFromButton(btn)
                if fruitInfo then
                    -- Lưu thông tin vào button
                    btn:SetAttribute("FruitName", fruitInfo.name)
                    btn:SetAttribute("FruitPrice", fruitInfo.price)
                    btn:SetAttribute("FruitImage", fruitInfo.image or "")
                    
                    print("📌 Đã lấy thông tin: " .. fruitInfo.name .. " (" .. fruitInfo.price .. " Robux)")
                end
            end
        end
    end
end

-- ============================================================
-- 7. KHỞI ĐỘNG TỰ ĐỘNG LẤY THÔNG TIN
-- ============================================================

-- Chạy khi game load
task.spawn(function()
    task.wait(5)  -- Đợi UI load
    hookShopForAutoInfo()
    print("✅ Đã quét và lấy thông tin Perm Fruit từ UI")
end)

-- ============================================================
-- 8. EXPORT CÁC HÀM
-- ============================================================

return {
    -- Hàm lấy thông tin
    getPermFruitsFromUI = getPermFruitsFromUI,
    getFruitInfoFromButton = getFruitInfoFromButton,
    resolveProduct = resolveProduct,
    getGiftInfoFromUI = getGiftInfoFromUI,
    
    -- Hàm hiển thị
    showAutoGiftPopup = showAutoGiftPopup,
    
    -- Hàm hook
    hookShopForAutoInfo = hookShopForAutoInfo,
}