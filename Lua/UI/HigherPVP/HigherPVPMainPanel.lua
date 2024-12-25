require("UI.UIBasePanel")
require("UI.PVP.UIPVPGlobal")
HigherPVPMainPanel = class("HigherPVPMainPanel", UIBasePanel)
HigherPVPMainPanel.__index = HigherPVPMainPanel

function HigherPVPMainPanel:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Panel
end

function HigherPVPMainPanel:OnAwake(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self:OnBtnClick()
end

function HigherPVPMainPanel:OnInit(root, data)
  self.ui.mAnimator_Root.enabled = true
  local isHaveSeasonData = false
  if NetCmdHigherPVPData:GetHighPvpNewSeasonOpen() then
    local seasonData = NetCmdHigherPVPData:GetHigherPVPSeasonData()
    if seasonData and seasonData.SeasonId > 0 then
      isHaveSeasonData = true
    end
  end
  self.isreadytorial = NetCmdHigherPVPData:GetHigherPVPSettle() == nil and not isHaveSeasonData
  self:UpdateRankPercent()
  NetCmdHigherPVPData:MsgCsHighPvpInfo(function(ret)
    if ret == ErrorCodeSuc then
      self:UpdateInfo()
    end
  end)
end

function HigherPVPMainPanel:UpdateRankPercent()
  self.ui.mText_Rank.text = ""
  NetCmdHigherPVPData:CleanSelfRankPercent()
  NetCmdHigherPVPData:MsgCsHighPvpRank(true, 0, 0, function(ret)
    if ret == ErrorCodeSuc and NetCmdHigherPVPData:GetSelfRankPercent() > 0 then
      self.ui.mText_Rank.text = string_format(TableData.GetHintById(290003), NetCmdHigherPVPData:GetSelfRankPercent())
    end
  end)
end

function HigherPVPMainPanel:UpdateInfo()
  self.ui.mImg_Icon.sprite = IconUtils.GetItemIconSprite(TableDataBase.GlobalSystemData.HighPVPTicket)
  local pvpRankData = NetCmdHigherPVPData:GetHighPvpRank()
  if pvpRankData then
    if pvpRankData.Rank == 0 then
      self.ui.mText_Num.text = TableData.GetHintById(130006)
    else
      self.ui.mText_Num.text = pvpRankData.Rank
    end
    self.ui.mText_Num1.text = pvpRankData.Points
    if pvpRankData.SeasonAtk then
      self.ui.mText_Num3.text = pvpRankData.SeasonAtk.Total
      self.ui.mText_Num2.text = pvpRankData.SeasonAtk.Win
    else
      self.ui.mText_Num3.text = 0
      self.ui.mText_Num2.text = 0
    end
  end
  self.ui.mText_Num4.text = CS.LuaUIUtils.GetMaxNumberText(1)
  local seasonData = NetCmdHigherPVPData:GetCurrSeason()
  if seasonData then
    local highPvpSeason = TableData.listHighPvpSeasonDatas:GetDataById(seasonData.SeasonId, true)
    if highPvpSeason then
      self.ui.mText_Season.text = highPvpSeason.season_name.str
    end
  end
  self:CheckKickOut()
end

function HigherPVPMainPanel:OnBtnClick()
  UIUtils.GetButtonListener(self.ui.mBtn_Back.gameObject).onClick = function()
    UIManager.CloseUI(UIDef.HigherPVPMainPanel)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Home.gameObject).onClick = function()
    UISystem:JumpToMainPanel()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_RankReward.gameObject).onClick = function()
    UIManager.OpenUI(UIDef.HigherPVPRankRewardDialog)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Record.gameObject).onClick = function()
    if not NetCmdHigherPVPData.PVPIsOpen then
      self:CheckKickOut()
      return
    end
    NetCmdHigherPVPData:MsgCsHighPvpHistory(CS.ProtoCsmsg.CS_HighPvpHistory.Types.PvpHistoryInfoType.FullBrief, 0, function(ret)
      if ret == ErrorCodeSuc then
        UIManager.OpenUI(UIDef.HigherPVPChallengeRecordDialog)
      end
    end)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Rank.gameObject).onClick = function()
    if not NetCmdHigherPVPData.PVPIsOpen then
      self:CheckKickOut()
      return
    end
    NetCmdHigherPVPData:CleanPVPRankList()
    UIManager.OpenUI(UIDef.HigherPVPRankDialog)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Root.gameObject).onClick = function()
    if not NetCmdHigherPVPData.PVPIsOpen then
      self:CheckKickOut()
      return
    end
    local currMapId = NetCmdHigherPVPData:GetHigherPVPCurrMapId()
    if currMapId == 0 then
      CS.PopupMessageManager.PopupString(TableData.GetHintById(290803))
      return
    end
    local defendDataList = NetCmdHigherPVPData:GetPVPDefendGunListByMapId(currMapId)
    if defendDataList.Count == 0 then
      CS.PopupMessageManager.PopupString(TableData.GetHintById(290715))
      return
    end
    if GlobalData.GetStaminaResourceItemCount(TableDataBase.GlobalSystemData.HighPVPTicket) < 1 then
      CS.PopupMessageManager.PopupString(TableData.GetHintById(290714))
      return
    end
    self.ui.mAnimator_Root.enabled = false
    NetCmdHigherPVPData:OpenLoadingWnd()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Root1.gameObject).onClick = function()
    if not NetCmdHigherPVPData.PVPIsOpen then
      self:CheckKickOut()
      return
    end
    UIManager.OpenUI(UIDef.HigherPVPDefenseTeamDialog)
  end
end

function HigherPVPMainPanel:CurWeeklySettleIsClose()
  local hint = TableData.GetHintById(290712)
  local content = MessageContent.New(hint, MessageContent.MessageType.SingleBtn, function()
    UISystem:JumpToMainPanel()
  end)
  MessageBoxPanel.Show(content)
end

function HigherPVPMainPanel:CleanCloseTimer()
  if self.closeTimer ~= nil then
    self.closeTimer:Stop()
    self.closeTimer = nil
  end
end

function HigherPVPMainPanel:CheckKickOut()
  self:CleanCloseTimer()
  self.pvpLastTime = NetCmdHigherPVPData.PVPLastTime
  local deltaTimeStr = NetCmdPVPData:ConvertPvpTime(CGameTime:GetTimestamp(), NetCmdHigherPVPData.PVPCloseTime)
  if self.pvpLastTime <= 0 then
    self.ui.mText_Time.text = TableData.GetHintById(120151)
  else
    self.ui.mText_Time.text = TableData.GetHintById(120161, self.currSeasonName, deltaTimeStr)
  end
  local repeatCount = self.pvpLastTime + 1
  if self.pvpLastTime <= 0 then
    self:CurWeeklySettleIsClose()
    return
  end
  self.closeTimer = TimerSys:DelayCall(1, function()
    deltaTimeStr = NetCmdPVPData:ConvertPvpTime(CGameTime:GetTimestamp(), NetCmdHigherPVPData.PVPCloseTime)
    if deltaTimeStr == nil or deltaTimeStr == "" then
      self.ui.mText_Time.text = TableData.GetHintById(120151)
    else
      self.ui.mText_Time.text = TableData.GetHintById(120161, self.currSeasonName, deltaTimeStr)
    end
    if not NetCmdHigherPVPData.PVPIsOpen then
      self:CurWeeklySettleIsClose()
      self:CleanCloseTimer()
      self.ui.mText_Time.text = TableData.GetHintById(120151)
      return
    end
    self.pvpLastTime = self.pvpLastTime - 1
  end, nil, repeatCount)
end

function HigherPVPMainPanel:OnShowStart()
  setactive(self.ui.mTrans_LookOverRedPoint1.gameObject, NetCmdHigherPVPData:GetTimeRewardRed())
end

function HigherPVPMainPanel:UpdateDialog()
  if not NetCmdHigherPVPData.PVPIsOpen then
    return
  end
  if self:CheckSettleEnd() then
    return
  end
  if self:CheckSettleOpen() then
    return
  end
end

function HigherPVPMainPanel:CheckSettleEnd()
  if NetCmdHigherPVPData:GetHigherPVPSettle() ~= nil then
    if self.mCSPanel.State == CS.UISystem.UIGroup.BasePanelUI.UIState.Show then
      UIManager.OpenUI(UIDef.HigherPVPSeasonSettlementDialog)
      if not NetCmdHigherPVPData:GetHighPvpNewSeasonOpen() then
        self.isreadytorial = true
      end
    end
    return true
  end
  return false
end

function HigherPVPMainPanel:CheckSettleOpen()
  if NetCmdHigherPVPData:GetHighPvpNewSeasonOpen() then
    local seasonData = NetCmdHigherPVPData:GetHigherPVPSeasonData()
    if seasonData and seasonData.SeasonId > 0 then
      if self.mCSPanel.State == CS.UISystem.UIGroup.BasePanelUI.UIState.Show then
        UIManager.OpenUI(UIDef.HigherPVPNewSeasonOpenDialog)
        if NetCmdHigherPVPData:GetHigherPVPSettle() == nil then
          self.isreadytorial = true
        end
      end
      return true
    end
  end
  return false
end

function HigherPVPMainPanel:IsReadyToStartTutorial()
  return self.isreadytorial
end

function HigherPVPMainPanel:OnShowFinish()
  self:UpdateDialog()
end

function HigherPVPMainPanel:OnTop()
  setactive(self.ui.mTrans_LookOverRedPoint1.gameObject, NetCmdHigherPVPData:GetTimeRewardRed())
  if not NetCmdHigherPVPData.PVPIsOpen then
    return
  end
  NetCmdHigherPVPData:MsgCsHighPvpInfo(function(ret)
    if ret == ErrorCodeSuc then
      local pvpRankData = NetCmdHigherPVPData:GetHighPvpRank()
      if pvpRankData then
        if pvpRankData.Rank == 0 then
          self.ui.mText_Num.text = TableData.GetHintById(130006)
        else
          self.ui.mText_Num.text = pvpRankData.Rank
        end
        self.ui.mText_Num1.text = pvpRankData.Points
      end
    end
  end)
end

function HigherPVPMainPanel:OnBackFrom()
  setactive(self.ui.mTrans_LookOverRedPoint1.gameObject, NetCmdHigherPVPData:GetTimeRewardRed())
end

function HigherPVPMainPanel:OnRecover()
  setactive(self.ui.mTrans_LookOverRedPoint1.gameObject, NetCmdHigherPVPData:GetTimeRewardRed())
end

function HigherPVPMainPanel:OnClose()
  self:CleanCloseTimer()
end

function HigherPVPMainPanel:OnHide()
end

function HigherPVPMainPanel:OnHideFinish()
end

function HigherPVPMainPanel:OnRelease()
end
