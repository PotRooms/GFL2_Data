require("UI.BattleIndexPanel.UIBattleDetailDialog")
LennaChallengeItem = class("LennaChallengeItem", UIBaseCtrl)

function LennaChallengeItem:ctor(root)
  self:SetRoot(root)
  self.ui = UIUtils.GetUIBindTable(root)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Root.gameObject, function()
    self:OnClickSelf()
  end)
end

function LennaChallengeItem:SetData(storyData, planId, index)
  self.storyData = storyData
  self.planId = planId
  self.index = index
end

function LennaChallengeItem:SetSelect(select)
  self.ui.mBtn_Root.interactable = not select
end

function LennaChallengeItem:GetIndex()
  return self.index
end

function LennaChallengeItem:Refresh()
  if not self.storyData then
    return
  end
  local stageData = TableDataBase.listStageDatas:GetDataById(self.storyData.stage_id)
  if stageData then
    self.ui.mText_Title.text = stageData.name.str
  end
  self.ui.mText_Num.text = self.storyData.code.str
  local isCompleted = NetCmdThemeData:LevelPassInThemeOpen(self.planId, self.storyData.id)
  setactivewithcheck(self.ui.mTrans_Complete, isCompleted)
end

function LennaChallengeItem:AddBtnClickListener(callback)
  self.onClickCallback = callback
end

function LennaChallengeItem:OnRelease()
  self.onClickCallback = nil
  self.storyData = nil
  self.planId = nil
  self.isUnlock = nil
end

function LennaChallengeItem:OnClickSelf()
  if self.onClickCallback then
    self.onClickCallback(self)
  end
end

function LennaChallengeItem:IsNowProgress(isNow)
  setactivewithcheck(self.ui.mTrans_NowProgress, isNow)
end

function LennaChallengeItem:GetStoryData()
  return self.storyData
end
