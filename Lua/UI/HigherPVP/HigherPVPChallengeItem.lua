require("UI.UIBaseCtrl")
HigherPVPChallengeItem = class("HigherPVPChallengeItem", UIBaseCtrl)
HigherPVPChallengeItem.__index = HigherPVPChallengeItem

function HigherPVPChallengeItem:ctor()
end

function HigherPVPChallengeItem:InitCtrl(parent)
  local itemPrefab = parent:GetComponent(typeof(CS.ScrollListChild))
  local instObj = instantiate(itemPrefab.childItem)
  self.ui = {}
  self:LuaUIBindTable(instObj, self.ui)
  if parent then
    UIUtils.AddListItem(instObj.gameObject, parent.gameObject)
    CS.LuaUIUtils.SetParent(instObj.gameObject, parent.gameObject, true)
  end
  self:SetRoot(instObj.transform)
end

function HigherPVPChallengeItem:InitCtrlWithoutInstantiate(obj)
  self.ui = {}
  self:LuaUIBindTable(obj, self.ui)
  self:SetRoot(obj.transform)
  UIUtils.GetButtonListener(self.ui.mBtn_Root.gameObject).onClick = function()
    self:OnClickSelf()
  end
end

function HigherPVPChallengeItem:SetData(data)
  self.data = data
  self.isNPC = data.Opponent.Uid == 0
  self.ui.mTrans_Success.gameObject:SetActive(data.Result)
  self.ui.mTrans_Fail.gameObject:SetActive(not data.Result)
  if data.Positive then
    if data.Result then
      self.ui.mText_Success.text = TableData.GetHintById(290501)
    else
      self.ui.mText_Fail.text = TableData.GetHintById(290502)
    end
  elseif data.Result then
    self.ui.mText_Success.text = TableData.GetHintById(290716)
  else
    self.ui.mText_Fail.text = TableData.GetHintById(290717)
  end
  self.ui.mText_Time.text = UIPVPGlobal.GetAboutTime(data.BattleTime) .. TableData.GetHintById(108045)
  if data.Opponent.Rank == 0 then
    self.ui.mText_Num.text = data.Opponent.RankRate .. "%"
  else
    self.ui.mText_Num.text = data.Opponent.Rank
  end
  local opponentData = NetCmdHigherPVPData:GetPVPOpponentByBattleId(data.BattleId)
  local historyCapacity = NetCmdHigherPVPData:GetCapacityByBattleId(data.BattleId)
  self.ui.mText_Num1.text = historyCapacity
  if opponentData then
    self.ui.mText_Num2.text = opponentData.highPvpOpponent.Points
    local defendData = opponentData:GetDefendGunPvpData(0)
    local gunId
    if defendData then
      gunId = defendData.Id
    end
    if self.isNPC then
      local pvpDummyData = NetCmdHigherPVPData:GetHigherRobotData(opponentData.highPvpOpponent.DummyId)
      if pvpDummyData then
        self.ui.mText_PlayerName.text = pvpDummyData.robot_name.str
        self.ui.mText_Num1.text = pvpDummyData.robot_score
      end
      self.ui.mText_Num.text = "-"
      if defendData then
        local gunPresetDatas = TableDataBase.listGunPresetDatas:GetDataById(defendData.Id)
        if gunPresetDatas then
          gunId = gunPresetDatas.SourceId
        end
      end
    else
      self.ui.mText_PlayerName.text = opponentData.user.Name
    end
    if gunId ~= nil then
      self.ui.mImg_Avatar.sprite = IconUtils.GetCharacterTypeSpriteWithClothByGunId(IconUtils.cCharacterAvatarType_Avatar, IconUtils.cCharacterAvatarGacha, gunId, defendData.Avatar.CostumeId)
      setactive(self.ui.mImg_Avatar.gameObject, true)
    else
      setactive(self.ui.mImg_Avatar.gameObject, false)
    end
  end
  if data.Result or data.ChangePoint == 0 then
    self.ui.mText_Score.text = string_format(TableData.GetHintById(271095), data.ChangePoint)
  else
    self.ui.mText_Score.text = string_format(TableData.GetHintById(271313), data.ChangePoint)
  end
end

function HigherPVPChallengeItem:OnClickSelf()
  NetCmdHigherPVPData:MsgCsHighPvpHistory(CS.ProtoCsmsg.CS_HighPvpHistory.Types.PvpHistoryInfoType.SingleFull, self.data.BattleId, function(ret)
    if ret == ErrorCodeSuc then
      UIManager.OpenUIByParam(UIDef.HigherPVPEmbattleDetailDialog, {
        historyData = self.data
      })
    end
  end)
end
