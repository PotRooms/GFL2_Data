require("UI.UIBaseCtrl")
CardDisplayItem = class("CardDisplayItem", UIBaseCtrl)
CardDisplayItem.__index = CardDisplayItem
CardDisplayItem.mImage_Glow = nil
CardDisplayItem.mCharacter_Image_FigureDrawing = nil
CardDisplayItem.mWeapon_Image_FigureDrawing = nil
CardDisplayItem.mImage_Attribute = nil
CardDisplayItem.mTrans_Again = nil
CardDisplayItem.mTrans_New = nil
CardDisplayItem.mTrans_Star1 = nil
CardDisplayItem.mTrans_Star2 = nil
CardDisplayItem.mTrans_Star3 = nil
CardDisplayItem.mTrans_Star4 = nil
CardDisplayItem.mTrans_Star5 = nil
CardDisplayItem.mTrans_Star6 = nil

function CardDisplayItem:__InitCtrl()
  self.mImage_Glow = self:GetImage("Image_Glow")
  self.mCharacter_Image_FigureDrawing = self:GetRawImage("CardBg/Trans_Character/ImgFigureDrawing/CharacterMask/Image_FigureDrawing")
  self.mWeapon_Image_FigureDrawing = self:GetRawImage("CardBg/Trans_Weapon/ImgFigureDrawing/CharacterMask/Image_Weapon")
  self.mImage_Attribute = self:GetImage("DetailPanel/Trans_New/GrpElement/Image_ElementIcon")
  self.mTrans_Again = self:GetRectTransform("DetailPanel/Trans_Again")
  self.mTrans_New = self:GetRectTransform("DetailPanel/Trans_New")
  self.mTrans_Star1 = self:GetRectTransform("DetailPanel/Trans_New/GrpStar/Trans_Star1")
  self.mTrans_Star2 = self:GetRectTransform("DetailPanel/Trans_New/GrpStar/Trans_Star2")
  self.mTrans_Star3 = self:GetRectTransform("DetailPanel/Trans_New/GrpStar/Trans_Star3")
  self.mTrans_Star4 = self:GetRectTransform("DetailPanel/Trans_New/GrpStar/Trans_Star4")
  self.mTrans_Star5 = self:GetRectTransform("DetailPanel/Trans_New/GrpStar/Trans_Star5")
end

CardDisplayItem.mStartList = nil
CardDisplayItem.mTrans_Weapon = nil
CardDisplayItem.mTrans_Character = nil
CardDisplayItem.mImage_ElementBg = nil
CardDisplayItem.mTrans_NewTag = nil
CardDisplayItem.mTrans_CardEffect = nil

function CardDisplayItem:InitCtrl(root)
  self:SetRoot(root)
  self:__InitCtrl()
  self.mTrans_Character = self:GetRectTransform("CardBg/Trans_Character")
  self.mTrans_Weapon = self:GetRectTransform("CardBg/Trans_Weapon")
  self.mImage_ElementBg = self:GetImage("DetailPanel/Trans_New/GrpElement/Image_ElementBg")
  self.mTrans_NewTag = self:GetRectTransform("DetailPanel/Trans_NewTag")
  self.mTrans_CardEffect = self:GetRectTransform("CardEffect")
  self.mStartList = {
    self.mTrans_Star1,
    self.mTrans_Star2,
    self.mTrans_Star3,
    self.mTrans_Star4,
    self.mTrans_Star5
  }
  for i = 1, #self.mStartList do
    setactive(self.mStartList[i], false)
  end
end

function CardDisplayItem:InitData(data)
  self.mData = data
  self.mStcData = TableData.GetItemData(data.ItemId)
  if self.mStcData == nil then
    gferror("\230\178\161\230\156\137\230\137\190\229\136\176id\230\152\175" .. data.ItemId .. "\231\154\132\233\129\147\229\133\183")
  else
    self:InitItemInfo()
  end
end

function CardDisplayItem:InitItemInfo()
  local name = self.mStcData.name
  local icon = self.mStcData.icon
  local rank = self.mStcData.rank
  if self.mStcData.type == 1 then
    local gunData = TableData.GetGunData(1001)
    self.mCharacter_Image_FigureDrawing.texture = UIUtils.GetIconTexture("CharacterRes/" .. gunData.code, "Gacha")
    setactive(self.mTrans_Character, true)
    setactive(self.mTrans_Weapon, false)
  elseif self.mStcData.type == 4 then
    local gunData = TableData.GetGunData(tonumber(self.mStcData.args[0]))
    self.mCharacter_Image_FigureDrawing.texture = UIUtils.GetIconTexture("CharacterRes/" .. gunData.code, "Gacha")
    setactive(self.mTrans_Character, true)
    setactive(self.mTrans_Weapon, false)
  elseif self.mStcData.type == 3 then
    self.mWeapon_Image_FigureDrawing.texture = UIUtils.GetIconTexture("Icon/" .. self.mStcData.IconPath, icon)
    setactive(self.mTrans_Character, false)
    setactive(self.mTrans_Weapon, true)
  elseif self.mStcData.type == 8 then
    self.mWeapon_Image_FigureDrawing.texture = UIUtils.GetIconTexture("Icon/" .. self.mStcData.IconPath, icon)
    setactive(self.mTrans_Character, false)
    setactive(self.mTrans_Weapon, true)
  elseif self.mStcData.type == 5 then
    self.mWeapon_Image_FigureDrawing.texture = UIUtils.GetIconTexture("Icon/" .. self.mStcData.IconPath, icon)
    setactive(self.mTrans_Character, false)
    setactive(self.mTrans_Weapon, true)
  elseif self.mStcData.type == 12 then
    local gunData = TableData.GetGunData(tonumber(self.mStcData.args[0]))
    self.mCharacter_Image_FigureDrawing.texture = UIUtils.GetIconTexture("CharacterRes/" .. gunData.code, "Gacha")
    setactive(self.mTrans_Character, true)
    setactive(self.mTrans_Weapon, false)
  end
  local rankColor = TableData.GetGlobalGun_Quality_Color2(rank)
  self.mImage_Glow.color = Color(rankColor.r, rankColor.g, rankColor.b, 0)
  for i = 1, #self.mStartList do
    setactive(self.mStartList[i], false)
  end
  if 6 <= rank then
    rank = 5
  end
  for i = 1, rank do
    setactive(self.mStartList[i], true)
  end
  local prefab = ResSys:GetUIRes("Gashapon/Effect/Card_Effect0" .. rank .. ".prefab", false)
  local effectObj = instantiate(prefab)
  effectObj.transform:SetParent(self.mTrans_CardEffect, false)
  effectObj.transform.localPosition = Vector3(0, 0, -2)
  ResourceManager:UnloadAssetFromLua(prefab)
  self:ConvertChipAnim()
end

CardDisplayItem.mPath_UICommonItemS = "UICommonFramework/UICommonItemS.prefab"

function CardDisplayItem:ConvertChipAnim()
  if self.mData.ItemNum == 0 then
    setactive(self.mTrans_Again, true)
    setactive(self.mTrans_New, false)
    local prefab = UIUtils.GetGizmosPrefab(self.mPath_UICommonItemS, self)
    local sort = self.mData.ExtItems.orderBy
    for key, value in pairs(self.mData.ExtItems) do
      if key <= 100 then
        local consumeItem = UICommonItemS.New()
        local instItem = instantiate(prefab)
        consumeItem:InitCtrl(instItem.transform)
        consumeItem:InitData(key, value, false)
        UIUtils.AddListItem(instItem, self.mTrans_Again.gameObject)
      end
    end
    for key, value in pairs(self.mData.ExtItems) do
      if 100 < key then
        local consumeItem = UICommonItemS.New()
        local instItem = instantiate(prefab)
        consumeItem:InitCtrl(instItem.transform)
        consumeItem:InitData(key, value, false)
        UIUtils.AddListItem(instItem, self.mTrans_Again.gameObject)
      end
    end
  else
    setactive(self.mTrans_Again, false)
    setactive(self.mTrans_New, true)
    local id = self.mStcData.Args[0]
    if self.mStcData.type ~= 8 then
      local gunData = TableData.listGunDatas:GetDataById(id)
      local elementData = TableData.listLanguageElementDatas:GetDataById(gunData.element)
      self.mImage_Attribute.sprite = IconUtils.GetElementIcon(elementData.icon .. "_M")
      self.mImage_ElementBg.color = ColorUtils.StringToColor(elementData.color)
      setactive(self.mTrans_NewTag, true)
    else
      local weaponData = TableData.listGunWeaponDatas:GetDataById(id)
      local elementData = TableData.listLanguageElementDatas:GetDataById(weaponData.element)
      self.mImage_Attribute.sprite = IconUtils.GetElementIcon(elementData.icon .. "_M")
      self.mImage_ElementBg.color = ColorUtils.StringToColor(elementData.color)
      setactive(self.mTrans_NewTag, false)
    end
  end
end

function CardDisplayItem:SetIndex(index)
  self.mIndex = index
end
