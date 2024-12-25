UIActivityTreasureItem = class("UIActivityTreasureItem", UIActivityItemBase)
UIActivityItemBase.__index = UIActivityItemBase
UIActivityTreasureItem.closeTime = nil
UIActivityTreasureItem.id = nil
local gameIconPath = "Assets/_UI/UIRes/Sprites/Activity/Treasure/"
local gameMaskPath = "GeneralUI_Effect/Others/"

function UIActivityTreasureItem:OnShow()
  UIActivityTreasureItem.closeTime = self.mCloseTime
  UIActivityTreasureItem.id = self.mActivityID
  self.ui.mText_Time:StartCountdown(self.mCloseTime)
  self.ui.mText_Desc.text = NetCmdActivityTreasureData:GetActivityDesc(self.mActivityID)
  self.ui.mText_Name.text = NetCmdActivityTreasureData:GetActivityName(self.mActivityID)
  UIUtils.GetButtonListener(self.ui.mBtn_Bp).onClick = function()
    self:ClickBp()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Bingo).onClick = function()
    self:ClickBingo()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Game).onClick = function()
    self:ClickGame()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Detail).onClick = function()
    self:ClickDetail(NetCmdActivityTreasureData:GetActivityHelp(self.mActivityID))
  end
  local now = CGameTime:GetTimestamp()
  if self.mCloseTime - now > 0 then
    self.CloseTimer = TimerSys:UnscaledDelayCall(self.mCloseTime - now, function()
      UIUtils.PopupErrorWithHint(260010)
      UISystem:JumpToMainPanel()
    end)
  else
    UIUtils.PopupErrorWithHint(260010)
    UISystem:JumpToMainPanel()
    return
  end
  self:RequestData()
end

function UIActivityTreasureItem:RegisterEvent()
  function self.OnActivityReset()
    UIUtils.PopupErrorWithHint(260010)
    
    UISystem:JumpToMainPanel()
  end
  
  MessageSys:AddListener(CS.GF2.Message.UIEvent.OnDayChange, self.OnActivityReset)
end

function UIActivityTreasureItem:RequestData()
  NetCmdActivityTreasureData:SetAsCurrent(self.mActivityID)
  NetCmdActivityTreasureData:DirtyRedPoint()
  self:RefreshConfig()
  self:RefreshRedPoint()
end

function UIActivityTreasureItem:ClickBp()
  UIManager.OpenUI(UIDef.UITreasureBpPanel)
end

function UIActivityTreasureItem:ClickBingo()
  UIManager.OpenUI(UIDef.UITreasureFlopPanel)
end

function UIActivityTreasureItem:ClickGame()
  local config = TableDataBase.listTreasureMainDatas:GetDataById(self.mActivityID)
  NetCmdActivityTreasureData:SwitchMiniGames(config.GameId)
end

function UIActivityTreasureItem:ClickDetail(desc)
  SimpleMessageBoxPanel.ShowByParam(TableData.GetHintById(260220), desc)
end

function UIActivityTreasureItem:RefreshConfig()
  local config = TableDataBase.listTreasureMainDatas:GetDataById(self.mActivityID)
  local bpId = config.BpId
  self:RefreshBp(bpId)
  local bingoId = config.BingoId
  self:RefreshBingo(bingoId)
  local gameId = config.GameId
  self:RefreshGame(gameId, config)
  local activityConfig = TableDataBase.listActivityListDatas:GetDataById(self.mActivityID)
  if activityConfig ~= nil then
    setactivewithcheck(self.ui.mBtn_Detail, activityConfig.permanent ~= 1)
    setactivewithcheck(self.ui.mText_Time, activityConfig.permanent ~= 1)
  end
end

function UIActivityTreasureItem:RefreshBingo(bingoId)
  setactivewithcheck(self.ui.mBtn_Bingo, 0 < bingoId)
  setactivewithcheck(self.ui.mTrans_Bingo, 0 < bingoId)
end

function UIActivityTreasureItem:RefreshBp(bpId)
  setactivewithcheck(self.ui.mBtn_Bp, 0 < bpId)
  setactivewithcheck(self.ui.mTrans_Bp, 0 < bpId)
end

function UIActivityTreasureItem:RefreshGame(gameId, config)
  setactivewithcheck(self.ui.mBtn_Game, 0 < gameId)
  if 0 < gameId then
    local gameIcon = ResSys:GetSpriteByFullPath(gameIconPath .. config.GameIcon .. ".png")
    self.ui.mImg_GameIcon.sprite = gameIcon
    self.ui.mImg_GameGlow.sprite = gameIcon
    local maskTexture = ResSys:GetUITexture(gameMaskPath .. config.GameSpec .. ".png")
    self.ui.mImg_GameMask.material:SetTexture("_MainTex", maskTexture)
  end
end

function UIActivityTreasureItem:RefreshRedPoint()
  local bp = NetCmdActivityTreasureData:CheckBp(self.mActivityID)
  setactivewithcheck(self.ui.mTrans_BpRedPoint, 0 < bp)
  local bingo = NetCmdActivityTreasureData:CheckBingo(self.mActivityID)
  setactivewithcheck(self.ui.mTrans_BingoRedPoint, 0 < bingo)
end

function UIActivityTreasureItem:OnTop()
  self:RefreshRedPoint()
end

function UIActivityTreasureItem:OnHide()
  if self.CloseTimer ~= nil then
    self.CloseTimer:Stop()
    self.CloseTimer = nil
  end
end

function UIActivityTreasureItem:UnregisterEvent()
  MessageSys:RemoveListener(CS.GF2.Message.UIEvent.OnDayChange, self.OnActivityReset)
end
