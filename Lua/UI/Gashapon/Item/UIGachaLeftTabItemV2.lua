require("UI.UIBaseCtrl")
UIGachaLeftTabItemV2 = class("UIGachaLeftTabItemV2", UIBaseCtrl)
UIGachaLeftTabItemV2.__index = UIGachaLeftTabItemV2
UIGachaLeftTabItemV2.mImg_Icon = nil

function UIGachaLeftTabItemV2:__InitCtrl()
  self.mImg_Icon = self:GetImage("Root/GrpDeco/Img_Deco")
  self.mTrans_Redpoint = self:GetRectTransform("Root/Trans_RedPoint")
  self.mBtn_GachaEventBtn = self:GetButton("Root")
end

function UIGachaLeftTabItemV2:InitCtrl(parent)
  local obj = instantiate(UIUtils.GetGizmosPrefab("Gashapon/GashaponMainLeftTabItem.prefab", self))
  if parent then
    CS.LuaUIUtils.SetParent(obj.gameObject, parent.gameObject, false)
  end
  self:SetRoot(obj.transform)
  self:__InitCtrl()
end

function UIGachaLeftTabItemV2:SetData(data)
  self.globalTab = GetOrAddComponent(self:GetRoot().gameObject, typeof(GlobalTab))
  self.globalTab:SetGlobalTabId(data.StcData.GlobalTab)
  setactive(self.mImg_Icon, false)
  IconUtils.GetAtlasSpriteAsyc("GashaponPic/" .. data.StcData.gacha_pic, function(s, o, arg)
    if o then
      self.mImg_Icon.sprite = o
    end
    setactive(self.mImg_Icon, true)
  end)
  self.mEventData = data
  self:UpdateRedPoint()
end

function UIGachaLeftTabItemV2:GetGlobalTab()
  return self.globalTab
end

function UIGachaLeftTabItemV2:UpdateRedPoint()
  setactive(self.mTrans_Redpoint, false)
end

function UIGachaLeftTabItemV2:SetSelect(isSelect)
  self.mBtn_GachaEventBtn.interactable = not isSelect
end
