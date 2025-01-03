require("UI.FacilityBarrackPanel.UIChrTalent.UIPropertyCtrl")
UIChrTalentExtraRewardLevelUpDialog = class("UIChrTalentExtraRewardLevelUpDialog", UIBasePanel)

function UIChrTalentExtraRewardLevelUpDialog:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function UIChrTalentExtraRewardLevelUpDialog:OnAwake(root)
  self.ui = UIUtils.GetUIBindTable(root)
  self:SetRoot(root.transform)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Close.gameObject, function()
    self:onClickClose()
  end)
  self.itemViewTable = {}
end

function UIChrTalentExtraRewardLevelUpDialog:OnInit(root, param)
  self.gunId = param.GunId
  self.onClickCloseCallback = param.OnClickCloseCallback
end

function UIChrTalentExtraRewardLevelUpDialog:OnShowStart()
  local animLength = LuaUtils.GetAnimationClipLength(self.ui.mAnimator, "FadeIn")
  self.ui.mBtn_Close.interactable = false
  self.timer = TimerSys:DelayCall(animLength, function()
    self.ui.mBtn_Close.interactable = true
  end)
  self:refresh()
end

function UIChrTalentExtraRewardLevelUpDialog:OnHide()
end

function UIChrTalentExtraRewardLevelUpDialog:OnClose()
  if self.timer then
    self.timer:Stop()
    self.timer = nil
  end
  self:ReleaseCtrlTable(self.itemViewTable, true)
end

function UIChrTalentExtraRewardLevelUpDialog:OnRelease()
  self.gunId = nil
  self.groupId = nil
  self.itemViewTable = nil
  self.ui = nil
  self.super.OnRelease(self)
end

function UIChrTalentExtraRewardLevelUpDialog:refresh()
  for i, item in ipairs(self.itemViewTable) do
    item:SetVisible(false)
  end
  local prevBonusGroupData = NetCmdTalentData:GetPrevBonusGroupData(self.gunId)
  local curBonusGroupData = NetCmdTalentData:GetCurBonusGroupData(self.gunId)
  if not curBonusGroupData then
    gferror("curBonusGroupData is null")
    return
  end
  local prevPropertyId = 0
  if prevBonusGroupData == nil then
    self.ui.mText_NumBefore.text = "-"
    self.ui.mText_NumAfter.text = tostring(curBonusGroupData.id)
  else
    prevPropertyId = prevBonusGroupData.PropertyId
    self.ui.mText_NumBefore.text = tostring(prevBonusGroupData.id)
    self.ui.mText_NumAfter.text = tostring(curBonusGroupData.id)
  end
  local curPropertyId = curBonusGroupData.PropertyId
  local startPropertyId = LuaUtils.EnumToInt(DevelopProperty.None)
  local endPropertyId = LuaUtils.EnumToInt(DevelopProperty.AllEnd)
  local itemIndex = 1
  for i = startPropertyId + 1, endPropertyId - 1 do
    local propertyType = DevelopProperty.__CastFrom(i)
    if propertyType then
      local prevValue = PropertyHelper.GetPropertyValueByEnum(prevPropertyId, propertyType)
      local curValue = PropertyHelper.GetPropertyValueByEnum(curPropertyId, propertyType)
      local delta = curValue - prevValue
      if 0 < delta then
        local template = self.ui.mScrollListChild_Content.childItem
        local parent = self.ui.mScrollListChild_Content.transform
        local root = instantiate(template, parent)
        local item = UIPropertyCtrl.New()
        item:InitRoot(root)
        item:ShowDiff(propertyType, prevValue, curValue, itemIndex)
        item:SetVisible(true)
        itemIndex = itemIndex + 1
        table.insert(self.itemViewTable, item)
      end
    end
  end
end

function UIChrTalentExtraRewardLevelUpDialog:onClickClose()
  UISystem:CloseUI(self.mCSPanel)
  if self.onClickCloseCallback then
    self.onClickCloseCallback()
  end
end
