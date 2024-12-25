require("UI.UIBaseCtrl")
LennaMuseItem = class("LennaMuseItem", UIBaseCtrl)
LennaMuseItem.__index = LennaMuseItem
local WhiteColor = CS.GF2.UI.UITool.StringToColor("FFCD6D")

function LennaMuseItem:ctor()
end

function LennaMuseItem:InitCtrl(instObj)
  self:SetRoot(instObj.transform)
  self.ui = {}
  self:LuaUIBindTable(instObj, self.ui)
  if parent then
    UIUtils.AddListItem(instObj.gameObject, parent.gameObject)
    CS.LuaUIUtils.SetParent(instObj.gameObject, parent.gameObject, true)
  end
end

function LennaMuseItem:SetData(data)
  self.ui.mImg_Icon.sprite = IconUtils.GetItemIconSprite(data.id)
  local itemNum = NetCmdItemData:GetItemCount(data.id)
  self.ui.mText_Num.text = itemNum
  if itemNum <= 0 then
    self.ui.mText_Num.color = ColorUtils.RedColor
  else
    self.ui.mText_Num.color = WhiteColor
  end
  UIUtils.GetButtonListener(self.ui.mBtn).onClick = function()
    TipsPanelHelper.OpenUITipsPanel(TableData.GetItemData(data.id))
  end
end
