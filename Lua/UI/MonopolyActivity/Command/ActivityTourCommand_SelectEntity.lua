require("UI.UIBaseCtrl")
require("UI.MonopolyActivity.Command.ActivityTourCommand_CtrlBase")
require("UI.MonopolyActivity.ActivityTourGlobal")
ActivityTourCommandSelectEntity = class("ActivityTourCommandSelectEntity", ActivityTourCommandCtrlBase)
ActivityTourCommandSelectEntity.__index = ActivityTourCommandSelectEntity

function ActivityTourCommandSelectEntity:ctor()
  self.super.ctor(self)
end

function ActivityTourCommandSelectEntity:InitCtrl(commandCtrl, parentUI)
  self.mCommandCtrl = commandCtrl
  self.ui = parentUI
  self.mSelectRoot = self.ui.mTrans_SelectEntity.gameObject
  
  function self.OnSelectChange()
    self:OnSelectChangeRefreshInfo()
  end
end

function ActivityTourCommandSelectEntity:Hide()
  setactive(self.ui.mTrans_SelectEntity, false)
  setactive(self.ui.mTrans_SelectRoot, false)
  MessageSys:RemoveListener(CS.GF2.Message.MonopolyEvent.OnSelectChange, self.OnSelectChange)
  MonopolySelectManager:CancelAllSelect(true)
  MonopolySelectManager:EnableMultiSelect(false)
end

function ActivityTourCommandSelectEntity:SetData(data, slotIndex)
  self:RegisterEvent()
  MessageSys:AddListener(CS.GF2.Message.MonopolyEvent.OnSelectChange, self.OnSelectChange)
  self.mData = data
  self.mSlotIndex = slotIndex
  self:InitParam()
  self:ShowOrderInfo(self.mData)
  self:InitSelectInfo()
end

function ActivityTourCommandSelectEntity:InitParam()
  local canSelect, skillType, maxSelectCount, skillID = CS.GF2.Monopoly.MonopolyDefine.GetSkillSelectInfo(self.mData)
  self.mShowSelect = canSelect
  self.mTargetType = skillType
  self.mMinSelect = 0
  self.mMaxSelect = maxSelectCount
  self.mUseSkillID = skillID
end

function ActivityTourCommandSelectEntity:RegisterEvent()
  UIUtils.AddBtnClickListener(self.ui.mBtn_Confirm, function()
    local selectCount = MonopolySelectManager:GetTotalSelectCount()
    local canSelectCount = MonopolySelectManager:GetTotalCanSelectCount()
    if self.mShowSelect and canSelectCount == 0 then
      MessageBox.Show(TableData.GetHintById(208), MonopolyUtil:GetMonopolyActivityHint(270325), nil, function()
        self:UseCommand()
      end)
    elseif self.mShowSelect and selectCount < self.mMaxSelect and selectCount < canSelectCount then
      MessageBox.Show(TableData.GetHintById(208), MonopolyUtil:GetMonopolyActivityHint(270327), nil, function()
        self:UseCommand()
      end)
    else
      self:UseCommand()
    end
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Delete, function()
    self.mCommandCtrl:DeleteCommand(self.mData, self.mSlotIndex)
  end)
end

function ActivityTourCommandSelectEntity:UseCommand()
  local targets = {}
  if self.mShowSelect then
    targets = MonopolySelectManager:GetAllSelectTargetGridIds()
    if self:PreCheckTargets(targets) then
      self:RelayUseCommand(targets)
    end
    return
  elseif self:NeedSelectTeam() then
    self:ShowTeamSelectPanel()
    return
  end
  self:RelayUseCommand(targets)
end

function ActivityTourCommandSelectEntity:PreCheckTargets(targets)
  if self.mTargetType ~= CS.GF2.Monopoly.OrderSkillType.ActorSkill then
    return true
  end
  local skillParamData = ActivityTourGlobal.MonopolyDefine.GetSkillParamDataByMainPlayer(self.mUseSkillID)
  if skillParamData == nil then
    return true
  end
  if skillParamData.steal_order > 0 then
    local hasCard = ActivityTourGlobal.MonopolyDefine.HasCanUseOrder(targets)
    if not hasCard then
      MessageBox.Show(TableData.GetHintById(208), MonopolyUtil:GetMonopolyActivityHint(270412), nil, function()
        self:RelayUseCommand(targets)
      end)
    end
    return hasCard
  end
  return true
end

function ActivityTourCommandSelectEntity:NeedSelectTeam()
  if self.mShowSelect then
    return false
  end
  if self.mTargetType == CS.GF2.Monopoly.OrderSkillType.ActorSkill and self.mUseSkillID > 0 then
    local skillConfig = TableDataBase.listMonopolySkillDatas:GetDataById(self.mUseSkillID)
    return skillConfig and skillConfig.target_type == LuaUtils.EnumToInt(CS.GF2.Monopoly.ActorSkillTargetType.SelfTeam)
  end
  return false
end

function ActivityTourCommandSelectEntity:ShowTeamSelectPanel()
  local skillConfig = TableDataBase.listMonopolySkillDatas:GetDataById(self.mUseSkillID)
  CS.GF2.Monopoly.MonopolyCommonBehavior.ShowGetPropBySkill(skillConfig, function(changeType, ret, uintTargets)
    if ret < 0 or uintTargets == nil then
      return
    end
    local targets = {}
    local selectCount = uintTargets.Count
    if 0 < selectCount then
      for i = 0, selectCount - 1 do
        local target = uintTargets[i]
        table.insert(targets, target)
      end
      self:RelayUseCommand(targets, true)
      return
    end
    if changeType == CS.GF2.Monopoly.PropChangeType.Restart then
      MessageBox.Show(TableData.GetHintById(208), MonopolyUtil:GetMonopolyActivityHint(270406), nil, function()
        self:RelayUseCommand(targets, true)
      end)
      return
    end
    self:RelayUseCommand(targets, true)
  end)
end

function ActivityTourCommandSelectEntity:RelayUseCommand(targets, isGun)
  if isGun == nil then
    isGun = false
  end
  MessageSys:SendMessage(MonopolyEvent.BlockActivityTourMainPanel, nil)
  MonopolyWorld.MpData:UseCommand(self.mSlotIndex, 0, targets, function(ret)
    MessageSys:SendMessage(MonopolyEvent.CancelBlockActivityTourMainPanel, nil)
    if ret == ErrorCodeSuc then
      self.mCommandCtrl:HideCommandInfo()
      self.mCommandCtrl:RefreshAllCommand(false)
    end
  end, isGun)
end

function ActivityTourCommandSelectEntity:InitSelectInfo()
  setactive(self.ui.mTrans_SelectRoot, self.mShowSelect)
  self:EnableConfirmBtn(not self.mShowSelect)
  MonopolySelectManager:CancelAllSelect(true)
  if not self.mShowSelect then
    return
  end
  MonopolySelectManager:EnableMultiSelect(true, self.mMaxSelect)
  local count = MonopolySelectManager:SetOnlyCanSelectWithOrder(self.mData)
  if self.mMaxSelect <= 0 then
    self.mMaxSelect = count
  end
  self:RefreshSelectCount()
end

function ActivityTourCommandSelectEntity:RefreshSelectCount()
  if not self.mShowSelect then
    return
  end
  local canSelectCount = MonopolySelectManager:GetTotalCanSelectCount()
  local selectCount = MonopolySelectManager:GetTotalSelectCount()
  local canConfirm = selectCount >= self.mMinSelect
  local selectAll = selectCount >= self.mMaxSelect
  local noCanSelect = canSelectCount == 0
  if noCanSelect then
    self.ui.mText_SelectInfo.text = MonopolyUtil:GetMonopolyActivityHint(270324)
  else
    local skillConfig
    if self.mTargetType == CS.GF2.Monopoly.OrderSkillType.ActorSkill then
      skillConfig = TableDataBase.listMonopolySkillDatas:GetDataById(self.mUseSkillID)
    else
      skillConfig = TableDataBase.listMonopolyMapSkillDatas:GetDataById(self.mUseSkillID)
    end
    if skillConfig == nil or skillConfig.target_tips.str == "" then
      self.ui.mText_SelectInfo.text = "Skill\239\188\154" .. tostring(self.mUseSkillID) .. "\233\133\141\231\189\174\229\188\130\229\184\184"
    else
      self.ui.mText_SelectInfo.text = UIUtils.StringFormat(skillConfig.target_tips.str, selectCount, self.mMaxSelect)
    end
  end
  setactive(self.ui.mTrans_SelectUnComplete, not selectAll)
  setactive(self.ui.mTrans_SelectComplete, selectAll)
  self:EnableConfirmBtn(canConfirm or noCanSelect)
end

function ActivityTourCommandSelectEntity:OnSelectChangeRefreshInfo()
  if not self.mSelectRoot.activeInHierarchy then
    return
  end
  self:RefreshSelectCount()
end

function ActivityTourCommandSelectEntity:OnRelease()
  MessageSys:RemoveListener(CS.GF2.Message.MonopolyEvent.OnSelectChange, self.OnSelectChange)
  self.mSelectRoot = nil
  self.super.OnRelease(self, true)
end
