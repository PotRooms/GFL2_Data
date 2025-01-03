require("UI.UIBaseCtrl")
UIBarrackCommonTabItem = class("UIBarrackCommonTabItem", UIBaseCtrl)
UIBarrackCommonTabItem.__index = UIBarrackCommonTabItem

function UIBarrackCommonTabItem:__InitCtrl()
  self.mBtn_ClickTab = self:GetSelfButton()
end

function UIBarrackCommonTabItem:ctor()
  self.tagId = 0
  self.systemId = 0
  self.isLock = false
  self.hintId = 0
end

function UIBarrackCommonTabItem:InitObj(root)
  self:SetRoot(root)
  self:__InitCtrl()
end

function UIBarrackCommonTabItem:InitCtrl(parent, useScrollListChild)
  local obj
  if useScrollListChild then
    local itemPrefab = parent:GetComponent(typeof(CS.ScrollListChild))
    obj = instantiate(itemPrefab.childItem)
  else
    obj = self:Instantiate("Character/PowerUpListItemV2.prefab", parent)
  end
  if parent then
    CS.LuaUIUtils.SetParent(obj.gameObject, parent.gameObject, false)
  end
  self:SetRoot(obj.transform)
  self:__InitCtrl()
end

function UIBarrackCommonTabItem:__InitCtrl()
  self.mBtn_ClickTab = self:GetSelfButton()
  self.mText_Name = self:GetText("GrpName/Text_Name")
  self.mTrans_RedPoint = self:GetRectTransform("GrpName/Trans_RedPoint/GrpRedPoint")
  self.mTrans_Locked = self:GetRectTransform("Trans_ImgLock")
  self.mTrans_VerticalImage = self:GetRectTransform("Icon")
  self:InstanceUIPrefab("UICommonFramework/ComRedPointItemV2.prefab", self.mTrans_RedPoint, true)
  setactive(self.mTrans_RedPoint, false)
end

function UIBarrackCommonTabItem:SetName(name)
  if name then
    self.mText_Name.text = name
    setactive(self.mText_Name.gameObject, true)
  else
    setactive(self.mText_Name.gameObject, false)
  end
end

function UIBarrackCommonTabItem:SetNameByHint(hintId)
  if hintId then
    self.mText_Name.text = TableData.GetHintById(hintId)
    setactive(self.mText_Name.gameObject, true)
  else
    setactive(self.mText_Name.gameObject, false)
  end
end

function UIBarrackCommonTabItem:SetItemState(isSelect)
  self.mBtn_ClickTab.interactable = not isSelect
end

function UIBarrackCommonTabItem:UpdateSystemLock()
  if self.systemId == 0 or self.systemId == nil then
    self.isLock = false
  else
    self.isLock = not AccountNetCmdHandler:CheckSystemIsUnLock(self.systemId)
  end
  setactive(self.mTrans_Locked, self.isLock)
  setactive(self.mTrans_VerticalImage, not self.isLock)
end

function UIBarrackCommonTabItem:UpdateAchievementLock(achievementId)
  local achieveCmdData = NetCmdAchieveData:GetAchieveCmdData(achievementId)
  setactive(self.mTrans_Locked, not achieveCmdData.IsCompleted)
  setactive(self.mTrans_VerticalImage, achieveCmdData.IsCompleted)
end

function UIBarrackCommonTabItem:SetEnable(enable)
  setactive(self.mUIRoot, enable)
end

function UIBarrackCommonTabItem:SetRedPointEnable(enable)
  setactive(self.mTrans_RedPoint, enable)
end

function UIBarrackCommonTabItem:OnRelease()
  self:DestroySelf()
end
