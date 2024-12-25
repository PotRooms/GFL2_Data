require("UI.UIBaseCtrl")
UIPVPSeasonSettlementDialog = class("UIPVPSeasonSettlementDialog", UIBasePanel)
UIPVPSeasonSettlementDialog.__index = UIPVPSeasonSettlementDialog
local self = UIPVPSeasonSettlementDialog

function UIPVPSeasonSettlementDialog:ctor(obj)
  UIPVPSeasonSettlementDialog.super.ctor(self)
  obj.Type = UIBasePanelType.Dialog
end

function UIPVPSeasonSettlementDialog:CleanCloseTimer()
  if self.closeTimer ~= nil then
    self.closeTimer:Stop()
    self.closeTimer = nil
  end
end

function UIPVPSeasonSettlementDialog:OnInit(root)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self:CleanCloseTimer()
  self.closeTimer = TimerSys:DelayCall(4, function()
    UIUtils.GetButtonListener(self.ui.mBtn_Close.gameObject).onClick = function()
      self:OnBtnClose()
    end
  end)
  NetCmdPVPData:ReqNrtPvpWeeklySettleAcquire(function(ret)
    NetCmdPVPData:ClearBattleSettle()
  end)
  local lastPlan = NetCmdPVPData:GetLastSeasonPlan()
  local openTime = CS.CGameTime.ConvertLongToDateTime(lastPlan.OpenTime):ToString("yyyy.MM.dd")
  local closeTime = CS.CGameTime.ConvertLongToDateTime(lastPlan.CloseTime):ToString("yyyy.MM.dd")
  local openTimeAndCloseTime = string_format(TableData.GetHintById(120157), openTime, closeTime)
  self.ui.mText_Date.text = openTimeAndCloseTime
  local seasonData = TableDataBase.listNrtpvpSeasonDatas:GetDataById(lastPlan.Args[0], true)
  if seasonData then
    if seasonData.season_id == 1 then
      self.seasonType = 1
      self.ui.mText_Tittle.text = TableData.GetHintById(120158)
      self.ui.mText_Date1.text = TableData.GetHintById(120159)
    else
      self.seasonType = 2
      self.ui.mText_Tittle.text = string_format(TableData.GetHintById(120156), seasonData.name)
      self.ui.mText_Date1.text = openTimeAndCloseTime
    end
  end
  local settleLevel = NetCmdPVPData.settleLevel
  if settleLevel == 0 then
    settleLevel = 35
  end
  UIPVPGlobal.GetRankImage(settleLevel, self.ui.mImg_Icon, self.ui.mImg_IconBg)
  UIPVPGlobal.GetRankNumImage(settleLevel, self.ui.mImg_StarNum)
  local seasonLevelData = NetCmdPVPData:GetCurrentSeasonLevelId(settleLevel)
  self.itemUIList = {}
  if seasonLevelData then
    self.ui.mText_Rank.text = seasonLevelData.name.str
    local itemList = UIUtils.GetKVSortItemTable(seasonLevelData.season_reward)
    for i = 1, #itemList do
      local item = UICommonItem.New()
      item:InitCtrl(self.ui.mTrans_Content)
      item:SetItemData(itemList[i].id, itemList[i].num, nil, nil, nil, nil, nil, function()
        TipsPanelHelper.OpenUITipsPanel(TableData.GetItemData(itemList[i].id))
      end)
      table.insert(self.itemUIList, item)
    end
  end
  self.ui.mText_Num.text = NetCmdPVPData.LastPvpInfo.points
  self.ui.mText_Num2.text = NetCmdPVPData.LastPvpInfo.seasonAtkWin .. "/" .. NetCmdPVPData.LastPvpInfo.seasonAtkTotal
end

function UIPVPSeasonSettlementDialog:OnBtnClose()
  self:CleanCloseTimer()
  UIManager.CloseUI(UIDef.UIPVPSeasonSettlementDialog)
  if UIPVPGlobal.SeasonCallback ~= nil then
    UIPVPGlobal.SeasonCallback()
    UIPVPGlobal.SeasonCallback = nil
  end
  NetCmdPVPData:ReqGetUpgradeReward(NetCmdPVPData.PvpInfo.level, function(ret)
  end)
  if self.itemUIList then
    for i, v in pairs(self.itemUIList) do
      gfdestroy(v.mUIRoot.gameObject)
    end
    self.itemUIList = {}
  end
end
