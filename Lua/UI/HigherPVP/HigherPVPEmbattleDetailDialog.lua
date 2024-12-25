require("UI.UIBasePanel")
require("UI.Common.UICommonPlayerAvatarItem")
require("UI.Common.ComChrInfoItemV2")
HigherPVPEmbattleDetailDialog = class("HigherPVPEmbattleDetailDialog", UIBasePanel)
HigherPVPEmbattleDetailDialog.__index = HigherPVPEmbattleDetailDialog

function HigherPVPEmbattleDetailDialog:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function HigherPVPEmbattleDetailDialog:OnAwake(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self:InitDefendUI()
  self:OnBtnClick()
end

function HigherPVPEmbattleDetailDialog:InitDefendUI()
  self.defendUIList = {}
  self.attackUIList = {}
  for i = 1, 4 do
    local defendCell = ComChrInfoItemV2.New()
    defendCell:InitCtrl(self.ui.mTrans_Chr)
    table.insert(self.defendUIList, defendCell)
    local attackCell = ComChrInfoItemV2.New()
    attackCell:InitCtrl(self.ui.mTrans_Chr1)
    table.insert(self.attackUIList, attackCell)
  end
end

function HigherPVPEmbattleDetailDialog:OnBtnClick()
  UIUtils.GetButtonListener(self.ui.mBtn_Close.gameObject).onClick = function()
    UIManager.CloseUI(UIDef.HigherPVPEmbattleDetailDialog)
  end
end

function HigherPVPEmbattleDetailDialog:UpdateInfo()
  self.ui.mText_Time.text = UIPVPGlobal.GetAboutTime(self.historyData.BattleTime) .. TableData.GetHintById(108045)
  if self.opponentData.highPvpOpponent.Rank == 0 then
    self.ui.mText_Num.text = TableData.GetHintById(130006)
  else
    self.ui.mText_Num.text = self.opponentData.highPvpOpponent.Rank
  end
  if self.playerAvatar == nil then
    self.playerAvatar = UICommonPlayerAvatarItem.New()
    self.playerAvatar:InitCtrl(self.ui.mTrans_PlayerAvatar)
  end
  if 0 < self.opponentData.highPvpOpponent.Uid then
    self.ui.mText_Name.text = self.opponentData.user.Name
    self.ui.mText_LV.text = string_format(TableData.GetHintById(102250), self.opponentData.user.Level)
    self.playerAvatar:SetData(TableData.GetPlayerAvatarIconById(self.opponentData.user.Portrait, LuaUtils.EnumToInt(self.opponentData.user.Sex)))
    if self.opponentData.user.PortraitFrame and 0 < self.opponentData.user.PortraitFrame then
      local frameData = TableData.listHeadFrameDatas:GetDataById(self.opponentData.user.PortraitFrame, true)
      if frameData then
        self.playerAvatar:SetFrameDataOut(frameData.icon)
      end
    end
    local historyCapacity = NetCmdHigherPVPData:GetCapacityByBattleId(self.historyData.BattleId)
    self.ui.mText_Num2.text = historyCapacity
  else
    self.ui.mText_Num.text = "-"
    local pvpDummyData = NetCmdHigherPVPData:GetHigherRobotData(self.opponentData.highPvpOpponent.DummyId)
    if pvpDummyData then
      self.ui.mText_Name.text = pvpDummyData.robot_name.str
      self.ui.mText_LV.text = string_format(TableData.GetHintById(102250), pvpDummyData.robot_level)
      local playerAvatarData = TableData.listPlayerAvatarDatas:GetDataById(pvpDummyData.robot_pic, true)
      self.ui.mText_Num2.text = pvpDummyData.robot_score
      if playerAvatarData then
        self.playerAvatar:SetData(playerAvatarData.Icon)
      end
    end
  end
  self.playerAvatar.ui.mBtn_Avatar.interactable = false
  setactive(self.playerAvatar.ui.mTrans_Sel, false)
  self.ui.mText_Num1.text = self.opponentData.highPvpOpponent.Points
  if self.historyData.Result or self.historyData.ChangePoint == 0 then
    self.ui.mText_Score.text = "\231\167\175\229\136\134 +" .. self.historyData.ChangePoint
  else
    self.ui.mText_Score.text = "\231\167\175\229\136\134 " .. self.historyData.ChangePoint
  end
  setactive(self.ui.mTrans_Win.gameObject, self.historyData.Result)
  setactive(self.ui.mTrans_Fail.gameObject, not self.historyData.Result)
  local mapData = TableData.listHighPvpMapDatas:GetDataById(self.opponentData.highPvpOpponent.MapId, true)
  if mapData then
    self.ui.mText_Title.text = mapData.map_name.str
  end
end

function HigherPVPEmbattleDetailDialog:SetDefendData()
  for i = 1, #self.defendUIList do
    local defendCell = self.defendUIList[i]
    local attackCell = self.attackUIList[i]
    defendCell:RefreshLineUp(self.opponentData:GetDefendData(i - 1), self.opponentData:GetGunCmdData(i - 1), self.opponentData.highPvpOpponent.Uid == 0)
    attackCell:RefreshLineUp(NetCmdHigherPVPData:GetPVPAttackByBattleId(self.historyData.BattleId, i - 1), nil, self.opponentData.Uid == 0)
  end
end

function HigherPVPEmbattleDetailDialog:OnInit(root, data)
  setactive(self.ui.mBtn_Back.gameObject, false)
  self.historyData = data.historyData
  self.opponentData = NetCmdHigherPVPData:GetPVPOpponentByBattleId(data.historyData.BattleId)
  self:UpdateInfo()
  self:SetDefendData()
end

function HigherPVPEmbattleDetailDialog:OnShowStart()
end

function HigherPVPEmbattleDetailDialog:OnShowFinish()
end

function HigherPVPEmbattleDetailDialog:OnTop()
end

function HigherPVPEmbattleDetailDialog:OnBackFrom()
end

function HigherPVPEmbattleDetailDialog:OnClose()
  if self.playerAvatar then
    self.playerAvatar:OnRelease()
    self.playerAvatar = nil
  end
end

function HigherPVPEmbattleDetailDialog:OnShowFinish()
end

function HigherPVPEmbattleDetailDialog:OnHide()
end

function HigherPVPEmbattleDetailDialog:OnHideFinish()
end

function HigherPVPEmbattleDetailDialog:OnRelease()
end
