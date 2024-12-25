require("UI.UIBaseCtrl")
require("UI.BattleIndexPanel.Btn_BattleIndexBranchItem")
UIBattleIndexBranchStorySubPanel = class("UIBattleIndexBranchStorySubPanel", UIBaseView)
UIBattleIndexBranchStorySubPanel.__index = UIBattleIndexBranchStorySubPanel
UIBattleIndexBranchStorySubPanel.leftTabUIList = {}
UIBattleIndexBranchStorySubPanel.rightItemUIList = {}

function UIBattleIndexBranchStorySubPanel:ctor(csPanel)
  UIBattleIndexBranchStorySubPanel.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function UIBattleIndexBranchStorySubPanel:InitCtrl(root, pageIndex, isLock)
  self.ui = {}
  self:SetRoot(root)
  self:LuaUIBindTable(root, self.ui)
  self.currSelectIndex = -1
  self.diffNameList = {
    103201,
    103202,
    103203
  }
  self:InitLockState()
  self.pageIndex = pageIndex
  self.activityWndUI = {
    [1] = UIDef.DaiyanChapterPanel,
    [2] = UIDef.UIActivityCafeChapterPanel,
    [4] = UIDef.LennaChapterPanel,
    [6] = UIDef.LennaChapterPanel,
    [4001] = UIDef.ActivityThemeBChapterPanel
  }
  NetCmdThemeData.currSelectTab = 0
  self:MaualUI(self.pageIndex)
end

function UIBattleIndexBranchStorySubPanel:MaualUI(pageIndex)
  self.pageTabDic = NetCmdThemeData:GetPageDatas(pageIndex, true)
  self.stageData = TableData.listStageIndexDatas:GetDataById(pageIndex)
  if self.stageData then
    self.chapterData = TableDataBase.listChapterDatas:GetDataById(self.stageData.detail_id[0])
    NetCmdThemeData:UpdateLevelInfo(self.chapterData.stage_group)
  end
  local tabPrefab = self.ui.mTrans_LeftContent:GetComponent(typeof(CS.ScrollListChild))
  for i = 0, self.pageTabDic.Count - 1 do
    local index = i + 1
    if self.leftTabUIList[index] == nil then
      self.leftTabUIList[index] = {}
      local instObj = instantiate(tabPrefab.childItem)
      self:LuaUIBindTable(instObj, self.leftTabUIList[index])
      UIUtils.AddListItem(instObj.gameObject, self.ui.mTrans_LeftContent.gameObject)
      local chapterList = NetCmdThemeData:GetChapterIdList(self.pageTabDic, index)
      if 0 < chapterList.Count then
        local data = TableDataBase.listChapterDatas:GetDataById(chapterList[0])
        self.leftTabUIList[index].mText_Name.text = data.tab_name.str
        self.leftTabUIList[index].mBtn_Self.enabled = true
        setactive(self.leftTabUIList[index].mTrans_RedPoint.gameObject, 0 > NetCmdThemeData:GetThemeFinishRed())
      else
        self.leftTabUIList[index].mText_Name.text = TableData.GetHintById(103207)
        self.leftTabUIList[index].mBtn_Self.enabled = false
        setactive(self.leftTabUIList[index].mTrans_RedPoint.gameObject, false)
      end
      UIUtils.GetButtonListener(self.leftTabUIList[index].mBtn_Self.gameObject).onClick = function()
        self:OnClickTab(i)
        self.ui.mAutoScrollFade_Content:ImmediatelyDoScrollFade()
      end
    end
  end
  self:OnClickTab(NetCmdThemeData.currSelectTab)
end

function UIBattleIndexBranchStorySubPanel:UpdateBtnState(index)
  if self.currSelectIndex == index then
    return
  end
  self.currSelectIndex = index
  for k, v in ipairs(self.leftTabUIList) do
    v.mBtn_Self.interactable = index + 1 ~= k
  end
end

function UIBattleIndexBranchStorySubPanel:OnClickTab(index)
  local chapterList = NetCmdThemeData:GetChapterIdList(self.pageTabDic, index + 1)
  if chapterList.Count == 0 then
    CS.PopupMessageManager.PopupString(TableData.GetHintById(270016))
    return
  end
  NetCmdThemeData.currSelectTab = index
  self:UpdateBtnState(index)
  local chapterData = TableDataBase.listChapterDatas:GetDataById(chapterList[0])
  if 0 < NetCmdThemeData.currSelectEndId then
    local selectChapterData = TableDataBase.listChapterDatas:GetDataById(NetCmdThemeData.currSelectEndId, true)
    if chapterData.difficulty_group == selectChapterData.difficulty_group then
      chapterData = selectChapterData
    end
  end
  self.chapterIDList = NetCmdThemeData:GetChapterIDList(chapterData.tab)
  local Prefab = self.ui.mTrans_Content:GetComponent(typeof(CS.ScrollListChild))
  self:RefreshRed(chapterData)
  local maxCount = CS.AuditUtils:IsAudit() and 1 or 4
  local processStr = TableData.GetHintById(210009)
  for i = 1, maxCount do
    if self.rightItemUIList[i] == nil then
      self.rightItemUIList[i] = {}
      local instObj = instantiate(Prefab.childItem)
      self:LuaUIBindTable(instObj, self.rightItemUIList[i])
      UIUtils.AddListItem(instObj.gameObject, self.ui.mTrans_Content.gameObject)
    end
    self.rightItemUIList[i].mText_Text.text = "0" .. i
    local chapterIndex = i - 1
    if i <= chapterList.Count then
      local data = TableDataBase.listChapterDatas:GetDataById(chapterList[chapterIndex])
      if data then
        self.rightItemUIList[i].mText_TitleName.text = data.name.str
        self.rightItemUIList[i].mImg_Pic.sprite = IconUtils.GetStageIcon(data.Background)
        setactive(self.rightItemUIList[i].mTrans_NotAccess.gameObject, false)
        setactive(self.rightItemUIList[i].mTrans_Title.gameObject, true)
        setactive(self.rightItemUIList[i].mTrans_GrpLocked.gameObject, self.branchLockList[chapterData.id] or self:IsLock(data.unlock))
        if self.branchLockList[chapterData.id] or self:IsLock(data.unlock) then
          self.rightItemUIList[i].mText_Process.text = ""
          setactive(self.rightItemUIList[i].mTrans_RedPoint.gameObject, false)
        elseif 0 < data.chapter_reward_value.Count then
          local stars = NetCmdDungeonData:GetCurStarsByChapterID(data.id)
          local totalCount = data.chapter_reward_value[data.chapter_reward_value.Count - 1]
          local levelPassStage = NetCmdThemeData:GetLevelPassStage(chapterData.id)
          if stars == 0 or totalCount == 0 then
            self.rightItemUIList[i].mText_Process.text = string_format(TableData.GetHintById(210006), "0%", self:GetDiffLevelName(NetCmdThemeData:GetActivityEndDiffIndex(data.id)))
            setactive(self.rightItemUIList[i].mTrans_RedPoint.gameObject, 0 > NetCmdThemeData:GetThemeFinishRed())
          else
            if levelPassStage == 1 then
              local content = "<color=#f26c1c>" .. processStr .. math.ceil(stars / totalCount * 100) .. "%</color>"
              self.rightItemUIList[i].mText_Process.text = string_format(TableData.GetHintById(210006), content, self:GetDiffLevelName(NetCmdThemeData:GetActivityEndDiffIndex(data.id)))
            else
              local content = processStr .. math.ceil(stars / totalCount * 100) .. "%"
              self.rightItemUIList[i].mText_Process.text = string_format(TableData.GetHintById(210006), content, self:GetDiffLevelName(NetCmdThemeData:GetActivityEndDiffIndex(data.id)))
            end
            setactive(self.rightItemUIList[i].mTrans_RedPoint.gameObject, 0 < NetCmdDungeonData:UpdateChatperRewardRedPoint(data.id) or 0 > NetCmdThemeData:GetThemeFinishRed())
          end
        else
          local chapterInfo = TableData.GetStorysByChapterID(chapterData.id)
          local compCount = NetCmdDungeonData:GetChapterCompteCount(chapterData.id)
          if chapterInfo then
            local content = math.ceil(compCount / chapterInfo.Count * 100) .. "%"
            self.rightItemUIList[i].mText_Process.text = string_format(TableData.GetHintById(210006), content, self:GetDiffLevelName(NetCmdThemeData:GetActivityEndDiffIndex(chapterData.id)))
          else
            self.rightItemUIList[i].mText_Process.text = string_format(TableData.GetHintById(210006), "0%", self:GetDiffLevelName(NetCmdThemeData:GetActivityEndDiffIndex(chapterData.id)))
          end
          setactive(self.rightItemUIList[i].mTrans_RedPoint.gameObject, false)
        end
        setactive(self.rightItemUIList[i].mImg_Pic.gameObject, true)
      end
      if self.chapterData then
        setactive(self.rightItemUIList[i].mTrans_Icon.gameObject, not self.branchLockList[chapterData.id] and NetCmdThemeData:ChapterPassInThemeOpen(self.chapterData.plan_id, self.chapterData.id))
      else
        setactive(self.rightItemUIList[i].mTrans_Icon.gameObject, false)
      end
    else
      setactive(self.rightItemUIList[i].mImg_Pic.gameObject, false)
      setactive(self.rightItemUIList[i].mTrans_GrpLocked.gameObject, false)
      setactive(self.rightItemUIList[i].mTrans_NotAccess.gameObject, true)
      setactive(self.rightItemUIList[i].mTrans_Title.gameObject, false)
      setactive(self.rightItemUIList[i].mTrans_Icon.gameObject, false)
      setactive(self.rightItemUIList[i].mTrans_RedPoint.gameObject, false)
    end
    UIUtils.GetButtonListener(self.rightItemUIList[i].mBtn_BattleIndexBranchItem.gameObject).onClick = function()
      if chapterList.Count >= i then
        local selectData = TableDataBase.listChapterDatas:GetDataById(chapterList[i - 1])
        if selectData == nil then
          selectData = chapterData
        end
        if self.branchLockList[selectData.id] then
          CS.PopupMessageManager.PopupString(TableData.GetHintById(103050))
          return
        end
        NetCmdThemeData.currSelectChapterId = selectData.id
        self.currSelectIndex = -1
        NetCmdThemeData:SetThemeFinishRed(1)
        self:RefreshRed(selectData)
        self:OnClickChapter(selectData.id)
      else
        CS.PopupMessageManager.PopupString(TableData.GetHintById(210010))
      end
    end
  end
end

function UIBattleIndexBranchStorySubPanel:GetDiffLevelName(currDiff)
  return TableData.GetHintById(self.diffNameList[currDiff])
end

function UIBattleIndexBranchStorySubPanel:RefreshRed(chapterData)
  for _, obj in pairs(self.leftTabUIList) do
    local chapterIDList = NetCmdThemeData:GetChapterIdList(self.pageTabDic, _)
    if chapterIDList.Count > 0 then
      local isShowRed = false
      for j = 0, chapterIDList.Count - 1 do
        if NetCmdThemeData:ThemeBattleRed(chapterIDList[j]) and not self.branchLockList[chapterIDList[j]] then
          isShowRed = true
          break
        end
      end
      setactive(obj.mTrans_RedPoint.gameObject, isShowRed)
    else
      setactive(obj.mTrans_RedPoint.gameObject, false)
    end
  end
end

function UIBattleIndexBranchStorySubPanel:OnClickChapter(chapterId)
  local chapterData = TableData.listChapterDatas:GetDataById(chapterId)
  local activityId = 1
  for i = 0, self.stageData.detail_id.Count - 1 do
    if self.stageData.detail_id[i] == chapterId then
      activityId = self.stageData.activity_id[i]
      break
    end
  end
  local wndId = self.activityWndUI[activityId]
  if wndId == nil then
    wndId = UIDef.DaiyanChapterPanel
    print("stage_index\232\161\168\231\154\132activity_id\230\178\161\230\156\137\233\133\141\231\189\174\229\175\185\229\186\148\231\154\132UI\231\149\140\233\157\162\239\188\140\232\175\183\232\129\148\231\179\187\231\168\139\229\186\143\229\164\132\231\144\134\239\188\129\239\188\129\239\188\129")
  end
  UIManager.OpenUIByParam(wndId, {ChapterData = chapterData, ActivityConfigId = activityId})
end

function UIBattleIndexBranchStorySubPanel:IsLock(list)
  if list.Count == 0 then
    return false
  end
  local lockStr = CS.LuaUIUtils.CheckUnlockPopupStrByRepeatedList(list)
  return 0 < string.len(lockStr)
end

function UIBattleIndexBranchStorySubPanel:InitLockState()
  self.branchLockList = {}
  self.pageIndex = 5
  local indexData = TableData.listStageIndexDatas:GetDataById(5)
  if indexData and indexData.detail_id.Count > 0 then
    for i = 0, indexData.detail_id.Count - 1 do
      local chapterData = TableData.listChapterDatas:GetDataById(indexData.detail_id[i])
      if chapterData then
        local storyData = TableData.listChapterByDifficultyGroupDatas:GetDataById(chapterData.difficulty_group)
        for j = 0, storyData.Id.Count - 1 do
          local stageChapterData = TableData.listChapterDatas:GetDataById(storyData.Id[j], true)
          local planActivity = TableData.listPlanDatas:GetDataById(stageChapterData.plan_id, true)
          self.branchLockList[stageChapterData.id] = true
          if planActivity and CGameTime:GetTimestamp() >= planActivity.open_time and CGameTime:GetTimestamp() < planActivity.close_time then
            self.branchLockList[stageChapterData.id] = false
          end
        end
      end
    end
  end
end

function UIBattleIndexBranchStorySubPanel:OnBackFrom()
  self:InitLockState()
  self:MaualUI(self.pageIndex)
end

function UIBattleIndexBranchStorySubPanel:OnRelease()
  for _, obj in pairs(UIBattleIndexBranchStorySubPanel.leftTabUIList) do
    gfdestroy(obj.mTrans_Parent)
  end
  UIBattleIndexBranchStorySubPanel.leftTabUIList = {}
  for _, obj in pairs(UIBattleIndexBranchStorySubPanel.rightItemUIList) do
    gfdestroy(obj.mTrans_Parent)
  end
  self.currSelectIndex = -1
  UIBattleIndexBranchStorySubPanel.rightItemUIList = {}
end

function UIBattleIndexBranchStorySubPanel:OnClose()
end
