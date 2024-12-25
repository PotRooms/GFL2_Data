require("UI.UIBaseCtrl")
UIActivityStoreBoxItem = class("UIActivityStoreBoxItem", UIBaseCtrl)
UIActivityStoreBoxItem.__index = UIActivityStoreBoxItem

function UIActivityStoreBoxItem:__InitCtrl()
end

function UIActivityStoreBoxItem:InitCtrl(root)
  self.ui = {}
  self:SetRoot(root)
  self:LuaUIBindTable(self.mUIRoot, self.ui)
  self:__InitCtrl()
end

function UIActivityStoreBoxItem:InitData(data, isCurStep)
  self.mData = data
  self.item = UICommonItem:New()
  self.item:InitObj(self.ui.mTrans_Item.gameObject)
  if isCurStep then
    self.ui.mImg_Bg.color = ColorUtils.StringToColor("3E3E3E")
  else
    self.ui.mImg_Bg.color = ColorUtils.StringToColor("212121")
  end
  for id, num in pairs(data.Reward) do
    local boxData = TableData.listCollectionActivityBoxDatas:GetDataById(id)
    if boxData ~= nil then
      self.item:SetIcon(IconUtils.GetItemSprite(boxData.icon))
      self.item:SetEscortScore(num)
      local curExp = NetCmdCounterData:GetCounterCount(35, data.id)
      self.item:SetReceivedIcon(curExp >= data.condition_num)
      self.item:SetLock(curExp < data.condition_num)
      self.item:SetLockColor()
      if id == 1001 then
        self.item.ui.mImage_Rank.color = TableData.GetGlobalGun_Quality_Color2(4)
        self.item.ui.mImage_Rank2.color = TableData.GetGlobalGun_Quality_Color2(4)
      elseif id == 1002 then
        self.item.ui.mImage_Rank.color = TableData.GetGlobalGun_Quality_Color2(5)
        self.item.ui.mImage_Rank2.color = TableData.GetGlobalGun_Quality_Color2(5)
      end
      UIUtils.GetButtonListener(self.item.ui.mBtn_Select).onClick = function()
        UIManager.OpenUIByParam(UIDef.UIActivityStoreOptionalGiftDialog, {canClaim = false, boxData = boxData})
      end
    else
      gferror(id .. ": \229\174\157\231\174\177\232\161\168\230\156\170\230\137\190\229\136\176\229\175\185\229\186\148\230\149\176\230\141\174!")
    end
  end
  self.ui.mText_Num.text = data.condition_num
end

function UIActivityStoreBoxItem:SetData(data)
  self.mData = data
end
