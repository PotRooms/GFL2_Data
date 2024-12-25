require("UI.BattleIndexPanel.UIBattleDetailDialog")
UIActivityCafeChallengeItem = class("UIActivityCafeChallengeItem", UIBaseCtrl)

function UIActivityCafeChallengeItem:ctor(root)
  self:SetRoot(root)
  self.ui = UIUtils.GetUIBindTable(root)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Root.gameObject, function()
    self:OnClickSelf()
  end)
end

function UIActivityCafeChallengeItem:SetData(storyData, planId, index)
  self.storyData = storyData
  self.planId = planId
  self.index = index
end

function UIActivityCafeChallengeItem:Refresh()
  if not self.storyData then
    return
  end
  local stageData = TableDataBase.listStageDatas:GetDataById(self.storyData.stage_id)
  if stageData then
    self.ui.mText_Title.text = stageData.name.str
  end
  self.ui.mText_Num.text = self.storyData.name.str
  local isCompleted = NetCmdThemeData:LevelPassInThemeOpen(self.planId, self.storyData.id)
  setactivewithcheck(self.ui.mTrans_Complete, isCompleted)
  local isUnlock = NetCmdThemeData:LevelIsUnLock(self.storyData.id) and AccountNetCmdHandler:GetLevel() >= self.storyData.unlock_level
  setactivewithcheck(self.ui.mTrans_Locked, not isUnlock)
end

function UIActivityCafeChallengeItem:AddBtnClickListener(callback)
  self.onClickCallback = callback
end

function UIActivityCafeChallengeItem:OnRelease()
  self.onClickCallback = nil
  self.index = nil
  self.storyData = nil
  self.planId = nil
  self.isUnlock = nil
end

function UIActivityCafeChallengeItem:SetSelect(isSelect)
  self.ui.mBtn_Root.interactable = not isSelect
end

function UIActivityCafeChallengeItem:GetIndex()
  return self.index
end

function UIActivityCafeChallengeItem:OnClickSelf()
  if self.onClickCallback then
    self.onClickCallback(self)
  end
end

function UIActivityCafeChallengeItem:IsNowProgress(isNow)
  setactivewithcheck(self.ui.mTrans_NowProgress, isNow)
end

function UIActivityCafeChallengeItem:GetStoryData()
  return self.storyData
end
