require("UI.FacilityBarrackPanel.UIChrTalent.UITalentGlobal")
require("UI.FacilityBarrackPanel.UIChrTalent.UIChrTalentDescSubPanel")
require("UI.FacilityBarrackPanel.UIChrTalent.UIChrTalentTreeSubPanel")
require("UI.FacilityBarrackPanel.UIGunTalent.UIGunTalentAssemblyUnlockItem")
require("UI.FacilityBarrackPanel.UIChrTalent.UITalentExtraRewardBtnCtrl")
UIChrTalentPanel = class("UIChrTalentPanel", UIBasePanel)
UIChrTalentPanel.CheckQueue = {
  None = 0,
  DisableInput = 1,
  TalentActiveAnim = 2,
  CommonReceive = 3,
  ExtraReceive = 4,
  RefreshView = 5,
  FocusNextTalent = 6,
  EnableInput = 7,
  Finish = 8
}

function UIChrTalentPanel:ctor(root, uiChrPowerUpPanel)
  self:SetRoot(root.transform)
  self.uiChrPowerUpPanel = uiChrPowerUpPanel
  self.ui = UIUtils.GetUIBindTable(root)
  self.treeSubPanel = UIChrTalentTreeSubPanel.New(self.ui.mTrans_TreeSubPanel, self)
  self.treeSubPanel:AddSlotClickListener(function(slot)
    self:onClickSlot(slot)
  end)
  self.treeSubPanel:AddInbornTalentKeyClickListener(function()
    self:onClickInbornTalentKey()
  end)
  self.treeSubPanel:AddShareSkillItemClickListener(function()
    self:onClickShareSkillItem()
  end)
  self.treeSubPanel:AddOnShowFinishCallback(function()
    self:onTreeSubPanelShowFinish()
  end)
  self.treeSubPanel:SetVisible(true)
  self.descSubPanel = UIChrTalentDescSubPanel.New(self.ui.mTrans_DescSubPanel, self)
  self.descSubPanel:SetVisible(false)
  self.btnTalentSet = UIGunTalentAssemblyUnlockItem.New()
  self.btnTalentSet:InitCtrl(self.ui.mTrans_SetTalent)
  self.btnTalentSet:AddClickListener(function()
    self:onClickTalentButton()
  end)
  self.btnExtraReward = UITalentExtraRewardBtnCtrl.New(self.ui.mBtn_ExtraReward.transform.parent)
  self.btnExtraReward:AddClickListener(function()
    self:onClickTalentExtraReward()
  end)
  self.curCheckStep = UIChrTalentPanel.CheckQueue.None
end

function UIChrTalentPanel:Init(gunCmdData)
  if self.gunId == gunCmdData.id then
    return
  end
  self.gunId = gunCmdData.id
  self.treeSubPanel:Init(self.gunId)
  self.descSubPanel:Init(self.gunId)
  self.btnExtraReward:Init(self.gunId)
end

function UIChrTalentPanel:OnShowStart()
  self:SetVisible(true)
  self:showStartByCurModel()
  self.btnExtraReward:Refresh()
end

function UIChrTalentPanel:OnShowFinish()
end

function UIChrTalentPanel:OnRecover()
  BarrackHelper.CameraMgr:ChangeCameraStand(BarrackCameraStand.Base, false)
  self.treeSubPanel:OnRecover()
  BarrackHelper.InteractManager:RemoveListener()
  BarrackHelper.InteractManager:ResetAll()
end

function UIChrTalentPanel:OnBackFrom()
  self:OnShowStart()
end

function UIChrTalentPanel:OnTop()
  self.descSubPanel:Refresh()
end

function UIChrTalentPanel:OnRefresh()
  self.descSubPanel:Refresh()
end

function UIChrTalentPanel:OnUpdate()
  self.treeSubPanel:OnUpdate()
end

function UIChrTalentPanel:OnHide()
  NetCmdTalentData:SetBlockTalentRedPoint(self.gunId, true)
  self.uiChrPowerUpPanel:UpdateTabRedPoint()
  local animLen = CS.LuaUtils.GetAnimationClipLength(self.ui.mAnimator_Root, "FadeOut")
  if self.treeSubPanel ~= nil then
    self.treeSubPanel:OnHide()
  end
  if self.descSubPanel ~= nil then
    self.descSubPanel:OnHide()
  end
  self.timer = TimerSys:DelayCall(animLen, function()
    self:OnHideFinish()
  end)
end

function UIChrTalentPanel:OnHideFinish()
  self:SetVisible(false)
  if self.treeSubPanel ~= nil then
    self.treeSubPanel:OnHideFinish()
  end
  if self.descSubPanel ~= nil then
    self.descSubPanel:OnHideFinish()
  end
end

function UIChrTalentPanel:OnClose()
  if self.timer then
    self.timer:Stop()
    self.timer = nil
  end
  self.authorizeGroupId = nil
  self.gunId = nil
end

function UIChrTalentPanel:OnRelease()
  if self.treeSubPanel ~= nil then
    self.treeSubPanel:OnRelease()
  end
  if self.descSubPanel ~= nil then
    self.descSubPanel:OnRelease()
  end
  if self.btnTalentSet ~= nil then
    self.btnTalentSet:OnRelease()
  end
  if self.btnExtraReward ~= nil then
    self.btnExtraReward:OnRelease()
  end
  self.ui = nil
  self.super.OnRelease(self)
end

function UIChrTalentPanel:ResetData()
  if not self.refreshDirty then
    self.refreshDirty = true
    self.treeSubPanel:OnHideFinish()
    self.descSubPanel:OnHideFinish()
    self:showStartByCurModel()
    self.ui.mAnimator_Root:SetTrigger("Switch")
    TimerSys:DelayFrameCall(1, function()
      self.refreshDirty = false
    end)
  end
end

function UIChrTalentPanel:SetVisible(visible)
  if visible then
    self.ui.mCanvasGroup.alpha = 1
    self.ui.mCanvasGroup.blocksRaycasts = true
  else
    self.ui.mCanvasGroup.alpha = 0
    self.ui.mCanvasGroup.blocksRaycasts = false
  end
end

function UIChrTalentPanel:EnableInputMask(enable)
  self.uiChrPowerUpPanel:ShowMask(enable)
  self.uiChrPowerUpPanel:SetUIInteractable(not enable)
end

function UIChrTalentPanel:showStartByCurModel()
  local gunCmdData = NetCmdTeamData:GetGunByID(BarrackHelper.ModelMgr.GunStcDataId)
  self:Init(gunCmdData)
  self.treeSubPanel:OnShowStart()
  self.btnTalentSet:SetData(self.gunId)
  self.btnExtraReward:Refresh()
end

function UIChrTalentPanel:onTreeSubPanelShowFinish()
  self.descSubPanel:SetVisible(true)
  self.descSubPanel:setAnimTrigger("FadeIn")
end

function UIChrTalentPanel:onReceivedShareSkillItem()
  self.treeSubPanel:refreshShareTalentItemSlot()
  self.uiChrPowerUpPanel:UpdateTabRedPoint()
end

function UIChrTalentPanel:onAuthorize(groupId)
  NetCmdTalentData:SetBlockTalentRedPoint(self.gunId, false)
  self.uiChrPowerUpPanel:UpdateTabRedPoint()
  self.authorizeGroupId = groupId
  self:startCheckQueue()
end

function UIChrTalentPanel:startCheckQueue()
  self.curCheckStep = UIChrTalentPanel.CheckQueue.None
  self:moveNextCheckQueue()
end

function UIChrTalentPanel:moveNextCheckQueue()
  self.curCheckStep = self.curCheckStep + 1
  if self.curCheckStep == self.CheckQueue.None then
    gferror("MoveNext\228\184\141\229\186\148\232\175\165\230\157\165\229\136\176None\231\138\182\230\128\129!")
  elseif self.curCheckStep == self.CheckQueue.DisableInput then
    self:EnableInputMask(true)
    self:moveNextCheckQueue()
  elseif self.curCheckStep == self.CheckQueue.TalentActiveAnim then
    self.treeSubPanel:refreshAllGroup()
    self:checkQueueForTalentActiveAnimEnd()
  elseif self.curCheckStep == self.CheckQueue.CommonReceive then
    self:checkQueueForOpenCommonReceivePanel()
  elseif self.curCheckStep == self.CheckQueue.ExtraReceive then
    self:checkQueueForOpenExtraReceivePanel()
  elseif self.curCheckStep == self.CheckQueue.RefreshView then
    self:refreshView()
    self:moveNextCheckQueue()
  elseif self.curCheckStep == self.CheckQueue.FocusNextTalent then
    self:focusNextTalent()
    self:moveNextCheckQueue()
  elseif self.curCheckStep == self.CheckQueue.EnableInput then
    self:EnableInputMask(false)
    self:moveNextCheckQueue()
  elseif self.curCheckStep == self.CheckQueue.Finish then
    self:onCheckQueueFinished()
    self.curCheckStep = self.CheckQueue.None
  end
end

function UIChrTalentPanel:checkQueueForTalentActiveAnimEnd()
  local animLen = self.treeSubPanel:getCurSlotAnimLen("Active_Fx")
  TimerSys:DelayCall(animLen, function(data)
    self:moveNextCheckQueue()
  end)
end

function UIChrTalentPanel:checkQueueForOpenCommonReceivePanel()
  local groupId = self.authorizeGroupId
  local talentType = UITalentGlobal.GetTalentType(groupId)
  if talentType == UITalentGlobal.TalentType.PrivateTalentKey then
    local level = NetCmdTalentData:GetGunTalentLevel(self.gunId, groupId)
    local geneData = UITalentGlobal.GetTargetGeneData(groupId, level)
    self:openCommonReceivePanel(geneData.ItemId, 1, function()
      self:moveNextCheckQueue()
    end)
  else
    self:moveNextCheckQueue()
  end
end

function UIChrTalentPanel:checkQueueForOpenExtraReceivePanel()
  local talentPoint = NetCmdTalentData:GetTalentPoint(self.gunId, self.authorizeGroupId)
  local talentPointTypeId = LuaUtils.EnumToInt(talentPoint.Type)
  if talentPointTypeId == 3 then
    local talentBonusData = NetCmdTalentData:GetCurBonusGroupData(self.gunId)
    if talentBonusData then
      local count = NetCmdTalentData:GetAuthorizedPrivateTalentCountNonAlloc(self.gunId)
      if talentBonusData.UnlockCount == count then
        local param = {
          GunId = self.gunId,
          OnClickCloseCallback = function()
            self:moveNextCheckQueue()
          end
        }
        UISystem:OpenUI(UIDef.UIChrTalentExtraRewardLevelUpDialog, param)
      else
        self:moveNextCheckQueue()
      end
    else
      self:moveNextCheckQueue()
    end
  else
    self:moveNextCheckQueue()
  end
end

function UIChrTalentPanel:refreshView()
  self.treeSubPanel:refreshShareTalentItemSlot()
  self.descSubPanel:Refresh()
  self.uiChrPowerUpPanel:UpdateTabRedPoint()
  self.btnTalentSet:SetData(self.gunId)
  self.btnExtraReward:Refresh()
end

function UIChrTalentPanel:focusNextTalent()
  self.treeSubPanel:FocusNextTalent()
end

function UIChrTalentPanel:onCheckQueueFinished()
  self.authorizeGroupId = 0
end

function UIChrTalentPanel:openCommonReceivePanel(itemId, itemNum, callback)
  NetCmdItemData:ClearUserDropCache()
  local itemTable = {
    {ItemId = itemId, ItemNum = itemNum}
  }
  UISystem:OpenCommonReceivePanel({
    callback,
    nil,
    false,
    false,
    itemTable
  })
end

function UIChrTalentPanel:onClickSlot(slot)
  local curSlot = slot
  if not curSlot then
    return
  end
  self.descSubPanel:RefreshBySlot(curSlot:GetTreeId(), curSlot:GetGroupId(), curSlot:GetLevel(), curSlot:GetGroupIndex(), curSlot:GetSlotIndex())
end

function UIChrTalentPanel:onClickInbornTalentKey()
  self.descSubPanel:RefreshByInbornTalentSkill()
end

function UIChrTalentPanel:onClickShareSkillItem()
  self.descSubPanel:RefreshByShareTalentItem()
end

function UIChrTalentPanel:onClickTalentButton()
  if AccountNetCmdHandler:CheckSystemIsUnLock(SystemList.SquadTalentEquip) then
    UIManager.OpenUIByParam(UIDef.UIGunTalentAssemblyPanel, {
      self.gunId,
      false
    })
  else
    TipsManager.NeedLockTips(SystemList.SquadTalentEquip)
  end
end

function UIChrTalentPanel:onClickTalentExtraReward()
  UISystem:OpenUI(UIDef.UIChrTalentExtraRewardDialog, self.gunId)
end
