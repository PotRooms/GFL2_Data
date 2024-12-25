require("UI.UIBaseCtrl")
SimCombatMythicStageGroupItemV2 = class("SimCombatMythicStageGroupItemV2", UIBaseCtrl)
local self = SimCombatMythicStageGroupItemV2

function SimCombatMythicStageGroupItemV2:ctor()
  self.stageGroupItemData = nil
  self.groupId = 0
  self.progressNum = 0
  self.curAllGroupNum = 0
  self.maxProgressNum = 0
  self.maxPhase = 0
  self.progressNumText = 0
  self.isThisItemRendered = false
  self.itemIndex = 0
  self.isUnLock = false
end

function SimCombatMythicStageGroupItemV2:InitCtrl(parent)
  local itemPrefab = parent.gameObject:GetComponent(typeof(CS.ScrollListChild))
  local instObj = instantiate(itemPrefab.childItem)
  self.ui = {}
  self:LuaUIBindTable(instObj, self.ui)
  if parent then
    UIUtils.AddListItem(instObj.gameObject, parent.gameObject)
  end
  self:SetRoot(instObj.transform)
  UIUtils.GetButtonListener(self.ui.mBtn_Item_Normal.gameObject).onClick = function()
    self:OnClickItem()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Item_Slc.gameObject).onClick = function()
    self:OnClickItem()
  end
end

function SimCombatMythicStageGroupItemV2:SetData(data)
  setactive(self.mUIRoot, true)
  self.stageGroupItemData = data
  self.groupId = data.Id
  self.itemIndex = data.Id
  self:SetPanel()
  self:SetSelected(false)
end

function SimCombatMythicStageGroupItemV2:SetSelected(boolean)
  self.ui.mAnimator_Item:SetInteger("Switch", boolean and 1 or 2)
end

function SimCombatMythicStageGroupItemV2:SetTextColor(isNormal)
  self.ui.mAnimator_Item:SetInteger("ModeSwitch", isNormal and 0 or 1)
end

function SimCombatMythicStageGroupItemV2:OnClickItem()
  if not self.isUnLock then
    local lockType = NetCmdSimCombatMythicData:CheckStageGroupLockType(self.groupId)
    if lockType == 1 then
      UIUtils.PopupHintMessage(103108)
    else
      local hint = TableData.GetHintById(103121)
      local msg = string_format(hint, self.stageGroupItemData.level)
      CS.PopupMessageManager.PopupString(msg)
    end
  else
    SimCombatMythicConfig.refightSelectedStageId = nil
    UIManager.OpenUIByParam(UIDef.UISimCombatMythicStageGroupDetailPanel, self.stageGroupItemData.Id)
  end
end

function SimCombatMythicStageGroupItemV2:SetPanel()
  self.ui.mText_Tittle_Normal.text = self.stageGroupItemData.goup_name.str
  self.ui.mText_Tittle_Slc.text = self.stageGroupItemData.goup_name.str
  if self.stageGroupItemData.group_type == 1 then
    local id = 0
    for i = 0, TableData.listSimCombatMythicGroupDatas.Count - 1 do
      local data = TableData.listSimCombatMythicGroupDatas[i]
      if data.group_type ~= 1 and id < data.id then
        id = data.id
      end
    end
    self.ui.mText_Num_Normal.text = "E 00" .. tostring(id + 1)
    self.ui.mText_Num_Slc.text = "E 00" .. tostring(id + 1)
  else
    self.ui.mText_Num_Normal.text = "E 00" .. tostring(self.stageGroupItemData.id)
    self.ui.mText_Num_Slc.text = "E 00" .. tostring(self.stageGroupItemData.id)
  end
  self.ui.mImage_Chapter_Normal.sprite = IconUtils.GetRogueIcon(self.stageGroupItemData.group_bg .. "_S")
  self.ui.mImage_Chapter_Slc.sprite = IconUtils.GetRogueIcon(self.stageGroupItemData.group_bg .. "_L")
  self.ui.mText_Content_Slc.text = self.stageGroupItemData.group_desc.str
  local recommendLv = self.stageGroupItemData.level
  if recommendLv == 0 then
    setactive(self.ui.mText_RecommendLv.transform.parent.gameObject, false)
  else
    setactive(self.ui.mText_RecommendLv.transform.parent.gameObject, true)
    self.ui.mText_RecommendLv.text = string_format(TableData.GetHintById(103113), self.stageGroupItemData.level)
  end
  local curStageGroupId = NetCmdSimCombatMythicData:GetStageGroupLevelGroupId(self.groupId)
  local stageGroupConfig = TableData.listSimCombatMythicConfigDatas:GetDataById(curStageGroupId)
  self.ui.mImage_Boss_Slc.sprite = IconUtils.GetCharacterHeadFullName(stageGroupConfig.Boss_icon)
  self.isUnLock = NetCmdSimCombatMythicData:CheckStageGroupIsUnlock(self.groupId)
  setactive(self.ui.mTrans_Target_Slc, self.isUnLock)
  setactive(self.ui.mTrans_TragetNormal, self.isUnLock)
  self.ui.mAnimatior_Normal:SetBool("Bool", self.isUnLock)
  self.ui.mAnimator_Slc:SetBool("Bool", self.isUnLock)
  setactive(self.ui.mImg_Infinite, self.stageGroupItemData.group_type == 1)
  setactive(self.ui.mText_Time, self.stageGroupItemData.group_type == 1)
  if self.isUnLock then
    self.ui.mImg_Infinite.sprite = ResSys:GetAtlasSprite("SimCombatMythicPic/Img_SimCombatMythic_Infinite")
    local allFinish = NetCmdSimCombatMythicData:CheckStageGroupIsAllFinish(self.groupId)
    if allFinish then
      self.ui.mText_Progress_Normal.text = "<color=#ed6a2bff>" .. "100%" .. "</color>"
      self.ui.mText_Progress_Slc.text = "<color=#ed6a2bff>" .. "100%" .. "</color>"
      setactive(self.ui.mTran_Boss_Complete_Slc.gameObject, true)
    else
      local progress = NetCmdSimCombatMythicData:GetStageGroupProgress(self.groupId)
      self.ui.mText_Progress_Normal.text = tostring(progress) .. "%"
      self.ui.mText_Progress_Slc.text = tostring(progress) .. "%"
      setactive(self.ui.mTran_Boss_Complete_Slc.gameObject, false)
    end
  else
    self.ui.mImg_Infinite.sprite = ResSys:GetAtlasSprite("SimCombatMythicPic/Img_SimCombatMythic_Infinite_Lock")
  end
  if self.stageGroupItemData.group_type == 1 then
    local planData = TableData.listPlanDatas:GetDataById(NetCmdSimCombatMythicData.CurPlanConfigId)
    if planData ~= nil then
      local currOpenData = CS.CGameTime.ConvertLongToDateTime(planData.OpenTime)
      local currCloseData = CS.CGameTime.ConvertLongToDateTime(planData.CloseTime)
      local curOpenTime = currOpenData:ToString("yyyy.MM.dd")
      local curCloseTime = currCloseData:ToString("yyyy.MM.dd")
      self.ui.mText_Time.text = string.format(TableData.GetHintById(103193), curOpenTime, curCloseTime)
    end
  end
end

function SimCombatMythicStageGroupItemV2:SetSelfShow(boolean)
  self.ui.mCanvasGroup_SelfItem.alpha = boolean and 1 or 0
end

function SimCombatMythicStageGroupItemV2:OnRelease()
  self:DestroySelf()
end
