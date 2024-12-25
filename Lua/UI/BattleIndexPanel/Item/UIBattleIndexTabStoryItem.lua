require("UI.UIBaseCtrl")
UIBattleIndexTabStoryItem = class("UIBattleIndexTabStoryItem", UIBaseCtrl)
UIBattleIndexTabStoryItem.__index = UIBattleIndexTabStoryItem
UIBattleIndexTabStoryItem.mText_BattleIndexTabStoryItem = nil
UIBattleIndexTabStoryItem.mText_1 = nil
UIBattleIndexTabStoryItem.mText_2 = nil
UIBattleIndexTabStoryItem.mText_Title = nil
UIBattleIndexTabStoryItem.mTrans_RedPoint = nil

function UIBattleIndexTabStoryItem:__InitCtrl()
end

function UIBattleIndexTabStoryItem:InitCtrl(parent)
  local instObj = instantiate(UIUtils.GetGizmosPrefab("BattleIndex/Btn_BattleIndexTabStoryItem.prefab", parent))
  self:InitCtrlWithoutInstance(instObj.transform)
end

function UIBattleIndexTabStoryItem:InitCtrlWithoutInstance(instObj)
  self:SetRoot(instObj.transform)
  self.ui = {}
  self:LuaUIBindTable(self.mUIRoot, self.ui)
  self:__InitCtrl()
  self.ui.mAnimator_State.keepAnimatorControllerStateOnDisable = true
  
  function self.showUnlock()
  end
  
  MessageSys:AddListener(UIEvent.UINewChapterShowFinish, self.showUnlock)
end

function UIBattleIndexTabStoryItem:SetData(data, index)
  self.mIndex = index
  if data ~= nil then
    setactive(self.mUIRoot, true)
    self.mData = data
    self.isUnLock = true
    for i = 0, data.unlock.Count - 1 do
      if not NetCmdAchieveData:CheckComplete(data.unlock[i]) then
        self.isUnLock = false
      end
    end
    local story = TableData.GetFirstStoryByChapterID(data.id)
    self.isNew = not AccountNetCmdHandler:IsWatchedChapter(story.stage_id * 100 + 10)
    self.isNext = self.isUnLock and data.difficulty_type == 1 and 0 < NetCmdDungeonData:UpdateChapterRedPoint(data.id)
    self:UpdateChapterItem()
  else
    setactive(self.mUIRoot, false)
  end
end

function UIBattleIndexTabStoryItem:SetNowProcess(isShow)
  setactive(self.ui.mTrans_NowProgress, isShow)
end

function UIBattleIndexTabStoryItem:GetUnlock()
  return self.isUnLock
end

function UIBattleIndexTabStoryItem:UpdateChapterItem()
  local splitChapterNum = string.split(string.format("%.2f", self.mData.id / 100), ".")
  if #splitChapterNum == 2 then
    local chapterNum = splitChapterNum[2]
    self.ui.mText_1.text = string.format("%02d", chapterNum)
    self.ui.mText_2.text = string.format("%02d", chapterNum)
  end
  self.ui.mText_Text.text = self.mData.name.str
  self.ui.mAnimator_State:SetBool("Bool", not self.isUnLock)
  setactive(self.ui.mTrans_NowProgress, self.isNext)
  setactive(self.ui.mTrans_RedPoint, self.isUnLock and NetCmdDungeonData:IsNeedStoryTabRedPointByDifficultyGroup(self.mData))
  local storyCount = NetCmdDungeonData:GetCanChallengeStoryList(self.mData.id).Count
  local total = storyCount * UIChapterGlobal.MaxChallengeNum
  local stars = NetCmdDungeonData:GetCurStarsByChapterID(self.mData.id)
  setactive(self.ui.mImgFinished, total == stars)
end

function UIBattleIndexTabStoryItem:SetIndexText(index)
  self.ui.mText_Index.text = string.format(string_format(TableData.GetHintById(615), "%02d"), index)
  self.ui.mText_noSel.text = string.format(string_format(TableData.GetHintById(615), "%02d"), index)
end

function UIBattleIndexTabStoryItem:Refresh()
  self:SetData(self.mData)
end

function UIBattleIndexTabStoryItem:OnRelease(isDestroy)
  self:RemoveListener()
  self.super.OnRelease(self, isDestroy)
end

function UIBattleIndexTabStoryItem:RemoveListener()
  MessageSys:RemoveListener(UIEvent.UINewChapterShowFinish, self.showUnlock)
end

function UIBattleIndexTabStoryItem:SetSelectState(id)
  self.ui.mBtn_Root.interactable = self.mData.id ~= id
end

function UIBattleIndexTabStoryItem:SetGlobalTabId(globalTabId)
  self.globalTab = GetOrAddComponent(self:GetRoot().gameObject, (typeof(GlobalTab)))
  self.globalTab:SetGlobalTabId(globalTabId)
end

function UIBattleIndexTabStoryItem:GetGlobalTab()
  return self.globalTab
end
